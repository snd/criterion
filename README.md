# Query language

### Install

    npm install query-language

### Usage

make query from object

```coffeescript
query = new Query {x: 7, y: 'foo'}

query.sql()
# => 'x = ? AND y = ?'

query.params()
# => x = [7, 'foo']
```

make query from string

```coffeescript
query = new Query 'x = ? AND y = ?', 6, 'bar'

query.sql()
# => 'x = ? AND y = ?'
query.params()
# => x = [6, 'bar']
```

combine queries

```coffeescript
query1 = new Query {x: 7, y: 'foo'}
query2 = new Query 'z = ?', true

query1.and(query2).sql()
# => 'x = ? AND y = ? AND z = ?'
query1.and(query2).params()
# => [7, 'foo', true]

query2.or(query1).sql()
# => '(z = ?) OR (x = ? AND y = ?)'
query2.or(query1).params()
# => [true, 7, 'foo']
```

### Possible arguments to `new Query`

find where `x = 7` and `y = 'foo'`

```coffeescript
{x: 7, y: 'foo'}
# or
'x = ? AND y = ?', 7, 'foo'
```

find where `x` is in `[1, 2, 3]`

```coffeescript
{x: [1, 2, 3]}
```

find where `x` is not in `[1, 2, 3]`

```coffeescript
{x: {$nin: [1, 2, 3]}}
```

find where `x != 3`

```coffeescript
{x: {$ne: 3}}
# or
'x != ?', 3
```

find where `x < 3` and `y <= 4`

```coffeescript
{x: {$lt: 3}, y: {$lte: 4}}
# or
```

find where `x > 3` and `y >= 4`

```coffeescript
{x: {$gt: 3}, y: {$gte: 4}}
```

find where not (`x > 3` and `y >= 4`)

```coffeescript
{$not: {x: {$gt: 3}, y: {$gte: 4}}}
```

find where `x < NOW()`

```coffeescript
{x: {$lt: {$sql: 'NOW()'}}}
```

find where `x < 7` or `y < 7`

```coffeescript
{$or: [{x: {$lt: 7}}, {y: {$lt: 7}}]}
```

find where not (`x < 7` or `y < 7`)

```coffeescript
{$nor: [{x: {$lt: 7}}, {y: {$lt: 7}}]}
```

find where `x < 7` and `x > 10`

```coffeescript
{$and: [{x: {$lt: 7}}, {x: {$gt: 10}}]}
```

find where not (`x < 7` and `x > 10`)

```coffeescript
{$nand: [{x: {$lt: 7}}, {x: {$gt: 10}}]}
```

find where `x` is `null`

```coffeescript
{$null: x}
```

find where `x` is not `null`

```coffeescript
{$notnull: x}
```

The query language is designed to be intuitive and consistent.
You should be able to infer all possible combinations.

### License: MIT
