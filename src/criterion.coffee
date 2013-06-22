{beget, arrayify} = require './util'

# base
# ----

criterionPrototype =
    not: -> newNot @
    and: (other) -> newAnd [@, other]
    or: (other) -> newOr [@, other]

# raw sql
# -------

rawSqlPrototype = beget criterionPrototype,
    sql: -> @_sql
    params: -> @_params

newRawSql = (sql, params) -> beget rawSqlPrototype, {_sql: sql, _params: params}

# comparison
# ----------

comparePrototype = beget criterionPrototype,
    sql: ->
        if 'function' is typeof @_v.sql
            "#{@_k} #{@_op} #{@_v.sql()}"
        else
            "#{@_k} #{@_op} ?"
    params: ->
        if 'function' is typeof @_v.sql
            if 'function' is typeof @_v.params
                @_v.params()
            else
                []
        else
            [@_v]

newEqual = (k, v) -> beget comparePrototype, {_k: k, _v: v, _op: '='}
newNotEqual = (k, v) -> beget comparePrototype, {_k: k, _v: v, _op: '!='}
newLowerThan = (k, v) -> beget comparePrototype, {_k: k, _v: v, _op: '<'}
newLowerThanEqual = (k, v) -> beget comparePrototype, {_k: k, _v: v, _op: '<='}
newGreaterThan = (k, v) -> beget comparePrototype, {_k: k, _v: v, _op: '>'}
newGreaterThanEqual = (k, v) -> beget comparePrototype, {_k: k, _v: v, _op: '>='}

# null
# ----

nullPrototype = beget criterionPrototype,
    sql: -> "#{@_k} IS #{if @_isNull then '' else 'NOT '}NULL"
    params: -> []

newNull = (k, isNull) -> beget nullPrototype, {_k: k, _isNull: isNull}

# negation
# --------

notPrototype = beget criterionPrototype,
    innerCriterion: -> @_criterion._criterion
    sql: ->
        # remove double negation
        if isNotCriterion @_criterion
            @innerCriterion().sql()
        else "NOT (#{@_criterion.sql()})"
        # TODO handle the case where there is no sql coming from the inner criterion
    params: -> @_criterion.params()

isNotCriterion = (c) ->
    notPrototype.isPrototypeOf c

newNot = (criterion) -> beget notPrototype, {_criterion: criterion}

# in
# --

inPrototype = beget criterionPrototype,
    sql: ->
        questionMarks = []
        @_vs.forEach -> questionMarks.push '?'
        "#{@_k} #{@_op} (#{questionMarks.join ', '})"
    params: -> @_vs

newIn = (k, vs) -> beget inPrototype, {_k: k, _vs: vs, _op: 'IN'}
newNotIn = (k, vs) -> beget inPrototype, {_k: k, _vs: vs, _op: 'NOT IN'}

# combination
# -----------

combinePrototype = beget criterionPrototype,
    sql: ->
        @_criteria.map((c) -> "(#{c.sql()})").join " #{@_op} "

    params: ->
        params = []
        @_criteria.forEach (c) -> params = params.concat c.params()
        params

newAnd = (criteria) -> beget combinePrototype, {_criteria: criteria, _op: 'AND'}
newOr = (criteria) -> beget combinePrototype, {_criteria: criteria, _op: 'OR'}

# exports
# -------

# recursively construct the object graph of the criterion

module.exports = criterion = (first, rest...) ->
    type = typeof first

    unless 'string' is type or 'object' is type
        throw new Error """
            string or object expected as first argument
            but #{type} given
        """

    # raw sql with optional bindings?
    return newRawSql first, rest if type is 'string'

    if Array.isArray first
        if first.length is 0
            throw new Error 'empty criterion'
        return newAnd first.map criterion

    keyCount = Object.keys(first).length

    if 0 is keyCount
        throw new Error 'empty criterion'

    if keyCount > 1
        # break it down if there is more than one key
        return newAnd arrayify(first).map criterion

    key = Object.keys(first)[0]
    value = first[key]

    if key is '$or'
        return newOr arrayify(value).map criterion

    if key is '$not'
        return newNot criterion value

    unless 'object' is typeof value
        return newEqual key, value

    if Array.isArray value
        if value.length is 0
            throw Error 'in with empty array'
        return newIn key, value

    keys = Object.keys value

    modifier = keys[0]

    if keys.length is 1 and 0 is modifier.indexOf '$'
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
