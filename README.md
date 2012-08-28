# Query language

### Install

    npm install query-language

### Usage

make query from string

```coffeescript
query = new Query 'x = ? AND y = ?', 6, 'bar'
query.sql() # => 'x = ? AND y = ?'
query.params() # => x = [6, 'bar']
```

make query from object

```coffeescript
query = new Query {x: 7, y = 'foo'}
query.sql() # => 'x = ? AND y = ?'
query.params() # => x = [7, 'foo']
```

combine queries

```
query1 = 
query2 =

query1.and(query2).sql() # => 
query2.or(query1).sql() # => 
query.and

combinedQuery = query.and query2

query.or query2

query.getSQL()
```

### Possible arguments to `new Query`

find where `x = 7` and `y = 'foo'`

```coffeescript
'x = ? AND y = ?', 7, 'foo'
```

find where `x = 7` and `y = 'foo'`

```coffeescript
{x: 7, y: 'foo'}
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
```

find where `x < 3` and `y <= 4`

```coffeescript
{x: {$lt: 3}, y: {$lte: 4}}
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

TODO complex query

The query language is designed to be intuitive and consistent.
You should be able to infer all possible combinations.

### License: MIT
