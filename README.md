# criterion

[![NPM version](https://badge.fury.io/js/criterion.svg)](http://badge.fury.io/js/criterion)
[![Build Status](https://travis-ci.org/snd/criterion.svg?branch=master)](https://travis-ci.org/snd/criterion/branches)
[![Dependencies](https://david-dm.org/snd/criterion.svg)](https://david-dm.org/snd/criterion)

> criterion parses SQL-where-conditions from a mongodb-like query-language into
> composable objects which it can then compile to SQL

criterion is inspired by the
[mongodb query language](http://www.mongodb.org/display/DOCS/Advanced+Queries)

- [motivation](#motivation)
- [introduction](#introduction)
- [reference](#reference)
  - [equal](#equal-find-where-x--7)
  - [not equal](#not-equal-find-where-x--3)
  - [and](#and-find-where-x--7-and-y--a)
  - [or](#or-find-where-x--7-or-y--6)
  - [lower than](#lower-than-find-where-x--3-and-y--4)
  - [greater than](#greater-than-find-where-x--3-and-y--4)
  - [between](#between-find-where-x-is-between-5-and-10)
  - [not](#not-find-where-not-x--3-and-y--4)
  - [sql function](#sql-function-find-where-x--logy-4)
  - [in](#in-find-where-x-is-in-1-2-3)
  - [not in](#not-in-find-where-x-is-not-in-1-2-3)
  - [null](#null-find-where-x-is-null)
  - [not null](#not-null-find-where-x-is-not-null)
  - [combining criteria with and](#combining-criteria-with-and)
  - [combining criteria with or](#combining-criteria-with-or)
  - [negating criteria with not](#negating-criteria-with-not)
- [license: MIT](#license-mit)

## motivation

**criterion is part of a set of three libraries with the goal to make sql with nodejs simple, elegant and fun !**

[mohair](http://github.com/snd/mohair) uses criterion and is a simple and flexible sql builder with a fluent interface.

[mesa](http://github.com/snd/mesa) uses mohair. mesa is not an orm. it aims to help as much as possible with the construction, composition and execution of sql queries while not restricting full access to the underlying database driver and database in any way.

the arguments to mohairs and mesas `where()` method are **exactly** the same as the [arguments to the function exported by criterion](http://github.com/snd/criterion#usage-examples)

mesa supports all methods supported by mohair with some additions.
look into mohairs documentation to get the full picture of what's possible with mesa.

## introduction

install it:

```
npm install criterion
```

require it:

``` js
var criterion = require('criterion');
```

criterion exports a single function which is to
be called with a **query-object** as an argument.

a query-object describes an sql-where-condition.
[see the reference below for the possible query objects.](#reference)

let's make a query:

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
var c = criterion('x = ? AND y IN (?)', 7, [8, 9, 10]);

c.sql();        // => 'x = ? AND y IN (?, ?, ?)'
c.params();     // => [7, 8, 9, 10]

var c = criterion('x = ? AND (y && ARRAY[?])', 7, [8, 9, 10]);

c.sql();        // => 'x = ? AND (y && ARRAY[?, ?, ?])'
c.params();     // => [7, 8, 9, 10]
```

**any** criterion and **any** other object that responds to a `sql()` and optionally a `params()` method can
be used in place of **any** value in a query object.
this allows you to mix query objects with arbitrary sql:

```javascript
var c = criterion({x: {$ne: criterion('LOG(y, ?)', 4)}});

c.sql();        // => 'x != LOG(y, ?)'
c.params();     // => [4]
```

## reference

### equal: find where `x = 7`

```javascript
var c = criterion({x: 7});
c.sql();    // => 'x = ?'
c.params(); // => [7]
```
or
```javascript
var c = criterion('x = ?', 7);
```

### not equal: find where `x != 3`

```javascript
var c = criterion({x: {$ne: 3}});
c.sql();    // => 'x != ?'
c.params(); // => [3]
```
or
```javascript
var c = criterion('x != ?', 3);
```

### and: find where `x = 7` and `y = 'a'`

```javascript
var c = criterion({x: 7, y: 'a'});
c.sql();    // => 'x = ? AND y = ?'
c.params(); // => [7, 'a']
```
or
```javascript
var c = criterion([{x: 7}, {y: 'a'}]);
```
or
```javascript
var c = criterion('x = ? AND y = ?', 7, 'a');
```

### or: find where `x = 7` or `y = 6`

```javascript
var c = criterion({$or: {x: 7, y: 6}});
c.sql();    // => 'x = ? OR y = ?'
c.params(); // => [7, 6]
```
or
```javascript
var c = criterion({$or: [{x: 7}, {y: 6}]});
```
or
```javascript
var c = criterion('x = ? OR y = ?', 7, 6);
```


### lower than: find where `x < 3` and `y <= 4`

```javascript
var c = criterion({x: {$lt: 3}, y: {$lte: 4}});
c.sql();    // => 'x < ? AND y <= ?'
c.params(); // => [3, 4]
```
or
```javascript
var c = criterion('x < ? AND y <= ?', 3, 4);
```

### greater than: find where `x > 3` and `y >= 4`

```javascript
var c = criterion({x: {$gt: 3}, y: {$gte: 4}});
c.sql();    // => 'x > ? AND y >= ?'
c.params(); // => [3, 4]
```
or
```javascript
var c = criterion('x > ? AND y >= ?', 3, 4);
```

### between: find where `x` is between `5` and `10`

```javascript
var c = criterion('x BETWEEN ? AND ?', 5, 10);
c.sql();    // => 'x BETWEEN ? AND ?'
c.params(); // => [5, 10]
```

### not: find where not (`x > 3` and `y >= 4`)

```javascript
var c = criterion({$not: {x: {$gt: 3}, y: {$gte: 4}}});
c.sql();    // => 'NOT (x > ? AND y >= ?)'
c.params(); // => [3, 4]
```
or
```javascript
var c = criterion('NOT (x > ? AND y >= ?)', 3, 4);
```

### sql function: find where `x != LOG(y, 4)`

```javascript
var c = criterion({x: {$ne: criterion('LOG(y, ?)', 4)}});
c.sql();    // => 'x != LOG(y, ?)'
c.params(); // => [4]
```

### in: find where `x` is in `[1, 2, 3]`

```javascript
var c = criterion({x: [1, 2, 3]});
c.sql();    // => 'x IN (?, ?, ?)'
c.params(); // => [1,2,3]
```
or
```javascript
var c = criterion('x IN (?)', [1, 2, 3]);
```

### not in: find where `x` is not in `[1, 2, 3]`

```javascript
var c = criterion({x: {$nin: [1, 2, 3]}});
c.sql();    // => 'x NOT IN (?, ?, ?)'
c.params(); // => [1,2,3]
```
or
```javascript
var c = criterion('x NOT IN (?)', [1, 2, 3]);
```

### null: find where `x` is `null`

```javascript
var c = criterion({x: {$null: true});
c.sql();    // => 'x IS NULL'
c.params(); // => []
```
or
```javascript
var c = criterion('x IS NULL');
```

### not null: find where `x` is not `null`

```javascript
var c = criterion({x: {$null: false}});
c.sql();        // => 'x IS NOT NULL'
c.params();     // => []
```
or
```javascript
var c = criterion('x IS NOT NULL');
```

### combining criteria with `and`

```javascript
var alpha = criterion({x: 7, y: 'a'});
var bravo = criterion('z = ?', true);

alpha.and(bravo).sql();     // => '(x = ?) AND (y = ?) AND (z = ?)'
alpha.and(bravo).params();  // => [7, 'a', true]
```

`and()`, `or()` and `not()` return new objects.
no method ever changes the object it is called on.

### combining criteria with `or`

```javascript
var alpha = criterion({x: 7, y: 'a'});
var bravo = criterion('z = ?', true);

bravo.or(alpha).sql();      // => '(z = ?) OR (x = ? AND y = ?)'
bravo.or(alpha).params();   // => [true, 7, 'a']
```

`and()`, `or()` and `not()` return new objects.
no method ever changes the object it is called on.

### negating criteria with `not`

```javascript
var c = criterion({x: 7, y: 'a'});
c.not().sql();    // => 'NOT ((x = ?) AND (y = ?))'
c.not().params(); // => [7, 'a']
```

double negations are removed:

```javascript
var c = criterion({x: 7, y: 'a'});
c.not().not().sql();    // => '(x = ?) AND (y = ?)'
c.not().not().params(); // => [7, 'a']
```

### [license: MIT](LICENSE)
