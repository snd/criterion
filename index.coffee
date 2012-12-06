beget = require 'beget'

criterionPrototype =
    not: -> newNot @
    and: (other) -> newAnd [@, other]
    or: (other) -> newOr [@, other]

sqlPrototype = beget criterionPrototype,
    sql: -> @_sql
    params: -> @_params
newSql = (sql, params) -> beget sqlPrototype, {_sql: sql, _params: params}

comparePrototype = beget criterionPrototype,
    sql: -> "#{@_k} #{@_op} ?"
    params: -> [@_v]
newEqual = (k, v) -> beget comparePrototype, {_k: k, _v: v, _op: '='}
newNotEqual = (k, v) -> beget comparePrototype, {_k: k, _v: v, _op: '!='}
newLowerThan = (k, v) -> beget comparePrototype, {_k: k, _v: v, _op: '<'}
newLowerThanEqual = (k, v) -> beget comparePrototype, {_k: k, _v: v, _op: '<='}
newGreaterThan = (k, v) -> beget comparePrototype, {_k: k, _v: v, _op: '>'}
newGreaterThanEqual = (k, v) -> beget comparePrototype, {_k: k, _v: v, _op: '>='}

nullPrototype = beget criterionPrototype,
    sql: -> "#{@_k} IS #{if @_isNull then '' else 'NOT '}NULL"
    params: -> []
newNull = (k, isNull) -> beget nullPrototype, {_k: k, _isNull: isNull}

notPrototype = beget criterionPrototype,
    sql: ->
        # remove double negation
        if notPrototype.isPrototypeOf @_criterion
            @_criterion._criterion.sql()
        else "NOT (#{@_criterion.sql()})"
    params: -> @_criterion.params()
newNot = (criterion) -> beget notPrototype, {_criterion: criterion}

inPrototype = beget criterionPrototype,
    sql: ->
        questionMarks = []
        @_vs.forEach -> questionMarks.push '?'
        "#{@_k} #{@_op} (#{questionMarks.join ', '})"
    params: -> @_vs
newIn = (k, vs) -> beget inPrototype, {_k: k, _vs: vs, _op: 'IN'}
newNotIn = (k, vs) -> beget inPrototype, {_k: k, _vs: vs, _op: 'NOT IN'}

combinePrototype = beget criterionPrototype,
    sql: ->
        @_criteria.map((c) -> "(#{c.sql()})").join " #{@_op} "

    params: ->
        params = []
        @_criteria.forEach (c) -> params = params.concat c.params()
        params

newAnd = (criteria) -> beget combinePrototype, {_criteria: criteria, _op: 'AND'}
newOr = (criteria) -> beget combinePrototype, {_criteria: criteria, _op: 'OR'}

arrayify = (thing) ->
    return thing if Array.isArray thing

    array = []
    for k, v of thing
        do (k, v) ->
            obj = {}
            obj[k] = v
            array.push obj
    array

# recursively construct the object graph of the criterion

module.exports = (first, rest...) ->
        type = typeof first
        unless 'string' is type or 'object' is type
            throw new Error """
                string or object expected as first argument
                but #{type} given
            """

        return newSql first, rest if type is 'string'

        if Array.isArray first
            if first.length is 0
                throw new Error 'empty criterion'
            return newAnd first.map module.exports

        switch Object.keys(first).length
            when 0 then throw new Error 'empty criterion'
            when 1
            else
                # break it down if there is more than one key
                newAnd arrayify(first).map module.exports

        keyCount = Object.keys(first).length

        if 0 is keyCount
            throw new Error 'empty criterion'

        if keyCount > 1
            # break it down if there is more than one key
            return newAnd arrayify(first).map module.exports

        else
            key = Object.keys(first)[0]
            value = first[key]

            return switch key
                when '$or' then newOr arrayify(value).map module.exports
                when '$not' then newNot module.exports value
                else
                    if (typeof value) is 'object'
                        if Array.isArray value
                            if value.length is 0
                                throw Error 'in with empty array'
                            return newIn key, value
                        keys = Object.keys value

                        if keys.length is 1 and 0 is keys[0].indexOf '$'
                            modifier = keys[0]
                            innerValue = value[modifier]
                            switch modifier
                                when '$nin'
                                    if innerValue.length is 0
                                        throw Error '$nin with empty array'
                                    newNotIn key, innerValue
                                when '$lt' then newLowerThan key, innerValue
                                when '$lte' then newLowerThanEqual key, innerValue
                                when '$gt' then newGreaterThan key, innerValue
                                when '$gte' then newGreaterThanEqual key, innerValue
                                when '$ne' then newNotEqual key, innerValue
                                when '$null' then newNull key, innerValue
                                else throw new Error "unknown modifier: #{modifier}"
                        else newEqual key, value
                    else newEqual key, value
