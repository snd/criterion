###################################################################################
# HELPERS

# return a new object which has `proto` as its prototype and
# all properties in `properties` as its own properties.

beget = (proto, properties) ->
  object = Object.create proto

  if properties?
    for key, value of properties
      do (key, value) -> object[key] = value

  return object

# if `thing` is an array return `thing`
# otherwise return an array of all key value pairs in `thing` as objects

explodeObject = (arrayOrObject) ->
  if Array.isArray arrayOrObject
    return arrayOrObject

  array = []
  for key, value of arrayOrObject
    do (key, value) ->
      object = {}
      object[key] = value
      array.push object

  return array

identity = (x) ->
  x

isEmptyArray = (x) ->
  Array.isArray(x) and x.length is 0

# calls iterator for the values in array in sequence.
# calls iterator with the index as second argument.
# returns the first value returned by iterator for which predicate returns true.
# otherwise returns sentinel.

some = (
  array
  iterator = identity
  predicate = (x) -> x?
  sentinel = undefined
) ->
  i = 0
  length = array.length
  while i < length
    result = iterator array[i], i
    if predicate result, i
      return result
    i++
  return sentinel

flatten = (array) ->
  [].concat array...

###################################################################################
# PROTOTYPES AND FACTORIES

# prototype objects for the objects that describe parts of sql-where-conditions
# as well as factory functions that make such objects by prototypically
# inheriting from the prototypes

prototypes = {}
factories = {}
modifierFactories = {}

# the base prototype for all other prototypes
# as all objects should have the logical operators not, and and or

prototypes.base =
  not: -> factories.not @
  and: (other) -> factories.and [@, other]
  or: (other) -> factories.or [@, other]

###################################################################################
# sql fragment

# criterion treats values in comparisons which are objects
# which have a sql property that is a function in a special way:
# by pasting the raw sql unmodified at the correct position

isSqlFragment = (value) ->
  value? and 'function' is typeof value.sql

prototypes.sqlFragment = beget prototypes.base,
  sql: ->
    unless @_params
      return @_sql

    i = -1
    params = @_params

    @_sql.replace /\?/g, ->
      i++
      # if the param is an array explode into a comma separated list of question marks
      if Array.isArray params[i]
        (params[i].map -> "?").join ", "
      else
        "?"

  params: ->
    if @_params
      flatten @_params

# params are optional
factories.sqlFragment = (sql, params) ->
  beget prototypes.sqlFragment, {_sql: sql, _params: params}

###################################################################################
# comparisons: eq, ne, lt, lte, gt, gte

prototypes.comparison = beget prototypes.base,
  sql: (escape = identity) ->
    if isSqlFragment @_value
      # put fragment in parentheses
      "#{escape @_key} #{@_operator} (#{@_value.sql()})"
    else
      "#{escape @_key} #{@_operator} ?"
  params: ->
    if isSqlFragment @_value
      @_value.params?() or []
    else
      [@_value]

comparisonNameToOperatorMapping =
  $eq: '='
  $ne: '!='
  $lt: '<'
  $lte: '<='
  $gt: '>'
  $gte: '>='

for name, operator of comparisonNameToOperatorMapping
  do (name, operator) ->
    modifierFactories[name] = (key, value) ->
      beget prototypes.comparison, {_key: key, _value: value, _operator: operator}

###################################################################################
# null

prototypes.null = beget prototypes.base,
  sql: (escape = identity) ->
    "#{escape @_key} IS #{if @_isNull then '' else 'NOT '}NULL"
  params: ->
    []

modifierFactories.$null = (k, isNull) ->
  beget prototypes.null, {_key: k, _isNull: isNull}

###################################################################################
# negation

prototypes.not = beget prototypes.base,
  innerCriterion: -> @_criterion._criterion
  sql: (escape = identity) ->
    # remove double negation
    if isNegation @_criterion
      @innerCriterion().sql(escape)
    else "NOT (#{@_criterion.sql(escape)})"
  params: ->
    @_criterion.params()

isNegation = (c) ->
  prototypes.not.isPrototypeOf c

factories.not = (criterion) ->
  beget prototypes.not, {_criterion: criterion}

###################################################################################
# exists

prototypes.exists = beget prototypes.base,
  sql: (escape = identity) ->
    "EXISTS (#{@_value.sql escape})"
  params: ->
    @_value.params?() or []

factories.exists = (value) ->
  unless isSqlFragment value
    throw new Error '$exists key requires sql-fragment value'
  beget prototypes.exists, {_value: value}

###################################################################################
# subquery expressions: in, nin, any, neAny, ...

