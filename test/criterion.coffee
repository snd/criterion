criterion = require '../src/factory'

module.exports =

    'create from string and parameters': (test) ->
        c = criterion 'x = ? AND y = ?', 6, 'bar'

        test.equal c.sql(), 'x = ? AND y = ?'
        test.deepEqual c.params(), [6, 'bar']

        test.done()

    'create from object': (test) ->
        c = criterion {x: 7}

        test.equal c.sql(), 'x = ?'
        test.deepEqual c.params(), [7]

        test.done()

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

    'throw on':

        'not string or object': (test) ->
            test.throws -> criterion 6

            test.done()

        'empty object': (test) ->
            test.throws -> criterion {}

            test.done()

        'null value with modifier': (test) ->
            test.throws -> criterion {x: {$lt: null}}

            test.done()

        'null value without modifier': (test) ->
            test.throws -> criterion {x: null}

            test.done()

        'in with empty array': (test) ->
            test.throws -> criterion {x: []}

            test.done()

        '$nin with empty array': (test) ->
            test.throws -> criterion {x: {$nin: []}}

            test.done()

    'queries':

        'and with object': (test) ->
            c = criterion {x: 7, y: 'foo'}

            test.equal c.sql(), '(x = ?) AND (y = ?)'
            test.deepEqual c.params(), [7, 'foo']

            test.done()

        'and with array': (test) ->
            c = criterion [{x: 7}, {y: 'foo'}]

            test.equal c.sql(), '(x = ?) AND (y = ?)'
            test.deepEqual c.params(), [7, 'foo']

            test.done()

        'in': (test) ->
            c = criterion {x: [1, 2, 3]}

            test.equal c.sql(), 'x IN (?, ?, ?)'
            test.deepEqual c.params(), [1, 2, 3]

            test.done()

        '$nin': (test) ->
            c = criterion {x: {$nin: [1, 2, 3]}}

            test.equal c.sql(), 'x NOT IN (?, ?, ?)'
            test.deepEqual c.params(), [1, 2, 3]

            test.done()

        '$ne': (test) ->
            c = criterion {x: {$ne: 3}}

            test.equal c.sql(), 'x != ?'
            test.deepEqual c.params(), [3]

            test.done()

        'equality with criterion argument': (test) ->
            c = criterion {x: criterion('crypt(?, gen_salt(?, ?))', 'password', 'bf', 4)}

            test.equal c.sql(), 'x = crypt(?, gen_salt(?, ?))'
            test.deepEqual c.params(), ['password', 'bf', 4]

            test.done()

        '$ne with criterion argument': (test) ->
            c = criterion {x: {$ne: criterion('crypt(?, gen_salt(?, ?))', 'password', 'bf', 4)}}

            test.equal c.sql(), 'x != crypt(?, gen_salt(?, ?))'
            test.deepEqual c.params(), ['password', 'bf', 4]

            test.done()

        '$lt and $lte': (test) ->
            c = criterion {x: {$lt: 3}, y: {$lte: 4}}

            test.equal c.sql(), '(x < ?) AND (y <= ?)'
            test.deepEqual c.params(), [3, 4]

            test.done()

        '$lt with criterion argument': (test) ->
            c = criterion {x: {$lt: criterion('NOW()')}}

            test.equal c.sql(), 'x < NOW()'
            test.deepEqual c.params(), []

            test.done()

        '$gt and $gte': (test) ->
            c = criterion {x: {$gt: 3}, y: {$gte: 4}}

            test.equal c.sql(), '(x > ?) AND (y >= ?)'
            test.deepEqual c.params(), [3, 4]

            test.done()

        '$not': (test) ->
            c = criterion {$not: {x: {$gt: 3}, y: {$gte: 4}}}

            test.equal c.sql(), 'NOT ((x > ?) AND (y >= ?))'
            test.deepEqual c.params(), [3, 4]

            test.done()

        '$or with object': (test) ->
            c = criterion {$or: {x: 7, y: 'foo'}}

            test.equal c.sql(), '(x = ?) OR (y = ?)'
            test.deepEqual c.params(), [7, 'foo']

            test.done()

        '$or with array': (test) ->
            c = criterion {$or: [{x: 7}, {y: 'foo'}]}

            test.equal c.sql(), '(x = ?) OR (y = ?)'
            test.deepEqual c.params(), [7, 'foo']

            test.done()

        '$null: true': (test) ->
            c = criterion {x: {$null: true}}

            test.equal c.sql(), 'x IS NULL'
            test.deepEqual c.params(), []

            test.done()

        '$null: false': (test) ->
            c = criterion {x: {$null: false}}

            test.equal c.sql(), 'x IS NOT NULL'
            test.deepEqual c.params(), []

            test.done()

        '$or inside $and is wrapped in parentheses': (test) ->
            c = criterion {
                username: "user"
                password: "hash"
                $or: [{active: 1}, active: {$null: true}]
            }

            test.equal c.sql(), '(username = ?) AND (password = ?) AND ((active = ?) OR (active IS NULL))'
            test.deepEqual c.params(), ["user", "hash", 1]

            test.done()
