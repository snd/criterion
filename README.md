# criterion

describe sql where-criteria similar to the [mongo query language](http://www.mongodb.org/display/DOCS/Advanced+Queries)

### install

    npm install criterion

### use

##### require it

```coffeescript
criterion = require 'criterion'
```

##### make from object

```coffeescript
c = criterion {x: 7, y: 'foo'}

c.sql()     # 'x = ? AND y = ?'
c.params()  # [7, 'foo']
```

criteria are immutable

##### make from string and parameters

```coffeescript
c = criterion 'x = ? AND y = ?', 6, 'bar'

c.sql()     # 'x = ? AND y = ?'
c.params()  # [6, 'bar']
```

##### combine

```coffeescript
fst = criterion {x: 7, y: 'foo'}
snd = criterion 'z = ?', true

fst.and(snd).sql()      # 'x = ? AND y = ? AND z = ?'
fst.and(snd).params()   # [7, 'foo', true]

fst.or(snd).sql()       # '(z = ?) OR (x = ? AND y = ?)'
fst.or(snd).params()    # [true, 7, 'foo']
```

##### negate

```coffeescript
c = criterion {x: 7, y: 'foo'}

c.negate().sql()    # 'NOT (x = ? AND y = ?)'
c.negate().params() # [7, 'foo', true]
```

### Possible arguments to `criterion`

##### find where `x = 7` and `y = 'foo'`

```coffeescript
{x: 7, y: 'foo'}
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
{x: {$lt: {$sql: 'NOW()'}}}
#or
'x < NOW()'
```

##### find where `x < 7` or `y < 7`

```coffeescript
{$or: [{x: {$lt: 7}}, {y: {$lt: 7}}]}
# or
'x < ? OR y < ?', 7, 7
```

##### find where not (`x < 7` or `y < 7`)

```coffeescript
{$nor: [{x: {$lt: 7}}, {y: {$lt: 7}}]}
# or
'NOT (x < ? OR y < ?)', 7, 7
```

##### find where `x < 7` and `x > 10`

```coffeescript
{$and: [{x: {$lt: 7}}, {x: {$gt: 10}}]}
# or
'x < ? AND x > ?', 7, 10
```

##### find where not (`x < 7` and `x > 10`)

```coffeescript
{$nand: [{x: {$lt: 7}}, {x: {$gt: 10}}]}
# or
'NOT (x < ? AND x > ?)', 7, 10
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

combine the above at your own will!
it should work. if it doesn't file an issue.

### license: MIT