prototypes.subquery = beget prototypes.base,
  sql: (escape = identity) ->
    if isSqlFragment @_value
      "#{escape @_key} #{@_operator} (#{@_value.sql escape})"
    else
      questionMarks = []
      @_value.forEach -> questionMarks.push '?'
      "#{escape @_key} #{@_operator} (#{questionMarks.join ', '})"
  params: ->
    if isSqlFragment @_value
      @_value.params?() or []
    else
      @_value

subqueryNameToOperatorMapping =
  $in: 'IN'
  $nin: 'NOT IN'
  $any: '= ANY'
  $neAny: '!= ANY'
  $ltAny: '< ANY'
  $lteAny: '<= ANY'
  $gtAny: '> ANY'
  $gteAny: '>= ANY'
  $all: '= ALL'
  $neAll: '!= ALL'
  $ltAll: '< ALL'
  $lteAll: '<= ALL'
  $gtAll: '> ALL'
  $gteAll: '>= ALL'

for name, operator of subqueryNameToOperatorMapping
  do (name, operator) ->
    modifierFactories[name] = (key, value) ->
      if Array.isArray value
        if name in ['$in', '$nin']
          if value.length is 0
            throw new Error "#{name} key with empty array value"
        else
          # only $in and $nin support arrays
          throw new Error "#{name} key doesn't support array value. only $in and $nin do!"
      else
        unless isSqlFragment value
          # TODO improve this error message
          throw new Error "#{name} key requires sql-fragment value (or array in case of $in and $nin)"

      beget prototypes.subquery, {_key: key, _value: value, _operator: operator}

###################################################################################
# combination: and, or

prototypes.combination = beget prototypes.base,
  sql: (escape = identity) ->
    parts = @_criteria.map (c) -> "(#{c.sql(escape)})"
    return parts.join " #{@_operator} "

  params: ->
    params = []
    @_criteria.forEach (c) ->
      if c.params?
        params = params.concat c.params()
    return params

factories.and = (criteria) ->
  beget prototypes.combination, {_criteria: criteria, _operator: 'AND'}

factories.or = (criteria) ->
  beget prototypes.combination, {_criteria: criteria, _operator: 'OR'}

###################################################################################
# MAIN FACTORY

# function that recursively construct the object graph
# of the criterion described by the arguments

module.exports = mainFactory = (first, rest...) ->
  if isSqlFragment first
    return first

  type = typeof first

  # invalid arguments?
  unless 'string' is type or 'object' is type
    throw new Error "string or object expected as first argument but #{type} given"

  # sql fragment with optional bindings?
  if type is 'string'

    # make sure that no param is an empty array

    emptyArrayParam = some(
      rest
      (x, i) -> {x: x, i: i}
      ({x, i}) -> isEmptyArray x
    )

    if emptyArrayParam?
      throw new Error "params[#{emptyArrayParam.i}] is an empty array"

    # all good
    return factories.sqlFragment first, rest

  # array of query objects?
  if Array.isArray first
    if first.length is 0
      throw new Error 'empty query object'
    # let's AND them together
    return factories.and first.map mainFactory

  keyCount = Object.keys(first).length

  if 0 is keyCount
    throw new Error 'empty query object'

  # if there is more than one key in the query object
  # cut it up into objects with one key and AND them together
  if keyCount > 1
    return factories.and explodeObject(first).map mainFactory

  # FROM HERE ON WE HAVE AN OBJECT WITH EXACTLY ONE KEY-VALUE-MAPPING

  key = Object.keys(first)[0]
  value = first[key]

  unless value?
    throw new Error "value undefined or null for key #{key}"

  if key is '$and'
    return factories.and explodeObject(value).map mainFactory

  if key is '$or'
    return factories.or explodeObject(value).map mainFactory

  if key is '$not'
    return factories.not mainFactory value

  if key is '$exists'
    return factories.exists value

  unless 'object' is typeof value
    return modifierFactories.$eq key, value

  # FROM HERE ON VALUE IS AN OBJECT

  # {x: [1, 2, 3]} is a shorthand for {x: {$in: [1, 2, 3]}}
  if Array.isArray value
    return modifierFactories.$in key, value

  keys = Object.keys value

  modifier = keys[0]

  hasModifier = keys.length is 1 and 0 is modifier.indexOf '$'

  unless hasModifier
    # handle other inner objects like dates
    return modifierFactories.$eq key, value

  # FROM HERE ON THE VALUE IS AN OBJECT WITH AN INNER MODIFIER KEY

  innerValue = value[modifier]
  unless innerValue?
    throw new Error "value undefined or null for key #{key} and modifier key #{modifier}"

  modifierFactory = modifierFactories[modifier]

  if modifierFactory?
    return modifierFactory key, innerValue

  throw new Error "unknown modifier key #{modifier}"
