constructors = require './constructors'
{arrayify} = require './util'

# recursively construct the object graph of the criterion

module.exports = factory = (first, rest...) ->
    type = typeof first

    unless 'string' is type or 'object' is type
        throw new Error """
            string or object expected as first argument
            but #{type} given
        """

    # raw sql with optional bindings?
    return constructors.raw first, rest if type is 'string'

    if Array.isArray first
        if first.length is 0
            throw new Error 'empty criterion'
        return constructors.and first.map factory

    keyCount = Object.keys(first).length

    if 0 is keyCount
        throw new Error 'empty criterion'

    if keyCount > 1
        # break it down if there is more than one key
        return constructors.and arrayify(first).map factory

    key = Object.keys(first)[0]
    value = first[key]

    if key is '$or'
        return constructors.or arrayify(value).map factory

    if key is '$not'
        return constructors.not factory value

    unless 'object' is typeof value
        return constructors.equal key, value

    if Array.isArray value
        if value.length is 0
            throw Error 'in with empty array'
        return constructors.in key, value

    unless value?
        throw new Error "value undefined or null for key #{key}"

    keys = Object.keys value

    modifier = keys[0]

    if keys.length is 1 and 0 is modifier.indexOf '$'
        innerValue = value[modifier]
        unless innerValue?
            throw new Error "value undefined or null for key #{key} and modifier #{modifier}"
        switch modifier
            when '$nin'
                if innerValue.length is 0
                    throw Error '$nin with empty array'
                constructors.notIn key, innerValue
            when '$lt' then constructors.lowerThan key, innerValue
            when '$lte' then constructors.lowerThanEqual key, innerValue
            when '$gt' then constructors.greaterThan key, innerValue
            when '$gte' then constructors.greaterThanEqual key, innerValue
            when '$ne' then constructors.notEqual key, innerValue
            when '$null' then constructors.null key, innerValue
            else throw new Error "unknown modifier: #{modifier}"
    else
        constructors.equal key, value
