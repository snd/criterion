# criterion

[![Build Status](https://travis-ci.org/snd/criterion.png)](https://travis-ci.org/snd/criterion)

criterion can describe sql where-conditions as objects for nodejs

inspired by the [mongo query language](http://www.mongodb.org/display/DOCS/Advanced+Queries)

### install

    npm install criterion

### use

##### require

```coffeescript
criterion = require 'criterion'
```

##### create from string and parameters

```coffeescript
c = criterion 'x = ?', 6

c.sql()     # 'x = ?'
c.params()  # [6]
```

##### create from object

```coffeescript
c = criterion {x: 7}

c.sql()     # 'x = ?'
c.params()  # [7]
```

##### `and` and `or`

```coffeescript
fst = criterion {x: 7, y: 'foo'}
snd = criterion 'z = ?', true

fst.and(snd).sql()      # '(x = ?) AND (y = ?) AND (z = ?)'
fst.and(snd).params()   # [7, 'foo', true]

snd.or(fst).sql()       # '(z = ?) OR (x = ? AND y = ?)'
snd.or(fst).params()    # [true, 7, 'foo']
```

##### `not`

```coffeescript
c = criterion {x: 7, y: 'foo'}

c.not().sql()           # 'NOT ((x = ?) AND (y = ?))'
c.not().params()        # [7, 'foo', true]

c.not().not().sql()     # '(x = ?) AND (y = ?)'
c.not().not().params()  # [7, 'foo', true]
```

criteria are immutable: `and`, `or` and `not` return new objects.

### possible function arguments to `criterion`

##### find where `x = 7` and `y = 'foo'`

```coffeescript
{x: 7, y: 'foo'}
# or
[{x: 7}, {y: 'foo'}]
# or
'x = ? AND y = ?', 7, 'foo'
```

##### find where `x` is in `[1, 2, 3]`

```coffeescript
{x: [1, 2, 3]}
```

##### find where `x` is not in `[1, 2, 3]`

```coffeescript
{x: {$nin: [1, 2, 3]}}
```

##### find where `x != 3`

```coffeescript
{x: {$ne: 3}}
# or
'x != ?', 3
```

##### find where `x < 3` and `y <= 4`

```coffeescript
{x: {$lt: 3}, y: {$lte: 4}}
# or
'x < ? AND y <= ?', 3, 4
```

##### find where `x > 3` and `y >= 4`

```coffeescript
{x: {$gt: 3}, y: {$gte: 4}}
# or
'x > ? AND y >= ?', 3, 4
```

##### find where not (`x > 3` and `y >= 4`)

```coffeescript
{$not: {x: {$gt: 3}, y: {$gte: 4}}}
# or
'NOT (x > ? AND y >= ?)', 3, 4
```

##### find where `x < NOW()`

```coffeescript
'x < NOW()'
```

##### find where `x` is between `5` and `10`

```coffeescript
'x BETWEEN ? AND ?', 5, 10
```

##### find where `x = 7` or `y = 6`

```coffeescript
{$or: [{x: 7}, {y: 6}]}
# or
{$or: {x: 7, y: 6}}
# or
'x = ? OR y = ?', 7, 6
```

##### find where `x` is `null`

```coffeescript
{x: {$null: true}}
# or
'x IS NULL'
```

##### find where `x` is not `null`

```coffeescript
{x: {$null: false}}
# or
'x IS NOT NULL'
```

all query parts can be composed at will!

### license: MIT
