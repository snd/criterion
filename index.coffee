Criterion = class
    not: -> new Not @
    and: (other) -> new And [@, other]
    or: (other) -> new Or [@, other]

Sql = class extends Criterion
    constructor: (@_sql, @_params = []) ->
    sql: -> @_sql
    params: -> @_params

Eq = class extends Criterion
    constructor: (@_k, @_v) ->
    sql: -> "#{@_k} = ?"
    params: -> [@_v]

Ne = class extends Criterion
    constructor: (@_k, @_v) ->
    sql: -> "#{@_k} != ?"
    params: -> [@_v]

Lt = class extends Criterion
    constructor: (@_k, @_v) ->
    sql: -> "#{@_k} < ?"
    params: -> [@_v]

Lte = class extends Criterion
    constructor: (@_k, @_v) ->
    sql: -> "#{@_k} <= ?"
    params: -> [@_v]

Gt = class extends Criterion
    constructor: (@_k, @_v) ->
    sql: -> "#{@_k} > ?"
    params: -> [@_v]

Gte = class extends Criterion
    constructor: (@_k, @_v) ->
    sql: -> "#{@_k} >= ?"
    params: -> [@_v]

Null = class extends Criterion
    constructor: (@_k, @_isNull) ->
    sql: -> "#{@_k} IS #{if @_isNull then '' else 'NOT '}NULL"
    params: -> []

Not = class extends Criterion

    constructor: (@_criterion) ->

    sql: ->
        if @_criterion instanceof Not
            # remove double negation
            @_criterion._criterion.sql()
        else
            "NOT (#{@_criterion.sql()})"

    params: -> @_criterion.params()

In = class extends Criterion
    constructor: (@_k, @_vs) ->

    sql: ->
        questionMarks = []
        @_vs.forEach -> questionMarks.push '?'
        "#{@_k} IN (#{questionMarks.join ', '})"

    params: -> @_vs

Nin = class extends Criterion
    constructor: (@_k, @_vs) ->

    sql: ->
        questionMarks = []
        @_vs.forEach -> questionMarks.push '?'
        "#{@_k} NOT IN (#{questionMarks.join ', '})"

    params: -> @_vs

And = class extends Criterion

    constructor: (@_criteria) ->

    sql: ->
        @_criteria.map((c) -> "(#{c.sql()})").join ' AND '

    params: ->
        params = []
        @_criteria.forEach (c) -> params = params.concat c.params()
        params

Or = class extends Criterion

    constructor: (@_criteria) ->

    sql: ->
        @_criteria.map((c) -> "(#{c.sql()})").join ' OR '

    params: ->
        params = []
        @_criteria.forEach (c) -> params = params.concat c.params()
        params

arrayify = (thing) ->
    return thing if Array.isArray thing

    array = []
    for k, v of thing
        do (k, v) ->
            obj = {}
            obj[k] = v
            array.push obj
    array

# recursively construct the object graph

module.exports = construct = (first, rest...) ->
        type = typeof first
        unless type in ['string', 'object']
            throw new Error """
                string or object expected as first argument
                but #{type} given
            """

        return new Sql first, rest if type is 'string'

        if Array.isArray first
            if first.length is 0
                throw new Error 'empty criterion'
            return new And first.map construct

        keyCount = Object.keys(first).length

        if 0 is keyCount
            throw new Error 'empty criterion'

        if 1 is keyCount
            key = Object.keys(first)[0]
            value = first[key]

            return switch key
                when '$or' then new Or arrayify(value).map construct
                when '$not' then new Not construct value
                else
                    if (typeof value) is 'object'
                        if Array.isArray value
                            if value.length is 0
                                throw Error 'in with empty array'
                            return new In key, value
                        keys = Object.keys value

                        if keys.length is 1 and 0 is keys[0].indexOf '$'
                            modifier = keys[0]
                            innerValue = value[modifier]
                            switch modifier
                                when '$nin'
                                    if innerValue.length is 0
                                        throw Error '$nin with empty array'
                                    new Nin key, innerValue
                                when '$lt' then new Lt key, innerValue
                                when '$lte' then new Lte key, innerValue
                                when '$gt' then new Gt key, innerValue
                                when '$gte' then new Gte key, innerValue
                                when '$ne' then new Ne key, innerValue
                                when '$null' then new Null key, innerValue
                                else throw new Error "unknown modifier: #{modifier}"
                        else new Eq key, value
                    else new Eq key, value

        # break it down if there is more than one key
        new And arrayify(first).map construct
