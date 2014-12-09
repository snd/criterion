criterion = C = require '../src/criterion'

escape = (x) -> '"' + x + '"'

module.exports =

  'successfully making criteria':

    'comparisons':

      '=': (test) ->
        SQL = 'x = ?'
        ESCAPED = '"x" = ?'
        PARAMS = [7]

        lang = criterion {x: 7}
        raw = criterion SQL, PARAMS...
        dsl = C.eq(C.escape('x'), 7)

        test.equal lang.sql(), SQL
        test.equal lang.sql(escape), ESCAPED
        test.deepEqual lang.params(), PARAMS

        test.equal raw.sql(), SQL
        test.equal raw.sql(escape), SQL
        test.deepEqual raw.params(), PARAMS

        test.equal dsl.sql(), SQL
        test.equal dsl.sql(escape), ESCAPED
        test.deepEqual dsl.params(), PARAMS

        test.done()

      '!=': (test) ->
        SQL = 'x != ?'
        ESCAPED = '"x" != ?'
        PARAMS = ['a']

        lang = criterion {x: {$ne: 'a'}}
        raw = criterion SQL, PARAMS...
        dsl = C.ne(C.escape('x'), 'a')

        test.equal lang.sql(), SQL
        test.equal lang.sql(escape), ESCAPED
        test.deepEqual lang.params(), PARAMS

        test.equal raw.sql(), SQL
        test.equal raw.sql(escape), SQL
        test.deepEqual raw.params(), PARAMS

        test.equal dsl.sql(), SQL
        test.equal dsl.sql(escape), ESCAPED
        test.deepEqual dsl.params(), PARAMS

        test.done()

      '< AND <=': (test) ->
        SQL = '(x < ?) AND (y <= ?)'
        ESCAPED = '("x" < ?) AND ("y" <= ?)'
        PARAMS = [3, 4]

        lang = criterion {x: {$lt: 3}, y: {$lte: 4}}
        raw = criterion SQL, PARAMS...
        dsl = C.and(
          C.lt(C.escape('x'), 3)
          C.lte(C.escape('y'), 4)
        )

        test.equal lang.sql(), SQL
        test.equal lang.sql(escape), ESCAPED
        test.deepEqual lang.params(), PARAMS

        test.equal raw.sql(), SQL
        test.equal raw.sql(escape), SQL
        test.deepEqual raw.params(), PARAMS

        test.equal dsl.sql(), SQL
        test.equal dsl.sql(escape), ESCAPED
        test.deepEqual dsl.params(), PARAMS

        test.done()

      '> AND >=': (test) ->
        SQL = '(x > ?) AND (y >= ?)'
        ESCAPED = '("x" > ?) AND ("y" >= ?)'
        PARAMS = [5, 6]

        lang = criterion {x: {$gt: 5}, y: {$gte: 6}}
        raw = criterion SQL, PARAMS...
        dsl = C.and(
          C.gt(C.escape('x'), 5)
          C.gte(C.escape('y'), 6)
        )

        test.equal lang.sql(), SQL
        test.equal lang.sql(escape), ESCAPED
        test.deepEqual lang.params(), PARAMS

        test.equal raw.sql(), SQL
        test.equal raw.sql(escape), SQL
        test.deepEqual raw.params(), PARAMS

        test.equal dsl.sql(), SQL
        test.equal dsl.sql(escape), ESCAPED
        test.deepEqual dsl.params(), PARAMS

        test.done()

      'NULL': (test) ->
        SQL = 'x IS NULL'
        ESCAPED = '"x" IS NULL'
        PARAMS = []

        lang = criterion {x: {$null: true}}
        raw = criterion SQL, PARAMS...
        dsl = C.null(C.escape('x'))

        test.equal lang.sql(), SQL
        test.equal lang.sql(escape), ESCAPED
        test.deepEqual lang.params(), PARAMS

        test.equal raw.sql(), SQL
        test.equal raw.sql(escape), SQL
        test.deepEqual raw.params(), PARAMS

        test.equal dsl.sql(), SQL
        test.equal dsl.sql(escape), ESCAPED
        test.deepEqual dsl.params(), PARAMS

        test.done()

      'NOT NULL': (test) ->
        SQL = 'x IS NOT NULL'
        ESCAPED = '"x" IS NOT NULL'
        PARAMS = []

        lang = criterion {x: {$null: false}}
        raw = criterion SQL, PARAMS...
        dsl = C.null(C.escape('x'), false)

        test.equal lang.sql(), SQL
        test.equal lang.sql(escape), ESCAPED
        test.deepEqual lang.params(), PARAMS

        test.equal raw.sql(), SQL
        test.equal raw.sql(escape), SQL
        test.deepEqual raw.params(), PARAMS

        test.equal dsl.sql(), SQL
        test.equal dsl.sql(escape), ESCAPED
        test.deepEqual dsl.params(), PARAMS

        test.done()

    'arrays or scalar expressions':

      'IN': (test) ->
        SQL = 'x IN (?, ?, ?)'
        ESCAPED = '"x" IN (?, ?, ?)'
        PARAMS = [1, 2, 3]

        lang = criterion {x: [1, 2, 3]}
        langLong = criterion {x: {$in: [1, 2, 3]}}
        raw = criterion SQL, PARAMS...
        dsl = C.in(C.escape('x'), [1, 2, 3])

        test.equal lang.sql(), SQL
        test.equal lang.sql(escape), ESCAPED
        test.deepEqual lang.params(), PARAMS

        test.equal langLong.sql(), SQL
        test.equal langLong.sql(escape), ESCAPED
        test.deepEqual langLong.params(), PARAMS

        test.equal raw.sql(), SQL
        test.equal raw.sql(escape), SQL
        test.deepEqual raw.params(), PARAMS

        test.equal dsl.sql(), SQL
        test.equal dsl.sql(escape), ESCAPED
        test.deepEqual dsl.params(), PARAMS

        test.done()

      'NOT IN': (test) ->
        SQL = 'x NOT IN (?, ?, ?)'
        ESCAPED = '"x" NOT IN (?, ?, ?)'
        PARAMS = [1, 2, 3]

        lang = criterion {x: {$nin: [1, 2, 3]}}
        raw = criterion SQL, PARAMS...
        dsl = C.nin(C.escape('x'), [1, 2, 3])

        test.equal lang.sql(), SQL
        test.equal lang.sql(escape), ESCAPED
        test.deepEqual lang.params(), PARAMS

        test.equal raw.sql(), SQL
        test.equal raw.sql(escape), SQL
        test.deepEqual raw.params(), PARAMS

        test.equal dsl.sql(), SQL
        test.equal dsl.sql(escape), ESCAPED
        test.deepEqual dsl.params(), PARAMS

        test.done()

    'boolean operations':

      'AND': (test) ->
        SQL = '(x = ?) AND (y = ?) AND (z = ?) AND a = ?'
        ESCAPED = '("x" = ?) AND ("y" = ?) AND ("z" = ?) AND a = ?'
        PARAMS = [7, 'foo', 2.5, 6]

        lang1 = criterion {x: 7, y: 'foo'}, {z: 2.5}, [criterion('a = ?', 6)]
        lang2 = criterion [{x: 7, y: 'foo'}, {z: 2.5}, criterion('a = ?', 6)]
        lang3 = criterion {$and: [{x: 7, y: 'foo'}, {z: 2.5}, criterion('a = ?', 6)]}
        lang4 = criterion {x: 7, y: 'foo', $and: [{z: 2.5}, criterion('a = ?', 6)]}
        raw = criterion SQL, PARAMS...
        dsl1 = C.and(
          C.eq(C.escape('x'), 7)
          C.eq(C.escape('y'), 'foo')
          C.eq(C.escape('z'), 2.5)
          C('a = ?', 6)
        )
        dsl2 = C.and(
          C.eq(C.escape('x'), 7)
          C.eq(C.escape('y'), 'foo')
          C.and(
            C.eq(C.escape('z'), 2.5)
            C('a = ?', 6)
          )
        )
        dsl3 = C(
          C.eq(C.escape('x'), 7)
          C.eq(C.escape('y'), 'foo')
          C(
            C.eq(C.escape('z'), 2.5)
            C('a = ?', 6)
          )
        )

        test.equal lang1.sql(), SQL
        test.equal lang1.sql(escape), ESCAPED
        test.deepEqual lang1.params(), PARAMS

        test.equal lang2.sql(), SQL
        test.equal lang2.sql(escape), ESCAPED
        test.deepEqual lang2.params(), PARAMS

        test.equal lang3.sql(), SQL
        test.equal lang3.sql(escape), ESCAPED
        test.deepEqual lang3.params(), PARAMS

        test.equal lang4.sql(), SQL
        test.equal lang4.sql(escape), ESCAPED
        test.deepEqual lang4.params(), PARAMS

        test.equal raw.sql(), SQL
        test.equal raw.sql(escape), SQL
        test.deepEqual raw.params(), PARAMS

        test.equal dsl1.sql(), SQL
        test.equal dsl1.sql(escape), ESCAPED
        test.deepEqual dsl1.params(), PARAMS

        test.equal dsl2.sql(), SQL
        test.equal dsl2.sql(escape), ESCAPED
        test.deepEqual dsl2.params(), PARAMS

        test.equal dsl3.sql(), SQL
        test.equal dsl3.sql(escape), ESCAPED
        test.deepEqual dsl3.params(), PARAMS

        test.done()

      'OR': (test) ->
        SQL = '(x = ?) OR (y = ?) OR (z = ?) OR a = ?'
        ESCAPED = '("x" = ?) OR ("y" = ?) OR ("z" = ?) OR a = ?'
        PARAMS = [7, 'foo', 2.5, 6]

        lang1 = criterion {$or: [{x: 7}, {y: 'foo'}, {z: 2.5}, criterion('a = ?', 6)]}
        lang2 = criterion {$or: {x: 7, y: 'foo', $or: [{z: 2.5}, criterion('a = ?', 6)]}}
        raw = criterion SQL, PARAMS...
        dsl1 = C.or(
          C.eq(C.escape('x'), 7)
          C.eq(C.escape('y'), 'foo')
          C.eq(C.escape('z'), 2.5)
          C('a = ?', 6)
        )
        dsl2 = C.or(
          C.eq(C.escape('x'), 7)
          C.eq(C.escape('y'), 'foo')
          C.or(
            C.eq(C.escape('z'), 2.5)
            C('a = ?', 6)
          )
        )

        test.equal lang1.sql(), SQL
        test.equal lang1.sql(escape), ESCAPED
        test.deepEqual lang1.params(), PARAMS

        test.equal lang2.sql(), SQL
        test.equal lang2.sql(escape), ESCAPED
        test.deepEqual lang2.params(), PARAMS

        test.equal raw.sql(), SQL
        test.equal raw.sql(escape), SQL
        test.deepEqual raw.params(), PARAMS

        test.equal dsl1.sql(), SQL
        test.equal dsl1.sql(escape), ESCAPED
        test.deepEqual dsl1.params(), PARAMS

        test.equal dsl2.sql(), SQL
        test.equal dsl2.sql(escape), ESCAPED
        test.deepEqual dsl2.params(), PARAMS

        test.done()

      'NOT': (test) ->
        SQL = 'NOT ((x > ?) AND (y >= ?))'
        ESCAPED = 'NOT (("x" > ?) AND ("y" >= ?))'
        PARAMS = [3, 4]

        lang = criterion {$not: {x: {$gt: 3}, y: {$gte: 4}}}
        raw = criterion SQL, PARAMS...
        dsl = C.not(
          C.and(
            C.gt(C.escape('x'), 3)
            C.gte(C.escape('y'), 4)
          )
        )

        test.equal lang.sql(), SQL
        test.equal lang.sql(escape), ESCAPED
        test.deepEqual lang.params(), PARAMS

        test.equal raw.sql(), SQL
        test.equal raw.sql(escape), SQL
        test.deepEqual raw.params(), PARAMS

        test.equal dsl.sql(), SQL
        test.equal dsl.sql(escape), ESCAPED
        test.deepEqual dsl.params(), PARAMS

        test.done()

      'OR inside AND (is wrapped in parentheses)': (test) ->
        SQL = '(username = ?) AND (password = ?) AND ((active = ?) OR (active IS NULL))'
        ESCAPED = '("username" = ?) AND ("password" = ?) AND (("active" = ?) OR ("active" IS NULL))'
        PARAMS = ['user', 'hash', 1]

        lang = criterion
          username: 'user'
          password: 'hash'
          $or: [{active: 1}, {active: {$null: true}}]
        raw = criterion SQL, PARAMS...
        dsl = C.and(
          C.eq(C.escape('username'), 'user')
          C.eq(C.escape('password'), 'hash')
          C.or(
            C.eq(C.escape('active'), 1)
            C.null(C.escape('active'))
          )
        )

        test.equal lang.sql(), SQL
        test.equal lang.sql(escape), ESCAPED
        test.deepEqual lang.params(), PARAMS

        test.equal raw.sql(), SQL
        test.equal raw.sql(escape), SQL
        test.deepEqual raw.params(), PARAMS

        test.equal dsl.sql(), SQL
        test.equal dsl.sql(escape), ESCAPED
        test.deepEqual dsl.params(), PARAMS

        test.done()

      'AND, OR and NOT can be deeply nested': (test) ->
        SQL = '(alpha = ?) OR ((charlie != ?) AND (NOT (((delta = ?) OR (delta IS NULL)) AND (echo = ?)))) OR ((echo < ?) AND ((golf = ?) OR (NOT (lima != ?)))) OR (foxtrot = ?) OR (NOT (alpha = ? OR (NOT (echo < ?)) OR (alpha < ?) OR (bravo = ?) OR ((alpha = ?) AND (bravo = ?)))) OR (bravo = ?)'
        ESCAPED = '("alpha" = ?) OR (("charlie" != ?) AND (NOT ((("delta" = ?) OR ("delta" IS NULL)) AND ("echo" = ?)))) OR (("echo" < ?) AND (("golf" = ?) OR (NOT ("lima" != ?)))) OR ("foxtrot" = ?) OR (NOT (alpha = ? OR (NOT ("echo" < ?)) OR ("alpha" < ?) OR ("bravo" = ?) OR (("alpha" = ?) AND ("bravo" = ?)))) OR ("bravo" = ?)'
        PARAMS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

        lang = criterion {
          $or: {
            alpha: 1
            $and: {
              charlie: {$ne: 2}
              $not: {
                $and: {
                  $or: [
                    {delta: 3},
                    {delta: {$null: true}}
                  ]
                  echo: 4
                }
              }
            }
            $or: [
              [
                {echo: {$lt: 5}}
                {$or: {
                  golf: 6
                  $not: {lima: {$ne: 7}}
                }}
              ]
              {foxtrot: 8}
            ]
            $not: {
              $or: [
                criterion('alpha = ?', 9)
                {$not: {echo: {$lt: 10}}}
                {alpha: {$lt: 11}}
                {bravo: 12}
                [
                  {alpha: 13}
                  {bravo: 14}
                ]
              ]
            }
            bravo: 15
          }
        }
        raw = criterion SQL, PARAMS...

        dsl = C.or(
          C.eq(C.escape('alpha'), 1)
          C.and(
            C.ne(C.escape('charlie'), 2)
            C.not(
              C.and(
                C.or(
                  C.eq(C.escape('delta'), 3)
                  C.null(C.escape('delta'))
                )
                C.eq(C.escape('echo'), 4)
              )
            )
          )
          C.or(
            C.and(
              C.lt(C.escape('echo'), 5)
              C.or(
                C.eq(C.escape('golf'), 6)
                C.not(
                  C.ne(C.escape('lima'), 7)
                )
              )
            )
            C.eq(C.escape('foxtrot'), 8)
          )
          C.not(
            C.or(
              C('alpha = ?', 9)
              C.not(
                C.lt(C.escape('echo'), 10)
              )
              C.lt(C.escape('alpha'), 11)
              C.eq(C.escape('bravo'), 12)
              C(
                C.eq(C.escape('alpha'), 13)
                C.eq(C.escape('bravo'), 14)
              )
            )
          )
          C.eq(C.escape('bravo'), 15)
        )

        test.equal lang.sql(), SQL
        test.equal lang.sql(escape), ESCAPED
        test.deepEqual lang.params(), PARAMS

        test.equal raw.sql(), SQL
        test.equal raw.sql(escape), SQL
        test.deepEqual raw.params(), PARAMS

        test.equal dsl.sql(), SQL
        test.equal dsl.sql(escape), ESCAPED
        test.deepEqual dsl.params(), PARAMS

        test.done()

    'subqueries':

      'IN and $nin': (test) ->
        subquery =
          sql: (escape) ->
            "SELECT #{escape 'id'} FROM \"user\" WHERE #{escape 'is_active'}"
          params: -> []

        subqueryWithParams =
          sql: (escape) ->
            "SELECT #{escape 'id'} FROM \"user\" WHERE #{escape 'is_active'} = ?"
          params: ->
            [true]

        inWithoutParams = criterion {x: {$in: subquery}}

        test.equal inWithoutParams.sql(), 'x IN (SELECT id FROM "user" WHERE is_active)'
        test.equal inWithoutParams.sql(escape), '"x" IN (SELECT "id" FROM "user" WHERE "is_active")'
        test.deepEqual inWithoutParams.params(), []

        inWithParams = criterion {x: {$in: subqueryWithParams}}

        test.equal inWithParams.sql(), 'x IN (SELECT id FROM "user" WHERE is_active = ?)'
        test.equal inWithParams.sql(escape), '"x" IN (SELECT "id" FROM "user" WHERE "is_active" = ?)'
        test.deepEqual inWithParams.params(), [true]

        ninWithoutParams = criterion {x: {$nin: subquery}}

        test.equal ninWithoutParams.sql(), 'x NOT IN (SELECT id FROM "user" WHERE is_active)'
        test.equal ninWithoutParams.sql(escape), '"x" NOT IN (SELECT "id" FROM "user" WHERE "is_active")'
        test.deepEqual ninWithoutParams.params(), []

        ninWithParams = criterion {x: {$nin: subqueryWithParams}}

        test.equal ninWithParams.sql(), 'x NOT IN (SELECT id FROM "user" WHERE is_active = ?)'
        test.equal ninWithParams.sql(escape), '"x" NOT IN (SELECT "id" FROM "user" WHERE "is_active" = ?)'
        test.deepEqual ninWithParams.params(), [true]

        test.done()

      '$exists': (test) ->
        subquery =
          sql: (escape) ->
            "SELECT * FROM \"user\" WHERE #{escape 'is_active'}"
          params: -> []
        subqueryWithParams =
          sql: (escape) ->
            "SELECT * FROM \"user\" WHERE #{escape 'is_active'} = ?"
          params: ->
            [true]

        existsWithoutParams = criterion {id: 7, $exists: subquery}

        test.equal existsWithoutParams.sql(), '(id = ?) AND (EXISTS (SELECT * FROM "user" WHERE is_active))'
        test.equal existsWithoutParams.sql(escape), '("id" = ?) AND (EXISTS (SELECT * FROM "user" WHERE "is_active"))'
        test.deepEqual existsWithoutParams.params(), [7]

        existsWithParams = criterion {id: 7, $exists: subqueryWithParams}

        test.equal existsWithParams.sql(), '(id = ?) AND (EXISTS (SELECT * FROM "user" WHERE is_active = ?))'
        test.equal existsWithParams.sql(escape), '("id" = ?) AND (EXISTS (SELECT * FROM "user" WHERE "is_active" = ?))'
        test.deepEqual existsWithParams.params(), [7, true]

        test.done()

      '$any, $neAny, $ltAny, $lteAny, $gtAny, $gteAny, $all, $neAll, $ltAll, $lteAll, $gtAll, $gteAll': (test) ->
        subquery =
          sql: (escape) ->
            "SELECT * FROM #{escape "user"}"
          params: -> []

        subqueryWithParams =
          sql: (escape) ->
            "SELECT * FROM #{escape "user"} WHERE #{escape "id"} = ?"
          params: ->
            [7]

        anyWithoutParams = criterion {x: {$any: subquery}}

        test.equal anyWithoutParams.sql(), 'x = ANY (SELECT * FROM user)'
        test.equal anyWithoutParams.sql(escape), '"x" = ANY (SELECT * FROM "user")'
        test.deepEqual anyWithoutParams.params(), []

        anyWithParams = criterion {x: {$any: subqueryWithParams}, y: 6}

        test.equal anyWithParams.sql(), '(x = ANY (SELECT * FROM user WHERE id = ?)) AND (y = ?)'
        test.equal anyWithParams.sql(escape), '("x" = ANY (SELECT * FROM "user" WHERE "id" = ?)) AND ("y" = ?)'
        test.deepEqual anyWithParams.params(), [7, 6]

        # since all other subqueries follow the same code path
        # we omit testing with params and escaping for them

        test.equal criterion({x: {$neAny: subquery}}).sql(), 'x != ANY (SELECT * FROM user)'
        test.equal criterion({x: {$ltAny: subquery}}).sql(), 'x < ANY (SELECT * FROM user)'
        test.equal criterion({x: {$lteAny: subquery}}).sql(), 'x <= ANY (SELECT * FROM user)'
        test.equal criterion({x: {$gtAny: subquery}}).sql(), 'x > ANY (SELECT * FROM user)'
        test.equal criterion({x: {$gteAny: subquery}}).sql(), 'x >= ANY (SELECT * FROM user)'

        test.equal criterion({x: {$all: subquery}}).sql(), 'x = ALL (SELECT * FROM user)'
        test.equal criterion({x: {$neAll: subquery}}).sql(), 'x != ALL (SELECT * FROM user)'
        test.equal criterion({x: {$ltAll: subquery}}).sql(), 'x < ALL (SELECT * FROM user)'
        test.equal criterion({x: {$lteAll: subquery}}).sql(), 'x <= ALL (SELECT * FROM user)'
        test.equal criterion({x: {$gtAll: subquery}}).sql(), 'x > ALL (SELECT * FROM user)'
        test.equal criterion({x: {$gteAll: subquery}}).sql(), 'x >= ALL (SELECT * FROM user)'

        test.done()

      'row-wise comparison': (test) ->
        subquery =
          sql: (escape) ->
            "SELECT #{escape 'created_at'} FROM #{escape 'message'} WHERE #{escape 'id'} = ?"
          params: ->
            [1]

        c = criterion {is_active: true, created_at: {$lte: subquery}}

        test.equal c.sql(), '(is_active = ?) AND (created_at <= (SELECT created_at FROM message WHERE id = ?))'
        test.equal c.sql(escape), '("is_active" = ?) AND ("created_at" <= (SELECT "created_at" FROM "message" WHERE "id" = ?))'
        test.deepEqual c.params(), [true, 1]

        test.done()

    'from sql-fragments':

      'without params': (test) ->
        c = criterion 'x IS NULL'

        test.equal c.sql(), 'x IS NULL'
        test.deepEqual c.params(), []

        test.done()

      'with one param': (test) ->
        c = criterion 'x = ?', 7

        test.equal c.sql(), 'x = ?'
        test.deepEqual c.params(), [7]

        test.done()

      'with two params': (test) ->
        c = criterion 'x = ? AND y = ?', 7, 8

        test.equal c.sql(), 'x = ? AND y = ?'
        test.deepEqual c.params(), [7, 8]

        test.done()

      'with one param and one array': (test) ->
        c = criterion 'x = ? AND y IN (?)', 7, [8,9,10]

        test.equal c.sql(), 'x = ? AND y IN (?, ?, ?)'
        test.deepEqual c.params(), [7, 8, 9, 10]

        test.done()

      'with two params and array': (test) ->
        c = criterion 'x = ? AND y = ? AND z IN (?)', 7, 8, [9,10,11]

        test.equal c.sql(), 'x = ? AND y = ? AND z IN (?, ?, ?)'
        test.deepEqual c.params(), [7, 8, 9, 10, 11]

        test.done()

      'with two params and two arrays': (test) ->
        c = criterion 'x = ? AND y = ? AND z IN (?) AND (a && ARRAY[?])', 7, 8, [9,10,11], [12,13,14]

        test.equal c.sql(), 'x = ? AND y = ? AND z IN (?, ?, ?) AND (a && ARRAY[?, ?, ?])'
        test.deepEqual c.params(), [7, 8, 9, 10, 11, 12, 13, 14]

        test.done()

    'from a mix of condition-objects and sql-fragments':

      'equality with criterion argument': (test) ->
        c = criterion {x: criterion('crypt(?, gen_salt(?, ?))', 'password', 'bf', 4)}

        test.equal c.sql(), 'x = crypt(?, gen_salt(?, ?))'
        test.equal c.sql(escape), '"x" = crypt(?, gen_salt(?, ?))'
        test.deepEqual c.params(), ['password', 'bf', 4]

        test.done()

      '$ne with criterion argument': (test) ->
        c = criterion {x: {$ne: criterion('crypt(?, gen_salt(?, ?))', 'password', 'bf', 4)}}

        test.equal c.sql(), 'x != crypt(?, gen_salt(?, ?))'
        test.equal c.sql(escape), '"x" != crypt(?, gen_salt(?, ?))'
        test.deepEqual c.params(), ['password', 'bf', 4]

        test.done()

      '$lt with criterion argument': (test) ->
        c = criterion {x: {$lt: criterion('NOW()')}}

        test.equal c.sql(), 'x < NOW()'
        test.equal c.sql(escape), '"x" < NOW()'
        test.deepEqual c.params(), []

        test.done()

  'successfully manipulating criteria':

    'and': (test) ->
      fst = criterion {x: 7, y: 'foo'}
      snd = criterion 'z = ?', true

      fstAndSnd = fst.and snd

      test.equal fstAndSnd.sql(), '(x = ?) AND (y = ?) AND z = ?'
      test.deepEqual fstAndSnd.params(), [7, 'foo', true]

      test.done()

    'or': (test) ->
      fst = criterion {x: 7, y: 'foo'}
      snd = criterion 'z = ?', true

      sndOrFst = snd.or fst

      test.equal sndOrFst.sql(), 'z = ? OR ((x = ?) AND (y = ?))'
      test.deepEqual sndOrFst.params(), [true, 7, 'foo']

      test.done()

    'not': (test) ->
      c = criterion {x: 7, y: 'foo'}

      test.equal c.not().sql(), 'NOT ((x = ?) AND (y = ?))'
      test.deepEqual c.not().params(), [7, 'foo']

      test.done()

    'double negation is removed': (test) ->
      c = criterion {x: 7, y: 'foo'}

      test.equal c.not().not().sql(), '(x = ?) AND (y = ?)'
      test.deepEqual c.not().not().params(), [7, 'foo']

      test.equal c.not().not().not().sql(), 'NOT ((x = ?) AND (y = ?))'
      test.deepEqual c.not().not().not().params(), [7, 'foo']

      test.done()

  'errors when making criteria':

    'not string or object': (test) ->
      try
        criterion 6
      catch e
        test.equal e.message, 'string or object expected as first argument but number given'
        test.done()

    'empty object': (test) ->
      try
        criterion {}
      catch e
        test.equal e.message, 'empty condition-object'

      try
        criterion [{}]
      catch e
        test.equal e.message, 'empty condition-object'

        test.done()

    'empty array param': (test) ->
      try
        criterion 'b < ? AND a IN(?) AND c < ?', 6, [], 7
      catch e
        test.equal e.message, 'params[1] is an empty array'
        test.done()

    'null value with modifier': (test) ->
      try
        criterion {x: {$lt: null}}
      catch e
        test.equal e.message, 'value undefined or null for key x and modifier key $lt'
        test.done()

    'null value without modifier': (test) ->
      try
        criterion {x: null}
      catch e
        test.equal e.message, 'value undefined or null for key x'
        test.done()

    'in with empty array': (test) ->
      try
        criterion {x: []}
      catch e
        test.equal e.message, '`in` with empty array as right operand'
        test.done()

    '$nin with empty array': (test) ->
      try
        criterion {x: {$nin: []}}
      catch e
        test.equal e.message, '`nin` with empty array as right operand'
        test.done()

    '$any with array': (test) ->
      try
        criterion {x: {$any: [1]}}
      catch e
        test.equal e.message, "`any` doesn't support array as right operand. only `in` and `nin` do!"
        test.done()

    '$any with number': (test) ->
      try
        criterion {x: {$any: 6}}
      catch e
        test.equal e.message, "`any` requires right operand that implements sql-fragment interface"
        test.done()

    'unknown modifier': (test) ->
      try
        criterion {x: {$not: 6}}
      catch e
        test.equal e.message, 'unknown modifier key $not'

      try
        criterion {x: {$foo: 6}}
      catch e
        test.equal e.message, 'unknown modifier key $foo'

        test.done()

    '$exists without sql-fragment': (test) ->
      try
        criterion {$exists: 6}
      catch e
        test.equal e.message, "`exists` operand must implement sql-fragment interface"
        test.done()

    '$in without array or sql-fragment': (test) ->
      try
        criterion({x: {$in: 6}})
      catch e
        test.equal e.message, "`in` requires right operand that is an array or implements sql-fragment interface"
        test.done()

    '$nin without array or sql-fragment': (test) ->
      try
        criterion({x: {$nin: 6}})
      catch e
        test.equal e.message, "`nin` requires right operand that is an array or implements sql-fragment interface"
        test.done()
