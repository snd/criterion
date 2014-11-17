###################################################################################
# helpers

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

# criterion treats values in comparisons which are objects
# which have a sql property that is a function in a special way:
# by replacing the parameter binding with the raw sql

isSpecialValue = (value) ->
  value? and 'function' is typeof value.sql

identity = (x) ->
  x

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

###################################################################################
# prototypes and factories

# prototype objects for the objects that describe parts of sql-where-conditions
# as well as factory functions that make such objects by prototypically
# inheriting from the prototypes

prototypes = {}
factories = {}

# the base prototype for all other prototypes
# as all objects should have the logical operators not, and and or

prototypes.base =
  not: -> factories.not @
  and: (other) -> factories.and [@, other]
  or: (other) -> factories.or [@, other]

# raw sql with optional params

prototypes.raw = beget prototypes.base,
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
      [].concat @_params...

factories.raw = (sql, params) ->
  beget prototypes.raw, {_sql: sql, _params: params}

# comparisons

prototypes.comparison = beget prototypes.base,
  sql: (escape = identity) ->
    if isSpecialValue @_value
      "#{escape @_key} #{@_operator} #{@_value.sql()}"
    else
      "#{escape @_key} #{@_operator} ?"
  params: ->
    if isSpecialValue @_value
      if 'function' is typeof @_value.params
        @_value.params()
      else
        []
    else
      [@_value]

getComparisonFactoryForOperator = (operator) ->
  (key, value) ->
    beget prototypes.comparison, {_key: key, _value: value, _operator: operator}

factories.equal = getComparisonFactoryForOperator '='
factories.notEqual = getComparisonFactoryForOperator '!='
factories.lowerThan = getComparisonFactoryForOperator '<'
factories.lowerThanEqual = getComparisonFactoryForOperator '<='
factories.greaterThan = getComparisonFactoryForOperator '>'
factories.greaterThanEqual = getComparisonFactoryForOperator '>='

# null

prototypes.null = beget prototypes.base,
  sql: (escape = identity) ->
    "#{escape @_key} IS #{if @_isNull then '' else 'NOT '}NULL"
  params: ->
    []

factories.null = (k, isNull) ->
  beget prototypes.null, {_key: k, _isNull: isNull}

# negation

prototypes.not = beget prototypes.base,
  innerCriterion: -> @_criterion._criterion
  sql: (escape = identity) ->
    # remove double negation
    if isNotCriterion @_criterion
      @innerCriterion().sql(escape)
    else "NOT (#{@_criterion.sql(escape)})"
  params: ->
    @_criterion.params()

isNotCriterion = (c) ->
  prototypes.not.isPrototypeOf c

factories.not = (criterion) ->
  beget prototypes.not, {_criterion: criterion}

# in

prototypes.in = beget prototypes.base,
  sql: (escape = identity) ->
    questionMarks = []
    @_values.forEach -> questionMarks.push '?'
    "#{escape @_key} #{@_operator} (#{questionMarks.join ', '})"
  params: -> @_values

factories.in = (key, values) ->
  beget prototypes.in, {_key: key, _values: values, _operator: 'IN'}

factories.notIn = (key, values) ->
  beget prototypes.in, {_key: key, _values: values, _operator: 'NOT IN'}

# combination

prototypes.combination = beget prototypes.base,
  sql: (escape = identity) ->
    parts = @_criteria.map (c) -> "(#{c.sql(escape)})"
    return parts.join " #{@_operator} "

  params: ->
    params = []
    @_criteria.forEach (c) -> params = params.concat c.params()
    params

factories.and = (criteria) ->
  beget prototypes.combination, {_criteria: criteria, _operator: 'AND'}

factories.or = (criteria) ->
  beget prototypes.combination, {_criteria: criteria, _operator: 'OR'}

###################################################################################
# main factory

# function that recursively construct the object graph
# of the criterion described by the arguments

module.exports = factory = (first, rest...) ->
  type = typeof first

  # invalid arguments?
  unless 'string' is type or 'object' is type
    throw new Error """
      string or object expected as first argument
      but #{type} given
    """

  # raw sql with optional bindings?
  if type is 'string'

    # make sure that no param is an empty array

    isEmptyArray = (x) ->
      Array.isArray(x) and x.length is 0

    emptyArrayParam = some(
      rest
      (x, i) -> {x: x, i: i}
      ({x, i}) -> isEmptyArray x
    )

    if emptyArrayParam?
      throw new Error "params[#{emptyArrayParam.i}] is an empty array"

    # all good
    return factories.raw first, rest

  # array of query objects?
  if Array.isArray first
    if first.length is 0
      throw new Error 'empty criterion'
    # let's AND them together
    return factories.and first.map factory

  keyCount = Object.keys(first).length

  if 0 is keyCount
    throw new Error 'empty criterion'

  # if there is more than one key in the query object
  # cut it up into objects with one key and AND them together
  if keyCount > 1
      return factories.and explodeObject(first).map factory

  # from here on we have an object with exactly one key-value-mapping

  key = Object.keys(first)[0]
  value = first[key]

  unless value?
    throw new Error "value undefined or null for key #{key}"

  if key is '$or'
    return factories.or explodeObject(value).map factory

  if key is '$not'
    return factories.not factory value

  unless 'object' is typeof value
    return factories.equal key, value

  # from here on value is an object

  # array query?
  if Array.isArray value
    if value.length is 0
      throw Error 'in with empty array'
    return factories.in key, value

  keys = Object.keys value

  modifier = keys[0]

  hasModifier = keys.length is 1 and 0 is modifier.indexOf '$'

  unless hasModifier
    # handle other inner objects like dates
    return factories.equal key, value

  # form here on the value is an object with a modifier key

  innerValue = value[modifier]
  unless innerValue?
    throw new Error "value undefined or null for key #{key} and modifier #{modifier}"

  switch modifier
    when '$nin'
      if innerValue.length is 0
        throw Error '$nin with empty array'
      factories.notIn key, innerValue
    when '$lt' then factories.lowerThan key, innerValue
    when '$lte' then factories.lowerThanEqual key, innerValue
    when '$gt' then factories.greaterThan key, innerValue
    when '$gte' then factories.greaterThanEqual key, innerValue
    when '$ne' then factories.notEqual key, innerValue
    when '$null' then factories.null key, innerValue
    else throw new Error "unknown modifier: #{modifier}"
