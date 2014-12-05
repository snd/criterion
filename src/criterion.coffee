# this is later exported as module.exports.internals
# to make the internals available to mesa, mohair
# and any other module that needs them
internals = {}

###################################################################################
# HELPERS

helper = {}

# return a new object which has `proto` as its prototype and
# all properties in `properties` as its own properties.

helper.beget = beget = (proto, properties) ->
  object = Object.create proto

  if properties?
    for key, value of properties
      do (key, value) -> object[key] = value

  return object

# if `thing` is an array return `thing`
# otherwise return an array of all key value pairs in `thing` as objects
# example: explodeObject({a: 1, b: 2}) -> [{a: 1}, {b: 2}]

helper.explodeObject = explodeObject = (arrayOrObject) ->
  if Array.isArray arrayOrObject
    return arrayOrObject

  array = []
  for key, value of arrayOrObject
    do (key, value) ->
      object = {}
      object[key] = value
      array.push object

  return array

helper.identity = identity = (x) ->
  x

helper.isEmptyArray = isEmptyArray = (x) ->
  Array.isArray(x) and x.length is 0

# calls iterator for the values in array in sequence (with the index as the second argument).
# returns the first value returned by iterator for which predicate returns true.
# otherwise returns sentinel.

helper.some = some = (
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

# flatten array one level

helper.flatten = flatten = (array) ->
  [].concat array...

# sql-fragments are treated differently in many situations

helper.implementsSqlFragmentInterface = implementsSqlFragmentInterface = (value) ->
  value? and 'function' is typeof value.sql and 'function' is typeof value.params

###################################################################################
# PROTOTYPES AND FACTORIES

# prototype objects for the objects that describe parts of sql-where-conditions

internals.prototypes = prototypes = {}

# factory functions that make such objects by prototypically inheriting from the prototypes

internals.factories = factories = {}
internals.modifierFactories = modifierFactories = {}

# the base prototype for all other prototypes:
# all objects should have the logical operators not, and and or

prototypes.base =
  not: -> factories.not @
  and: (other) -> factories.and [@, other]
  or: (other) -> factories.or [@, other]

###################################################################################
# raw sql

prototypes.rawSql = beget prototypes.base,
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
    flatten @_params

# params are entirely optional
# casts to sql-fragment
factories.rawSql = helper.rawSql = (sql, params = []) ->
  if implementsSqlFragmentInterface sql
    return sql
  beget prototypes.rawSql, {_sql: sql, _params: params}

###################################################################################
# comparisons: eq, ne, lt, lte, gt, gte

prototypes.comparison = beget prototypes.base,
  sql: (escape = identity) ->
    if implementsSqlFragmentInterface @_value
      # put fragment in parentheses
      "#{escape @_key} #{@_operator} (#{@_value.sql(escape)})"
    else
      "#{escape @_key} #{@_operator} ?"
  params: ->
    if implementsSqlFragmentInterface @_value
      @_value.params()
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
    @_value.params()

factories.exists = (value) ->
  unless implementsSqlFragmentInterface value
    throw new TypeError '$exists key requires value that implements sql-fragment interface'
  beget prototypes.exists, {_value: value}

###################################################################################
# subquery expressions: in, nin, any, neAny, ...

prototypes.subquery = beget prototypes.base,
  sql: (escape = identity) ->
    if implementsSqlFragmentInterface @_value
      "#{escape @_key} #{@_operator} (#{@_value.sql escape})"
    else
      questionMarks = []
      @_value.forEach -> questionMarks.push '?'
      "#{escape @_key} #{@_operator} (#{questionMarks.join ', '})"
  params: ->
    if implementsSqlFragmentInterface @_value
      @_value.params()
    else
      # only for $in and $nin: in that case @_value is already an array
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
          throw new TypeError "#{name} key doesn't support array value. only $in and $nin do!"
      # not array
      else
        unless implementsSqlFragmentInterface value
          if name in ['$in', '$nin']
            throw new TypeError "#{name} key requires value that is an array or implements sql-fragment interface"
          else
            throw new TypeError "#{name} key requires value that implements sql-fragment interface"

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
      params = params.concat c.params()
    return params

factories.and = (criteria) ->
  beget prototypes.combination, {_criteria: criteria, _operator: 'AND'}

factories.or = (criteria) ->
  beget prototypes.combination, {_criteria: criteria, _operator: 'OR'}

###################################################################################
# MAIN FACTORY

# function that recursively constructs the object graph
# of the criterion described by the arguments.

module.exports = criterionFactory = (firstArg, restArgs...) ->
  if implementsSqlFragmentInterface firstArg
    return firstArg

  typeOfFirstArg = typeof firstArg

  # invalid arguments?
  unless 'string' is typeOfFirstArg or 'object' is typeOfFirstArg
    throw new TypeError "string or object expected as first argument but #{typeOfFirstArg} given"

  # raw sql string with optional params?
  if typeOfFirstArg is 'string'

    # make sure that no param is an empty array

    emptyArrayParam = some(
      restArgs
      (x, i) -> {x: x, i: i}
      ({x, i}) -> isEmptyArray x
    )

    if emptyArrayParam?
      throw new Error "params[#{emptyArrayParam.i}] is an empty array"

    # valid raw sql !
    return factories.rawSql firstArg, restArgs

  # array of condition objects?
  if Array.isArray firstArg
    if firstArg.length is 0
      throw new Error 'condition-object is an empty array'
    # let's AND them together
    return factories.and firstArg.map criterionFactory

  # FROM HERE ON `firstArg` IS A CONDITION OBJECT

  keyCount = Object.keys(firstArg).length

  if 0 is keyCount
    throw new Error 'empty condition-object'

  # if there is more than one key in the condition-object
  # cut it up into objects with one key and AND them together
  if keyCount > 1
    return factories.and explodeObject(firstArg).map criterionFactory

  key = Object.keys(firstArg)[0]
  value = firstArg[key]

  # FROM HERE ON `firstArg` IS A CONDITION-OBJECT WITH EXACTLY ONE KEY-VALUE-MAPPING:
  # `key` MAPS TO `value`

  unless value?
    throw new TypeError "value undefined or null for key #{key}"

  if key is '$and'
    return factories.and explodeObject(value).map criterionFactory

  if key is '$or'
    return factories.or explodeObject(value).map criterionFactory

  if key is '$not'
    return factories.not criterionFactory value

  if key is '$exists'
    return factories.exists value

  unless 'object' is typeof value
    return modifierFactories.$eq key, value

  # {x: [1, 2, 3]} is a shorthand for {x: {$in: [1, 2, 3]}}
  if Array.isArray value
    return modifierFactories.$in key, value

  # FROM HERE ON `value` IS AN OBJECT AND NOT A NUMBER, STRING, ARRAY, ...

  keys = Object.keys value

  hasModifier = keys.length is 1 and 0 is keys[0].indexOf '$'

  unless hasModifier
    # handle other objects which are values but have no modifiers
    # (dates for example) like primitives (strings, numbers)
    return modifierFactories.$eq key, value

  modifier = keys[0]
  innerValue = value[modifier]

  # FROM HERE ON `value` IS AN OBJECT WITH A `modifier` KEY AND an `innerValue`

  unless innerValue?
    throw new TypeError "value undefined or null for key #{key} and modifier key #{modifier}"

  modifierFactory = modifierFactories[modifier]

  if modifierFactory?
    return modifierFactory key, innerValue

  throw new Error "unknown modifier key #{modifier}"

# make the internals available to mesa, mohair
# and any other module that needs them
module.exports.internals = internals
module.exports.helper = helper
