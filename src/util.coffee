# return a new object which has `proto` as its prototype and
# all properties in `properties`

module.exports.beget = (proto, properties) ->
  object = Object.create proto

  if properties?
    for k, v of properties
      do (k, v) -> object[k] = v

  return object

# if `thing` is an array return `thing`
# otherwise return an array of all key value pairs in `thing` as objects

module.exports.arrayify = (thing) ->
  return thing if Array.isArray thing

  array = []
  for k, v of thing
    do (k, v) ->
      obj = {}
      obj[k] = v
      array.push obj
  array

module.exports.isRaw = (value) ->
  value? and 'function' is typeof value.sql

# calls fun for the values in array. returns the first
# value returned by transform for which predicate returns true.
# otherwise returns sentinel.

module.exports.some = (
  array
  iterator = (x) -> x
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
