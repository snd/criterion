_ = require 'lodash'

###################################################################################
# HELPERS

helper = {}

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

helper.isEmptyArray = isEmptyArray = (x) ->
  Array.isArray(x) and x.length is 0

# calls iterator for the values in array in sequence (with the index as the second argument).
# returns the first value returned by iterator for which predicate returns true.
# otherwise returns sentinel.

helper.some = some = (
  array
  iterator = _.identity
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

# sql-fragments are treated differently in many situations
helper.implementsSqlFragmentInterface = implementsSqlFragmentInterface = (value) ->
  value? and 'function' is typeof value.sql and 'function' is typeof value.params

# normalize sql for fragments and values
helper.normalizeSql = normalizeSql = (fragmentOrValue, escape, ignoreWrap = false) ->
  if implementsSqlFragmentInterface fragmentOrValue
    sql = fragmentOrValue.sql(escape)
    if ignoreWrap or fragmentOrValue.dontWrap then sql else '(' + sql + ')'
  else
    # if thing is not an sql fragment treat it as a value
    "?"

# normalize params for fragments and values
helper.normalizeParams = normalizeParams = (fragmentOrValue) ->
  if implementsSqlFragmentInterface fragmentOrValue
    fragmentOrValue.params()
  # if thing is not an sql fragment treat it as a value
  else
    [fragmentOrValue]

###################################################################################
# PROTOTYPES AND FACTORIES

# prototype objects for the objects that describe parts of sql-where-conditions

prototypes = {}

dsl = {}

modifiers = {}

# the base prototype for all other prototypes:
# all objects should have the logical operators not, and and or

prototypes.base =
  not: -> dsl.not @
  and: (args...) -> dsl.and @, criterion args...
  or: (args...) -> dsl.or @, criterion args...

###################################################################################
# raw sql

prototypes.rawSql = _.create prototypes.base,
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
    _.flatten @_params
  dontWrap: true

rawSql = (sql, params = []) ->
  _.create prototypes.rawSql, {_sql: sql, _params: params}

###################################################################################
# escape

prototypes.escape = _.create prototypes.base,
  sql: (escape) ->
    return escape @_sql
  params: ->
    []
  dontWrap: true

dsl.escape = (sql) ->
  _.create prototypes.escape, {_sql: sql}

###################################################################################
# wrap

prototypes.wrap = _.create prototypes.base,
  sql: (escape) ->
    return escape @_sql
  params: ->
    []
  dontWrap: false

dsl.wrap = (sql) ->
  _.create prototypes.wrap, {_sql: sql}

###################################################################################
# comparisons: eq, ne, lt, lte, gt, gte

prototypes.comparison = _.create prototypes.base,
  sql: (escape = _.identity) ->
    "#{normalizeSql @_left, escape} #{@_operator} #{normalizeSql @_right, escape}"
  params: ->
    normalizeParams(@_left).concat normalizeParams(@_right)

# for when you need arbitrary comparison operators
dsl.compare = (operator, left, right) ->
  _.create prototypes.comparison, {_left: left, _right: right, _operator: operator}

# make dsl functions and modifier functions for the most common comparison operators
comparisonTable = [
  {name: 'eq', modifier: '$eq', operator: '='}
  {name: 'ne', modifier: '$ne', operator: '!='}
  {name: 'lt', modifier: '$lt', operator: '<'}
  {name: 'lte', modifier: '$lte', operator: '<='}
  {name: 'gt', modifier: '$gt', operator: '>'}
  {name: 'gte', modifier: '$gte', operator: '>='}
].forEach ({name, modifier, operator}) ->
  dsl[name] = modifiers[modifier] = (left, right) ->
    dsl.compare operator, left, right

###################################################################################
# null

prototypes.null = _.create prototypes.base,
  sql: (escape = _.identity) ->
    "#{normalizeSql(@_operand, escape)} IS #{if @_isNull then '' else 'NOT '}NULL"
  params: ->
    normalizeParams(@_operand)

dsl.null = modifiers.$null = (operand, isNull = true) ->
  unless operand?
    throw new Error '`null` needs an operand'
  _.create prototypes.null, {_operand: operand, _isNull: isNull}

###################################################################################
# negation

prototypes.not = _.create prototypes.base,
  sql: (escape = _.identity) ->
    # remove double negation
    if isNegation @_inner
      ignoreWrap = true
      normalizeSql(@_inner._inner, escape, ignoreWrap)
    else
      "NOT #{normalizeSql(@_inner, escape)}"
  params: ->
    @_inner.params()

isNegation = (x) ->
  prototypes.not.isPrototypeOf x

dsl.not = (inner) ->
  unless implementsSqlFragmentInterface inner
    throw new Error '`not`: operand must implement sql-fragment interface'
  _.create prototypes.not, {_inner: inner}

###################################################################################
# exists

prototypes.exists = _.create prototypes.base,
  sql: (escape = _.identity) ->
    "EXISTS #{normalizeSql(@_operand, escape)}"
  params: ->
    @_operand.params()

dsl.exists = (operand) ->
  unless implementsSqlFragmentInterface operand
    throw new Error '`exists` operand must implement sql-fragment interface'
  _.create prototypes.exists, {_operand: operand}

###################################################################################
# subquery expressions: in, nin, any, neAny, ...

prototypes.subquery = _.create prototypes.base,
  sql: (escape = _.identity) ->
    sql = ""
    sql += normalizeSql @_left, escape
    sql += " #{@_operator} "
    if implementsSqlFragmentInterface @_right
      sql += "#{normalizeSql(@_right, escape)}"
    else
      questionMarks = []
      @_right.forEach -> questionMarks.push '?'
      sql += "(#{questionMarks.join ', '})"
    return sql
  params: ->
    params = normalizeParams @_left
    if implementsSqlFragmentInterface @_right
      params = params.concat @_right.params()
    else
      # only for $in and $nin: in that case @_value is already an array
      params = params.concat @_right
    return params

dsl.subquery = (operator, left, right) ->
  _.create prototypes.subquery, {_left: left, _right: right, _operator: operator}

# make dsl functions and modifier functions for common subquery operators
[
  {name: 'in', modifier: '$in', operator: 'IN'}
  {name: 'nin', modifier: '$nin', operator: 'NOT IN'}

  {name: 'any', modifier: '$any', operator: '= ANY'}
  {name: 'neAny', modifier: '$neAny', operator: '!= ANY'}
  {name: 'ltAny', modifier: '$ltAny', operator: '< ANY'}
  {name: 'lteAny', modifier: '$lteAny', operator: '<= ANY'}
  {name: 'gtAny', modifier: '$gtAny', operator: '> ANY'}
  {name: 'gteAny', modifier: '$gteAny', operator: '>= ANY'}

  {name: 'all', modifier: '$all', operator: '= ALL'}
  {name: 'neAll', modifier: '$neAll', operator: '!= ALL'}
  {name: 'ltAll', modifier: '$ltAll', operator: '< ALL'}
  {name: 'lteAll', modifier: '$lteAll', operator: '<= ALL'}
  {name: 'gtAll', modifier: '$gtAll', operator: '> ALL'}
  {name: 'gteAll', modifier: '$gteAll', operator: '>= ALL'}
].forEach ({name, modifier, operator}) ->
  dsl[name] = modifiers[modifier] = (left, right) ->
    unless left?
      throw new Error "`#{name}` needs left operand"
    unless right?
      throw new Error "`#{name}` needs right operand"
    if Array.isArray right
      if name in ['in', 'nin']
        if right.length is 0
          throw new Error "`#{name}` with empty array as right operand"
      else
        # only $in and $nin support arrays
        throw new TypeError "`#{name}` doesn't support array as right operand. only `in` and `nin` do!"
    # not array
    else
      unless implementsSqlFragmentInterface right
        if name in ['in', 'nin']
          throw new TypeError "`#{name}` requires right operand that is an array or implements sql-fragment interface"
        else
          throw new TypeError "`#{name}` requires right operand that implements sql-fragment interface"

    return dsl.subquery operator, left, right

###################################################################################
# and

isAnd = (x) ->
  prototypes.and.isPrototypeOf x

prototypes.and = _.create prototypes.base,
  sql: (escape = _.identity) ->
    parts = @_operands.map (x) ->
      # we don't have to wrap ANDs inside an AND
      ignoreWrap = isAnd x
      normalizeSql(x, escape, ignoreWrap)
    return parts.join " AND "
  params: ->
    params = []
    @_operands.forEach (c) ->
      params = params.concat c.params()
    return params

dsl.and = (args...) ->
  operands = _.flatten args
  if operands.length is 0
    throw new Error "`and` needs at least one operand"
  operands.forEach (x) ->
    unless implementsSqlFragmentInterface x
      throw new Error "`and`: all operands must implement sql-fragment interface"
  _.create prototypes.and, {_operands: operands}

###################################################################################
# or

isOr = (x) ->
  prototypes.or.isPrototypeOf x

prototypes.or = _.create prototypes.base,
  sql: (escape = _.identity) ->
    parts = @_operands.map (x) ->
      # we don't have to wrap ORs inside an OR
      ignoreWrap = isOr x
      normalizeSql(x, escape, ignoreWrap)
    return parts.join " OR "
  params: ->
    params = []
    @_operands.forEach (c) ->
      params = params.concat c.params()
    return params

dsl.or = (args...) ->
  operands = _.flatten args
  if operands.length is 0
    throw new Error "`or` needs at least one operand"
  operands.forEach (x) ->
    unless implementsSqlFragmentInterface x
      throw new Error "`or`: all operands must implement sql-fragment interface"
  _.create prototypes.or, {_operands: operands}

###################################################################################
# MAIN FACTORY

# always returns an sql-fragment.
# can be used to normalize sql strings and fragments.

# when called with a single sql fragment returns that fragment unchanged.
#
# when called with a list of 
# when called with a condition-object parses that object into a fragment and returns it.
# function that recursively constructs the object graph
# of the criterion described by the arguments.
# when called with a string

criterion = (firstArg, restArgs...) ->
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
    return rawSql firstArg, restArgs

  # if there is more than one argument and the first isnt a string
  # map criterion over all arguments and AND them together

  if restArgs.length isnt 0
    return dsl.and [firstArg].concat(restArgs).map (x) -> criterion x

  # FROM HERE ON THERE IS ONLY A SINGLE ARGUMENT

  if implementsSqlFragmentInterface firstArg
    return firstArg

  # array of condition objects?
  if Array.isArray firstArg
    if firstArg.length is 0
      throw new Error 'condition-object is an empty array'
    # let's AND them together
    return dsl.and firstArg.map (x) -> criterion x

  # FROM HERE ON `firstArg` IS A CONDITION OBJECT

  keyCount = Object.keys(firstArg).length

  if 0 is keyCount
    throw new Error 'empty condition-object'

  # if there is more than one key in the condition-object
  # cut it up into objects with one key and AND them together
  if keyCount > 1
    return dsl.and explodeObject(firstArg).map (x) -> criterion x

  # column name
  key = Object.keys(firstArg)[0]
  keyFragment = dsl.escape key
  value = firstArg[key]

  # FROM HERE ON `firstArg` IS A CONDITION-OBJECT WITH EXACTLY ONE KEY-VALUE-MAPPING:
  # `key` MAPS TO `value`

  unless value?
    throw new TypeError "value undefined or null for key #{key}"

  if key is '$and'
    return dsl.and explodeObject(value).map (x) -> criterion x

  if key is '$or'
    return dsl.or explodeObject(value).map (x) -> criterion x

  if key is '$not'
    return dsl.not criterion value

  if key is '$exists'
    return dsl.exists value

  unless 'object' is typeof value
    return dsl.eq keyFragment, value

  # {x: [1, 2, 3]} is a shorthand for {x: {$in: [1, 2, 3]}}
  if Array.isArray value
    return dsl.in keyFragment, value

  # FROM HERE ON `value` IS AN OBJECT AND NOT A NUMBER, STRING, ARRAY, ...

  keys = Object.keys value

  hasModifier = keys.length is 1 and 0 is keys[0].indexOf '$'

  unless hasModifier
    # handle other objects which are values but have no modifiers
    # (dates for example) like primitives (strings, numbers)
    return dsl.eq keyFragment, value

  modifier = keys[0]
  innerValue = value[modifier]

  # FROM HERE ON `value` IS AN OBJECT WITH A `modifier` KEY AND an `innerValue`

  unless innerValue?
    throw new TypeError "value undefined or null for key #{key} and modifier key #{modifier}"

  modifierFactory = modifiers[modifier]

  if modifierFactory?
    return modifierFactory keyFragment, innerValue

  throw new Error "unknown modifier key #{modifier}"

###################################################################################
# EXPORTS

module.exports = criterion

# make the dsl public
for key, value of dsl
  do (key, value) ->
    criterion[key] = value

# make the helpers available to mesa, mohair
# and any other module that needs them
criterion.helper = helper

# make prototypes available
criterion.prototypes = prototypes
