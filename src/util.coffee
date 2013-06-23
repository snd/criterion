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
