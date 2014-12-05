criterion = require '../src/criterion'

escape = (x) -> '"' + x + '"'

module.exports =

  'making criteria':

    'from condition-objects':

      'comparisons':

        '=': (test) ->
          c = criterion {x: 7}

          test.equal c.sql(), 'x = ?'
          test.deepEqual c.params(), [7]

          test.done()

        '$ne': (test) ->
          c = criterion {x: {$ne: 3}}

          test.equal c.sql(), 'x != ?'
          test.equal c.sql(escape), '"x" != ?'
          test.deepEqual c.params(), [3]

          test.done()

        '$lt and $lte': (test) ->
          c = criterion {x: {$lt: 3}, y: {$lte: 4}}

          test.equal c.sql(), '(x < ?) AND (y <= ?)'
          test.equal c.sql(escape), '("x" < ?) AND ("y" <= ?)'
          test.deepEqual c.params(), [3, 4]

          test.done()

        '$gt and $gte': (test) ->
          c = criterion {x: {$gt: 3}, y: {$gte: 4}}

          test.equal c.sql(), '(x > ?) AND (y >= ?)'
          test.equal c.sql(escape), '("x" > ?) AND ("y" >= ?)'
          test.deepEqual c.params(), [3, 4]

          test.done()

        '$null: true': (test) ->
          c = criterion {x: {$null: true}}

          test.equal c.sql(), 'x IS NULL'
          test.equal c.sql(escape), '"x" IS NULL'
          test.deepEqual c.params(), []

          test.done()

        '$null: false': (test) ->
          c = criterion {x: {$null: false}}

          test.equal c.sql(), 'x IS NOT NULL'
          test.equal c.sql(escape), '"x" IS NOT NULL'
          test.deepEqual c.params(), []

          test.done()

      'arrays or scalar expressions':

        'IN': (test) ->
          c = criterion {x: [1, 2, 3]}

          test.equal c.sql(), 'x IN (?, ?, ?)'
          test.equal c.sql(escape), '"x" IN (?, ?, ?)'
          test.deepEqual c.params(), [1, 2, 3]

          test.done()

        '$in': (test) ->
          c = criterion {x: {$in: [1, 2, 3]}}

          test.equal c.sql(), 'x IN (?, ?, ?)'
          test.equal c.sql(escape), '"x" IN (?, ?, ?)'
          test.deepEqual c.params(), [1, 2, 3]

          test.done()

        '$nin': (test) ->
          c = criterion {x: {$nin: [1, 2, 3]}}

          test.equal c.sql(), 'x NOT IN (?, ?, ?)'
          test.equal c.sql(escape), '"x" NOT IN (?, ?, ?)'
          test.deepEqual c.params(), [1, 2, 3]

          test.done()

      'boolean operations':

        'object is joined with AND': (test) ->
          c = criterion {x: 7, y: 'foo'}

          test.equal c.sql(), '(x = ?) AND (y = ?)'
          test.equal c.sql(escape), '("x" = ?) AND ("y" = ?)'
          test.deepEqual c.params(), [7, 'foo']

          test.done()

        'array of objects is joined with AND': (test) ->
          c = criterion [{x: 7, y: 'foo'}, {z: 2.5}, criterion('a = ?', 6)]

          test.equal c.sql(), '((x = ?) AND (y = ?)) AND (z = ?) AND (a = ?)'
          test.equal c.sql(escape), '(("x" = ?) AND ("y" = ?)) AND ("z" = ?) AND (a = ?)'
          test.deepEqual c.params(), [7, 'foo', 2.5, 6]

          test.done()

        '$and with object': (test) ->
          c = criterion {$and: {x: 7, y: 'foo'}}

          test.equal c.sql(), '(x = ?) AND (y = ?)'
          test.equal c.sql(escape), '("x" = ?) AND ("y" = ?)'
          test.deepEqual c.params(), [7, 'foo']

          test.done()

        '$and with array': (test) ->
          c = criterion {$and: [{x: 7, y: 'foo'}, {z: 2.5}, criterion('a = ?', 6)]}

          test.equal c.sql(), '((x = ?) AND (y = ?)) AND (z = ?) AND (a = ?)'
          test.equal c.sql(escape), '(("x" = ?) AND ("y" = ?)) AND ("z" = ?) AND (a = ?)'
          test.deepEqual c.params(), [7, 'foo', 2.5, 6]

          test.done()

        '$or with object': (test) ->
          c = criterion {$or: {x: 7, y: 'foo'}}

          test.equal c.sql(), '(x = ?) OR (y = ?)'
          test.equal c.sql(escape), '("x" = ?) OR ("y" = ?)'
          test.deepEqual c.params(), [7, 'foo']

          test.done()

        '$or with array': (test) ->
          c = criterion {$or: [{x: 7}, {y: 'foo'}, criterion('a = ?', 6)]}

          test.equal c.sql(), '(x = ?) OR (y = ?) OR (a = ?)'
          test.equal c.sql(escape), '("x" = ?) OR ("y" = ?) OR (a = ?)'
          test.deepEqual c.params(), [7, 'foo', 6]

          test.done()

        '$not': (test) ->
          c = criterion {$not: {x: {$gt: 3}, y: {$gte: 4}}}

          test.equal c.sql(), 'NOT ((x > ?) AND (y >= ?))'
          test.equal c.sql(escape), 'NOT (("x" > ?) AND ("y" >= ?))'
          test.deepEqual c.params(), [3, 4]

          test.done()

        '$or inside AND is wrapped in parentheses': (test) ->
          c = criterion
            username: "user"
            password: "hash"
            $or: [{active: 1}, active: {$null: true}]

          test.equal c.sql(), '(username = ?) AND (password = ?) AND ((active = ?) OR (active IS NULL))'
          test.equal c.sql(escape), '("username" = ?) AND ("password" = ?) AND (("active" = ?) OR ("active" IS NULL))'
          test.deepEqual c.params(), ["user", "hash", 1]

          test.done()

        '$or, AND and $not can be deeply nested': (test) ->
          c = criterion {
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

          test.equal c.sql(), '(alpha = ?) OR ((charlie != ?) AND (NOT (((delta = ?) OR (delta IS NULL)) AND (echo = ?)))) OR (((echo < ?) AND ((golf = ?) OR (NOT (lima != ?)))) OR (foxtrot = ?)) OR (NOT ((alpha = ?) OR (NOT (echo < ?)) OR (alpha < ?) OR (bravo = ?) OR ((alpha = ?) AND (bravo = ?)))) OR (bravo = ?)'
          test.equal c.sql(escape), '("alpha" = ?) OR (("charlie" != ?) AND (NOT ((("delta" = ?) OR ("delta" IS NULL)) AND ("echo" = ?)))) OR ((("echo" < ?) AND (("golf" = ?) OR (NOT ("lima" != ?)))) OR ("foxtrot" = ?)) OR (NOT ((alpha = ?) OR (NOT ("echo" < ?)) OR ("alpha" < ?) OR ("bravo" = ?) OR (("alpha" = ?) AND ("bravo" = ?)))) OR ("bravo" = ?)'
          test.deepEqual c.params(), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

          test.done()

      'subqueries':

        'IN and $nin': (test) ->
          subquery =
            sql: (escape) ->
              "SELECT #{escape 'id'} FROM \"user\" WHERE #{escape 'is_active'}"

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

        '$exists without params': (test) ->
          subquery =
            sql: (escape) ->
              "SELECT * FROM \"user\" WHERE #{escape 'is_active'}"
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

        test.equal c.sql(), 'x = (crypt(?, gen_salt(?, ?)))'
        test.equal c.sql(escape), '"x" = (crypt(?, gen_salt(?, ?)))'
        test.deepEqual c.params(), ['password', 'bf', 4]

        test.done()

      '$ne with criterion argument': (test) ->
        c = criterion {x: {$ne: criterion('crypt(?, gen_salt(?, ?))', 'password', 'bf', 4)}}

        test.equal c.sql(), 'x != (crypt(?, gen_salt(?, ?)))'
        test.equal c.sql(escape), '"x" != (crypt(?, gen_salt(?, ?)))'
        test.deepEqual c.params(), ['password', 'bf', 4]

        test.done()

      '$lt with criterion argument': (test) ->
        c = criterion {x: {$lt: criterion('NOW()')}}

        test.equal c.sql(), 'x < (NOW())'
        test.equal c.sql(escape), '"x" < (NOW())'
        test.deepEqual c.params(), []

        test.done()

  'manipulating criteria':

    'and': (test) ->
      fst = criterion {x: 7, y: 'foo'}
      snd = criterion 'z = ?', true

      fstAndSnd = fst.and snd

      test.equal fstAndSnd.sql(), '((x = ?) AND (y = ?)) AND (z = ?)'
      test.deepEqual fstAndSnd.params(), [7, 'foo', true]

      test.done()

    'or': (test) ->
      fst = criterion {x: 7, y: 'foo'}
      snd = criterion 'z = ?', true

      sndOrFst = snd.or fst

      test.equal sndOrFst.sql(), '(z = ?) OR ((x = ?) AND (y = ?))'
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

  'error conditions':

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
        test.equal e.message, '$in key with empty array value'
        test.done()

    '$nin with empty array': (test) ->
      try
        criterion {x: {$nin: []}}
      catch e
        test.equal e.message, '$nin key with empty array value'
        test.done()

    '$any with array': (test) ->
      try
        criterion {x: {$any: [1]}}
      catch e
        test.equal e.message, "$any key doesn't support array value. only $in and $nin do!"
        test.done()

    '$any with number': (test) ->
      try
        criterion {x: {$any: 6}}
      catch e
        test.equal e.message, '$any key requires value that implements sql-fragment interface'
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
        test.equal e.message, '$exists key requires value that implements sql-fragment interface'
        test.done()

    '$in without array or sql-fragment': (test) ->
      try
        criterion({x: {$in: 6}})
      catch e
        test.equal e.message, '$in key requires value that is an array or implements sql-fragment interface'
        test.done()

    '$nin without array or sql-fragment': (test) ->
      try
        criterion({x: {$nin: 6}})
      catch e
        test.equal e.message, '$nin key requires value that is an array or implements sql-fragment interface'
        test.done()
