{beget, isRaw} = require './util'

prototypes = {}

module.exports = constructors = {}

# base
# ----

prototypes.base =
    not: -> constructors.not @
    and: (other) -> constructors.and [@, other]
    or: (other) -> constructors.or [@, other]

# raw sql
# -------

prototypes.raw = beget prototypes.base,
    sql: -> @_sql
    params: -> @_params

constructors.raw = (sql, params) ->
    beget prototypes.raw, {_sql: sql, _params: params}

# comparison
# ----------

prototypes.comparison = beget prototypes.base,
    sql: ->
        if isRaw @_v
            "#{@_k} #{@_op} #{@_v.sql()}"
        else
            "#{@_k} #{@_op} ?"
    params: ->
        if isRaw @_v
            if 'function' is typeof @_v.params
                @_v.params()
            else
                []
        else
            [@_v]

comparisonConstructorByOperator = (op) ->
    (k, v) ->
        beget prototypes.comparison, {_k: k, _v: v, _op: op}

constructors.equal = comparisonConstructorByOperator '='
constructors.notEqual = comparisonConstructorByOperator '!='
constructors.lowerThan = comparisonConstructorByOperator '<'
constructors.lowerThanEqual = comparisonConstructorByOperator '<='
constructors.greaterThan = comparisonConstructorByOperator '>'
constructors.greaterThanEqual = comparisonConstructorByOperator '>='

# null
# ----

prototypes.null = beget prototypes.base,
    sql: -> "#{@_k} IS #{if @_isNull then '' else 'NOT '}NULL"
    params: -> []

constructors.null = (k, isNull) ->
    beget prototypes.null, {_k: k, _isNull: isNull}

# negation
# --------

prototypes.not = beget prototypes.base,
    innerCriterion: -> @_criterion._criterion
    sql: ->
        # remove double negation
        if isNotCriterion @_criterion
            @innerCriterion().sql()
        else "NOT (#{@_criterion.sql()})"
    params: -> @_criterion.params()

isNotCriterion = (c) ->
    prototypes.not.isPrototypeOf c

constructors.not = (criterion) ->
    beget prototypes.not, {_criterion: criterion}

# in
# --

prototypes.in = beget prototypes.base,
    sql: ->
        questionMarks = []
        @_vs.forEach -> questionMarks.push '?'
        "#{@_k} #{@_op} (#{questionMarks.join ', '})"
    params: -> @_vs

constructors.in = (k, vs) ->
    beget prototypes.in, {_k: k, _vs: vs, _op: 'IN'}

constructors.notIn = (k, vs) ->
    beget prototypes.in, {_k: k, _vs: vs, _op: 'NOT IN'}

# combination
# -----------

prototypes.combination = beget prototypes.base,
    sql: ->
        @_criteria.map((c) -> "(#{c.sql()})").join " #{@_op} "

    params: ->
        params = []
        @_criteria.forEach (c) -> params = params.concat c.params()
        params

constructors.and = (criteria) ->
    beget prototypes.combination, {_criteria: criteria, _op: 'AND'}

constructors.or = (criteria) ->
    beget prototypes.combination, {_criteria: criteria, _op: 'OR'}
