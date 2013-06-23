# criterion

[![Build Status](https://travis-ci.org/snd/criterion.png)](https://travis-ci.org/snd/criterion)

criterion describes sql-where-conditions as objects which can be combined
and manipulated.

criterion is inspired by the [mongo query language](http://www.mongodb.org/display/DOCS/Advanced+Queries)

[mohair](https://github.com/snd/mohair) uses criterion.
the arguments to mohairs `where()` method are **exactly** the same as the arguments to the function exported by criterion.
mohair is an sql builder which does a lot more than criterion: [go check it out.](https://github.com/snd/mohair)

### install

```
npm install criterion
```

### use

require:

```javascript
var criterion = require('criterion');
```

criterion exports a single function.
that function can be called with a **query object** as an argument.
a query object describes an sql-where-condition.
[see the examples](#examples) below for an idea of possible query objects.

```javascript
var c = criterion({x: 7, y: 8});
```

sql and a list of parameter bindings can be generated from the object returned by criterion:

```javascript
c.sql();        // => 'x = ? AND y = ?'
c.params();     // => [7, 8]
```

alternatively criterion can be called with a string of **raw sql** and optional parameter bindings:

```javascript
var c = criterion('x = ? AND Y = ?', 7, 8);

c.sql();        // => 'x = ? AND y = ?'
c.params();     // => [7, 8]
```

any criterion and any other object that responds to a `sql()` and optionally a `params()` method can
be used in place of any value in a query object.
this allows you to mix query objects with arbitrary sql:

```javascript
var c = criterion({x: {$ne: criterion('LOG(y, ?)', 4)}});
c.sql();        // => 'x != LOG(y, ?)'
c.params();     // => [4]
```

criteria can be combined:

```javascript
var fst = criterion({x: 7, y: 'a'});
var snd = criterion('z = ?', true);

fst.and(snd).sql();         // => '(x = ?) AND (y = ?) AND (z = ?)'
fst.and(snd).params();      // => [7, 'a', true]

snd.or(fst).sql();          // => '(z = ?) OR (x = ? AND y = ?)'
snd.or(fst).params();       // => [true, 7, 'a']
```

criteria can be negated:

```javascript
var c = criterion({x: 7, y: 'a'});
c.not().sql();              // => 'NOT ((x = ?) AND (y = ?))'
c.not().params();           // => [7, 'a']
```

double negations are removed:

```javascript
var c = criterion({x: 7, y: 'a'});
c.not().not().sql();        // => '(x = ?) AND (y = ?)'
c.not().not().params();     // => [7, 'a']
```

`and()`, `or()` and `not()` return new objects.
no method ever changes the state of the object it is called on.
this enables a functional programming style.

### examples

##### logical

###### find where `x = 7` and `y = 'a'`

```javascript
var c = criterion({x: 7, y: 'a'});
c.sql();        // => 'x = ? AND y = ?'
c.params();     // => [7, 'a']
```
or
```javascript
var c = criterion([{x: 7}, {y: 'a'}]);
```
or
```javascript
var c = criterion('x = ? AND y = ?', 7, 'a');
```

###### find where `x = 7` or `y = 6`

```javascript
var c = criterion({$or: [{x: 7}, {y: 6}]});
c.sql();        // => 'x = ? OR y = ?'
c.params();     // => [7, 6]
```
or
```javascript
var c = criterion({$or: {x: 7, y: 6}});
```
or
```javascript
var c = criterion('x = ? OR y = ?', 7, 6);
```

##### comparison

###### find where `x != 3`

```javascript
var c = criterion({x: {$ne: 3}});
c.sql();        // => 'x != ?'
c.params();     // => [3]
```
or
```javascript
var c = criterion('x != ?', 3);
```

###### find where `x < 3` and `y <= 4`

```javascript
var c = criterion({x: {$lt: 3}, y: {$lte: 4}});
c.sql();        // => 'x < ? AND y <= ?'
c.params();     // => [3, 4]
```
or
```javascript
var c = criterion('x < ? AND y <= ?', 3, 4);
```

###### find where `x > 3` and `y >= 4`

```javascript
var c = criterion({x: {$gt: 3}, y: {$gte: 4}});
c.sql();        // => 'x > ? AND y >= ?'
c.params();     // => [3, 4]
```
or
```javascript
var c = criterion('x > ? AND y >= ?', 3, 4);
```

###### find where not (`x > 3` and `y >= 4`)

```javascript
var c = criterion({$not: {x: {$gt: 3}, y: {$gte: 4}}});
c.sql();        // => 'NOT (x > ? AND y >= ?)'
c.params();     // => [3, 4]
```
or
```javascript
var c = criterion('NOT (x > ? AND y >= ?)', 3, 4);
```

###### find where `x < NOW()`

```javascript
var c = criterion(x: {$lt: criterion('NOW()')});
c.sql();        // => 'x < NOW()'
c.params();     // => []
```

###### find where `x != LOG(y, 4)`

```javascript
var c = criterion({x: {$ne: criterion('LOG(y, ?)', 4)}});
c.sql();        // => 'x != LOG(y, ?)'
c.params();     // => [4]
```

###### find where `x` is between `5` and `10`

```javascript
var c = criterion('x BETWEEN ? AND ?', 5, 10);
c.sql();        // => 'x BETWEEN ? AND ?'
c.params();     // => [5, 10]
```

##### array

###### find where `x` is in `[1, 2, 3]`

```javascript
var c = criterion({x: [1, 2, 3]});
c.sql();        // => 'x IN (?, ?, ?)'
c.params();     // => [1,2,3]
```
or
```javascript
var c = criterion('x IN (?, ?, ?)', 1, 2, 3);
```

###### find where `x` is not in `[1, 2, 3]`

```javascript
var c = criterion({x: {$nin: [1, 2, 3]}});
c.sql();        // => 'x NOT IN (?, ?, ?)'
c.params();     // => [1,2,3]
```
or
```javascript
var c = criterion('x NOT IN (?, ?, ?)', 1, 2, 3);
```

##### null

###### find where `x` is `null`

```javascript
var c = criterion({x: {$null: true});
c.sql();        // => 'x IS NULL'
c.params();     // => []
```
or
```javascript
var c = criterion('x IS NULL');
```

###### find where `x` is not `null`

```javascript
var c = criterion({x: {$null: false}});
c.sql();        // => 'x IS NOT NULL'
c.params();     // => []
```
or
```javascript
var c = criterion('x IS NOT NULL');
```

### license: MIT
