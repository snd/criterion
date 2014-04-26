# criterion

[![Build Status](https://travis-ci.org/snd/criterion.png)](https://travis-ci.org/snd/criterion)

criterion describes sql-where-conditions as objects which can be combined
and manipulated.

criterion is inspired by the
[mongodb query language](http://www.mongodb.org/display/DOCS/Advanced+Queries)

- [mesa, mohair and criterion](#mesa-mohair-and-criterion)
- [install](#install)
- [basic usage](#basic usage)
- [usage examples](#examples)
  - [equal](#equal-find-where-x-7)
  - [not equal](#not-equal-find-where-x-7)
  - [and](#and-find-where-x-7-and-y-a)
  - [or](#or-find-where-x-7-or-y-6)
  - [lower than](#lower-than-find-where-x-3-and-y-4)
  - [greater than](#greater-than-find-where-x-3-and-y-4)
  - [between](#between-find-where-x-is-between-5-and-10)
  - [not](#not-find-where-not-x-3-and-y-4)
  - [sql function](#sql-function-where-where-x-log-y-4)
  - [in](#in-find-where-x-is-in-1-2-3)
  - [not in](#not-in-find-where-x-is-in-1-2-3)
  - [null](#null-find-where-x-is-null)
  - [not null](#not-null-find-where-x-is-not-null)
- [combining criteria](#combining-criteria)
  - [and](#and)
  - [or](#or)
  - [not](#not)
- [license](#license-mit)

### [mesa](http://github.com/snd/mesa), [mohair](http://github.com/snd/mohair) and [criterion](http://github.com/snd/criterion)

**criterion is part of a set of three libraries whose goal is to make sql with nodejs simple and elegant:**

[criterion](http://github.com/snd/criterion) describes sql-where-conditions as objects which can be combined
and manipulated.

[mohair](http://github.com/snd/mohair) is a simple and flexible sql builder with a fluent interface.
*mohair uses criterion.*

[mesa](http://github.com/snd/mesa) is not an orm. it aims to help as much as possible with the construction, composition and execution of sql queries while not restricting full access to the underlying database driver and database in any way.
*mesa uses mohair.*

the arguments to mohairs and mesas `where()` method are **exactly** the same as the arguments to the function exported by criterion.

mesa supports all methods supported by mohair with some additions.
look into mohairs documentation to get the full picture of what's possible with mesa.

### install

```
npm install criterion
```

**or**

put this line in the dependencies section of your `package.json`:

```
"criterion": "0.3.2"
```

and run:

```
npm install
```

### basic usage

```javascript
var criterion = require('criterion');
```
criterion exports a single function.
that function can be called with a **query object** as an argument.
a query object describes an sql-where-condition.
[see the usage examples](#usage-examples) below for examples of the possible query objects:

```javascript
var c = criterion({x: 7, y: 8});
```

sql and a list of parameter bindings can be generated
from the object returned by criterion:

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

if a param is an array the corresponding binding `?` is exploded into a list of `?`:

```javascript
var d = criterion('x = ? AND y IN (?)', 7, [8, 9, 10]);

d.sql();        // => 'x = ? AND y IN (?, ?, ?)'
d.params();     // => [7, 8, 9, 10]

var e = criterion('x = ? AND (y && ARRAY[?])', 7, [8, 9, 10]);

e.sql();        // => 'x = ? AND (y && ARRAY[?, ?, ?])'
e.params();     // => [7, 8, 9, 10]
```

**any** criterion and **any** other object that responds to a `sql()` and optionally a `params()` method can
be used in place of **any** value in a query object.
this allows you to mix query objects with arbitrary sql:

```javascript
var c = criterion({x: {$ne: criterion('LOG(y, ?)', 4)}});
c.sql();        // => 'x != LOG(y, ?)'
c.params();     // => [4]
```

### usage examples

#### equal: find where `x = 7`

```javascript
var c = criterion({x: 7});
c.sql();        // => 'x = ?'
c.params();     // => [7]
```
or
```javascript
var c = criterion('x = ?', 7);
```

#### not equal: find where `x != 3`

```javascript
var c = criterion({x: {$ne: 3}});
c.sql();        // => 'x != ?'
c.params();     // => [3]
```
or
```javascript
var c = criterion('x != ?', 3);
```

#### and: find where `x = 7` and `y = 'a'`

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

#### or: find where `x = 7` or `y = 6`

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


#### lower than: find where `x < 3` and `y <= 4`

```javascript
var c = criterion({x: {$lt: 3}, y: {$lte: 4}});
c.sql();        // => 'x < ? AND y <= ?'
c.params();     // => [3, 4]
```
or
```javascript
var c = criterion('x < ? AND y <= ?', 3, 4);
```

#### greater than: find where `x > 3` and `y >= 4`

```javascript
var c = criterion({x: {$gt: 3}, y: {$gte: 4}});
c.sql();        // => 'x > ? AND y >= ?'
c.params();     // => [3, 4]
```
or
```javascript
var c = criterion('x > ? AND y >= ?', 3, 4);
```

#### between: find where `x` is between `5` and `10`

```javascript
var c = criterion('x BETWEEN ? AND ?', 5, 10);
c.sql();        // => 'x BETWEEN ? AND ?'
c.params();     // => [5, 10]
```

#### not: find where not (`x > 3` and `y >= 4`)

```javascript
var c = criterion({$not: {x: {$gt: 3}, y: {$gte: 4}}});
c.sql();        // => 'NOT (x > ? AND y >= ?)'
c.params();     // => [3, 4]
```
or
```javascript
var c = criterion('NOT (x > ? AND y >= ?)', 3, 4);
```

#### sql function: find where `x != LOG(y, 4)`

```javascript
var c = criterion({x: {$ne: criterion('LOG(y, ?)', 4)}});
c.sql();        // => 'x != LOG(y, ?)'
c.params();     // => [4]
```

#### in: find where `x` is in `[1, 2, 3]`

```javascript
var c = criterion({x: [1, 2, 3]});
c.sql();        // => 'x IN (?, ?, ?)'
c.params();     // => [1,2,3]
```
or
```javascript
var c = criterion('x IN (?)', [1, 2, 3]);
```

#### not in: find where `x` is not in `[1, 2, 3]`

```javascript
var c = criterion({x: {$nin: [1, 2, 3]}});
c.sql();        // => 'x NOT IN (?, ?, ?)'
c.params();     // => [1,2,3]
```
or
```javascript
var c = criterion('x NOT IN (?)', [1, 2, 3]);
```

#### null: find where `x` is `null`

```javascript
var c = criterion({x: {$null: true});
c.sql();        // => 'x IS NULL'
c.params();     // => []
```
or
```javascript
var c = criterion('x IS NULL');
```

#### not null: find where `x` is not `null`

```javascript
var c = criterion({x: {$null: false}});
c.sql();        // => 'x IS NOT NULL'
c.params();     // => []
```
or
```javascript
var c = criterion('x IS NOT NULL');
```

### combining criteria

`and()`, `or()` and `not()` return new objects.
no method ever changes the object it is called on.

#### and

```javascript
var fst = criterion({x: 7, y: 'a'});
var snd = criterion('z = ?', true);

fst.and(snd).sql();         // => '(x = ?) AND (y = ?) AND (z = ?)'
fst.and(snd).params();      // => [7, 'a', true]
```

#### or

```javascript
var fst = criterion({x: 7, y: 'a'});
var snd = criterion('z = ?', true);

snd.or(fst).sql();          // => '(z = ?) OR (x = ? AND y = ?)'
snd.or(fst).params();       // => [true, 7, 'a']
```

#### not

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

### [license: MIT](LICENSE)
