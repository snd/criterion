# criterion

[![NPM version](https://badge.fury.io/js/criterion.svg)](http://badge.fury.io/js/criterion)
[![Build Status](https://travis-ci.org/snd/criterion.svg?branch=master)](https://travis-ci.org/snd/criterion/branches)
[![Dependencies](https://david-dm.org/snd/criterion.svg)](https://david-dm.org/snd/criterion)

> criterion is a very flexible, powerful, yet simple solution for describing
> and SQL-where-conditions as data (instead of strings) to make them easily
> can be manipulated and composed.

> criterion parses SQL-where-conditions from a mongodb-like query-language into
> composable objects it can compile to SQL

- [background](#background)
- [relevance for users of mesa and mohair](#relevance-for-users-of-mesa-and-mohair)
- [get started](#get-started)
- [reference by example](#reference-by-example)
  - [comparisons](#comparisons)
    - [equal](#equal)
    - [not equal](#not-equal)
    - [lower than](#lower-than)
    - [greater than](#greater-than)
    - [null](#null)
    - [not null](#not-null)
  - [boolean](#boolean)
    - [and](#and)
    - [or](#or)
    - [not](#not)
  - [sql-fragments](#sql-fragments)
    - [between](#between)
    - [sql function](#sql-function)
  - [nesting](#not)
  - [lists of scalar expressions](#lists-of-scalar-expressions)
    - [in list](#in-list)
    - [not in list](#not-in-list)
  - [subqueries](#subqueries)
    - [in subquery](#in-subquery)
    - [not in subquery](#not-in-subquery)
    - [exists - whether subquery returns any rows](#exists-whether-subquery-returns-any-rows)
  - [combining criteria with and](#combining-criteria-with-and)
  - [combining criteria with or](#combining-criteria-with-or)
  - [negating criteria with not](#negating-criteria-with-not)
  - [escaping column names](#escaping-column-names)
- [changelog](#changelog)
- [license: MIT](#license-mit)

## background

criterion is part of three libraries for nodejs that strive to

> make SQL with Nodejs [simple](http://www.infoq.com/presentations/Simple-Made-Easy), elegant, productive and FUN !

#### [CRITERION](http://github.com/snd/criterion)

parses SQL-where-conditions from a mongodb-like query-language into
objects which it can compile to SQL

#### [MOHAIR](http://github.com/snd/mohair)

a powerful SQL-query-builder with a fluent, functional, side-effect-free API.

uses [criterion](http://github.com/snd/criterion) to build and combine its SQL-where-clauses.

#### [MESA](http://github.com/snd/mesa)

helps as much as possible with the construction, composition and execution of SQL-queries while not restricting full access to the database in any way.

is not an ORM !

uses [mohair](http://github.com/snd/mohair) to build its SQL-queries.

uses [criterion](http://github.com/snd/criterion) (through [mohair](http://github.com/snd/mohair)) to build and combine its SQL-where-clauses.

## get started

### install

```
npm install criterion
```

### require

``` js
var criterion = require('criterion');
```

criterion exports a single `criterion()` function.

`criterion()` can be called with either a [query-object](#query-objects)
or an [sql-fragment](#sql-fragments):

### definition: condition object

a **condition-object** is

let's make a **condition-object**

``` js
var condition = {
  x: 7,
  y: 8
};
```

``` js
var c = criterion(condition);
```

the query language uses objects with special modifier keys to model conditions.

criterion is inspired by the
[mongodb query language](http://docs.mongodb.org/manual/tutorial/query-documents/)


a query-object describes an sql-where-condition.
[see the reference below for the possible query objects.](#reference)


### definition: raw sql

**raw-sql** is a string of raw sql followed by some optional parameter bindings.
for those rare cases where the query-object and you have to fall back to sql strings.

a criterion made from **raw-sql** behaves exactly like one made from
a **query-object**

in fact both are sql-fragments

### interface: sql fragments

every object that 

the sql function

**any** criterion and **any** other object that responds to a `sql()` and optionally a `params()` method can
be used in place of **any** value in a query object.
this allows you to mix query objects with arbitrary sql:


combining and nesting ...

query object:

if `criterion()` is called with an object

let's make a query:


sql and a list of parameter bindings can be generated
from the object returned by criterion:


you can even use a criterion build from a query-object as a fragment

``` js
c.sql();        // -> 'x = ? AND y = ?'
c.params();     // -> [7, 8]
```

alternatively criterion can be called with a string of **raw sql** and optional parameter bindings:

``` js
var c = criterion('x = ? AND Y = ?', 7, 8);

c.sql();        // -> 'x = ? AND y = ?'
c.params();     // -> [7, 8]
```

if a param is an array the corresponding binding `?` is exploded into a list of `?`:

``` js
var c = criterion('x = ? AND y IN (?)', 7, [8, 9, 10]);

c.sql();        // -> 'x = ? AND y IN (?, ?, ?)'
c.params();     // -> [7, 8, 9, 10]

var c = criterion('x = ? AND (y && ARRAY[?])', 7, [8, 9, 10]);

c.sql();        // -> 'x = ? AND (y && ARRAY[?, ?, ?])'
c.params();     // -> [7, 8, 9, 10]
```

``` js
var c = criterion({x: {$ne: criterion('LOG(y, ?)', 4)}});

c.sql();        // -> 'x != LOG(y, ?)'
c.params();     // -> [4]
```

## relevance for users of mesa and mohair

[EVERYTHING possible with criterion](http://github.com/snd/criterion#reference-by-example) is possible in
[mesa](http://github.com/snd/mesa)
and [mohair](http://github.com/snd/mohair) !

the [criterion reference](http://github.com/snd/criterion#reference-by-example) completes mesa's and mohair's documentation !

here's why:

the criterion module exports a single function: `var criterion = require('criterion')`

[mesa's](http://github.com/snd/mesa) and [mohair's](http://github.com/snd/mohair) fluent `.where()` methods
call `criterion()` under the hood and forward all their arguments **unmodifed** to `criterion()`.
this means that all arguments supported by `criterion()` are supported by `.where()` !

``` js
// same condition-object
var condition = {x: 7};

// criterion
var criterion = require('criterion');
var c = criterion(condition);
c.sql();    // -> 'x = ?'
c.params(); // -> [7]

// mohair
var mohair = require('mohair');
var query = mohair
  .table('post')
  .where(condition);
query.sql();    // -> 'SELECT * FROM post WHERE x = ?'
query.params(); // -> [7]
```

if `.where()` is called more than once the resulting criteria are [ANDed](#combining-criteria-with-and) together:

``` js
var mohair = require('mohair');

var postTable = mohair.table('post')
var queryAlpha = postTable.where({x: 7});
var queryBravo = queryAlpha.where('y IN (?)', [1, 2]);

postTable.sql();
// -> 'SELECT * FROM post'
postTable.params();
// -> []

queryAlpha.sql();
// -> 'SELECT * FROM post WHERE x = ?'
queryAlpha.params();
// -> [7]

queryBravo.sql();
// -> 'SELECT * FROM post WHERE x = ? AND y IN (?, ?)'
queryBravo.params();
// -> [7, 1, 2]
```

calling methods on does not but
refines

this is one of the nice properties of mohair and mesa.

#### IMPORTANT !

**
this is the readme for criterion@0.4.0.
criterion@0.4.0 is not yet used by the newest versions of mesa and mohair.
it will be used very very soon !
to see the readme for criterion@0.3.3 which is used by the newest mesa and mohair [click here](https://github.com/snd/criterion/tree/0808d66443fd72aaece2f3e5134f49d3af0bf72e) !
to see what has changed in 0.4.0 [click here](#changelog).
**


## reference by example

### equal

where `x = 7`

``` js
var c = criterion({x: 7});
c.sql();    // -> 'x = ?'
c.params(); // -> [7]
```

or

``` js
var c = criterion('x = ?', 7);
```

### not equal

where `x != 3`

``` js
var c = criterion({x: {$ne: 3}});
c.sql();    // -> 'x != ?'
c.params(); // -> [3]
```

or

``` js
var c = criterion('x != ?', 3);
```

### and

where `x = 7` and `y = 'a'`

``` js
var c = criterion({x: 7, y: 'a'});
c.sql();    // -> 'x = ? AND y = ?'
c.params(); // -> [7, 'a']
```

or

``` js
var c = criterion([{x: 7}, {y: 'a'}]);
```

or

``` js
var c = criterion({$and: {x: 7, y: 'a'}});
```

or

``` js
var c = criterion({$and: [{x: 7}, {y: 'a'}]});
```

or

``` js
var c = criterion('x = ? AND y = ?', 7, 'a');
```

### or

where `x = 7` or `y = 6`

``` js
var c = criterion({$or: {x: 7, y: 6}});
c.sql();    // -> 'x = ? OR y = ?'
c.params(); // -> [7, 6]
```

or

``` js
var c = criterion({$or: [{x: 7}, {y: 6}]});
```

or

``` js
var c = criterion('x = ? OR y = ?', 7, 6);
```

### not

where not (`x > 3` and `y >= 4`)

``` js
var c = criterion({$not: {x: {$gt: 3}, y: {$gte: 4}}});
c.sql();    // -> 'NOT (x > ? AND y >= ?)'
c.params(); // -> [3, 4]
```

or

``` js
var c = criterion('NOT (x > ? AND y >= ?)', 3, 4);
```


### nesting `$or`, `$and` and `$not`

`$or`, `$and` and `$not` can be nested arbitrarily deep.

where `(x > 10) AND (x < 20) AND (x != 17)

``` js
var subquery = mohair.table('post').where({title: 'criterion});

var c = criterion({
  $or: [{
    $and: [
      {x: {$gt: 10}},
      {x: {$lt: 20}},
      {x: {$ne: 17}}
      # TODO make sure that this works
      criterion('x BETWEEN ? AND ?', 5, 10)
      {$or: {
        exists: subquery
        x: {$nin: [1, 2, 3]}
      }
    ]

  },

c.sql();    // -> 'x NOT IN (?, ?, ?)'
c.params(); // -> [1,2,3]
```


### lower than

where `x < 3` and `y <= 4`

``` js
var c = criterion({x: {$lt: 3}, y: {$lte: 4}});
c.sql();    // -> 'x < ? AND y <= ?'
c.params(); // -> [3, 4]
```
or
``` js
var c = criterion('x < ? AND y <= ?', 3, 4);
```

### greater than

where `x > 3` and `y >= 4`

``` js
var c = criterion({x: {$gt: 3}, y: {$gte: 4}});
c.sql();    // -> 'x > ? AND y >= ?'
c.params(); // -> [3, 4]
```

or

``` js
var c = criterion('x > ? AND y >= ?', 3, 4);
```

### between

where `x` is between `5` and `10`

example of raw sql

``` js
var c = criterion('x BETWEEN ? AND ?', 5, 10);
c.sql();    // -> 'x BETWEEN ? AND ?'
c.params(); // -> [5, 10]
```

### sql function

where `x != LOG(y, 4)`

example of raw sql combined with

``` js
var c = criterion({x: {$ne: criterion('LOG(y, ?)', 4)}});
c.sql();    // -> 'x != (LOG(y, ?))'
c.params(); // -> [4]
```

### null

where `x` is `null`

``` js
var c = criterion({x: {$null: true});
c.sql();    // -> 'x IS NULL'
c.params(); // -> []
```

or

``` js
var c = criterion('x IS NULL');
```

### not null

where `x` is not `null`

``` js
var c = criterion({x: {$null: false}});
c.sql();        // -> 'x IS NOT NULL'
c.params();     // -> []
```

or

``` js
var c = criterion('x IS NOT NULL');
```

### in list of scalar expressions

where `x` is in `[1, 2, 3]`

``` js
var c = criterion({x: [1, 2, 3]});
c.sql();    // -> 'x IN (?, ?, ?)'
c.params(); // -> [1,2,3]
```

or

``` js
var c = criterion({x: {$in: [1, 2, 3]}});
```

or

``` js
var c = criterion('x IN (?)', [1, 2, 3]);
```

[see also the postgres documentation on row and array comparisons](http://www.postgresql.org/docs/9.3/static/functions-comparisons.html)

### not in list of scalar expressions

where `x` is not in `[1, 2, 3]`

``` js
var c = criterion({x: {$nin: [1, 2, 3]}});
c.sql();    // -> 'x NOT IN (?, ?, ?)'
c.params(); // -> [1,2,3]
```

or

``` js
var c = criterion('x NOT IN (?)', [1, 2, 3]);
```

[see also the postgres documentation on row and array comparisons](http://www.postgresql.org/docs/9.3/static/functions-comparisons.html)

### in subquery

where `x` is in subquery

``` js
var subquery = mohair
  .table('post')
  .where({is_published: true})
  .select('id');

var c = criterion({x: {$in: subquery}});

c.sql();    // -> 'x IN (SELECT id FROM post WHERE is_published = ?)'
c.params(); // -> [true]
```

`subquery` can be any [mohair](https://github.com/snd/mohair)-query-object,
[mesa](https://github.com/snd/mesa)-query-object and any other
object that has an `sql()` function!

[see also the postgres documentation on row and array comparisons](http://www.postgresql.org/docs/9.3/static/functions-comparisons.html)

### not in subquery

where `x` is in subquery

``` js
var subquery = mohair
  .table('post')
  .where({is_published: true})
  .select('id');

var c = criterion({x: {$nin: subquery}});

c.sql();    // -> 'x NOT IN (SELECT id FROM post WHERE is_published = ?)'
c.params(); // -> [true]
```

`subquery` can be any [mohair](https://github.com/snd/mohair)-query-object,
[mesa](https://github.com/snd/mesa)-query-object and any other
object that has an `sql()` function!

### subquery returns any rows

``` js
# TODO this isnt right
var subquery = mohair
  .table('post')
  .where({is_published: false})
  .where({user_id: mohair.raw('id')})

var c = criterion({$exists: subquery})

c.sql();    // -> 'EXISTS (SELECT * FROM post WHERE is_published = ?)'
c.params(); // -> [true]
```

`subquery` can be any [mohair](https://github.com/snd/mohair)-query-object,
[mesa](https://github.com/snd/mesa)-query-object and any other
object that has an `sql()` function!

[see also the postgres documentation on row and array comparisons](http://www.postgresql.org/docs/9.3/static/functions-comparisons.html)

### compare to any in subquery

``` js
var subquery = mohair
  .table('post')
  .select('id')
  .where({is_published: false})

var any = criterion({x: {$any: subquery}})

any.sql();    // -> 'x = ANY (SELECT * FROM post WHERE is_published = ?)'
any.params(); // -> [true]

var any = criterion({x: {$neAny: subquery}})

any.sql();    // -> 'x != ANY (SELECT * FROM post WHERE is_published = ?)'
any.params(); // -> [true]
```

`subquery` can be any [mohair](https://github.com/snd/mohair)-query-object,
[mesa](https://github.com/snd/mesa)-query-object and any other
object that has an `sql()` function!

[see also the postgres documentation on row and array comparisons](http://www.postgresql.org/docs/9.3/static/functions-comparisons.html)

### compare to all in subquery

### combining criteria with `and`

``` js
var alpha = criterion({x: 7, y: 'a'});
var bravo = criterion('z = ?', true);

alpha.and(bravo).sql();     // -> '(x = ?) AND (y = ?) AND (z = ?)'
alpha.and(bravo).params();  // -> [7, 'a', true]
```

`and()`, `or()` and `not()` return new objects.
no method ever changes the object it is called on.

### combining criteria with `or`

``` js
var alpha = criterion({x: 7, y: 'a'});
var bravo = criterion('z = ?', true);

bravo.or(alpha).sql();      // -> '(z = ?) OR (x = ? AND y = ?)'
bravo.or(alpha).params();   // -> [true, 7, 'a']
```

`and()`, `or()` and `not()` return new objects.
no method ever changes the object it is called on.

### negating criteria with `not`

``` js
var c = criterion({x: 7, y: 'a'});
c.not().sql();    // -> 'NOT ((x = ?) AND (y = ?))'
c.not().params(); // -> [7, 'a']
```

double negations are removed:

``` js
var c = criterion({x: 7, y: 'a'});
c.not().not().sql();    // -> '(x = ?) AND (y = ?)'
c.not().not().params(); // -> [7, 'a']
```

### escaping column names

you can pass a function into any `sql()` method to escape column names:

``` js
var c = criterion({x: 7, y: 8});

var escape = function(x) {
  return '"' + x + '"';
};
c.sql(escape);  // -> '"x" = ? AND "y" = ?' <- x and y are escaped !
c.params();     // -> [7, 8]
```

## changelog

### 0.4.0

- to escape column names in the resulting SQL an escape function can now be passed as an argument into any `sql()` method
- sql fragments are now always wrapped in parentheses before pasting them into a query.
  this doesn't break anything and makes subqueries work without further changes.
- added `$exists` which can be used with mesa/mohair queries (or any object that responds to an `sql()` method): `criterion({$exists: mohair.table('post').where({id: 7})})`
- `$in` and `$nin` now support not just lists of values but also subqueries: `criterion({id: {$in: mohair.table('post').where({is_active: true}).select('id')}})`
- added modifiers `$any`, `$neAny`, `$ltAny`, `$gtAny`, `$gteAny`, `$all`, `$neAll`, `$ltAll`, `$lteAll`, `$gtAll`, `$gteAll` to be used with subqueries: `criterion({created_at: {$gteAll: mohair.table('post').where({is_active: true}).select('updated_at')}})`
- sql fragments can now be used in more places...
  - where the value would normally go in a comparison: `{$lt: criterion('5 + 8')}`
    - this makes row-wise comparisons with subqueries possible
  - in the arrays passed to `$or` and `$and`: `{$or [{a: 7}, criterion('b < ?', 5)]}`
  - ...
- improved the code, the tests and the documentation

## [license: MIT](LICENSE)

## TODO

- keep `isSqlFragment` but rename sql fragments to rawSql
- sections in reference
  - boolean operators
- document query nesting
  - document that you can intersperse sql fragments in $or and $and
- "you can use sql-fragments pretty much anywhere"
- if some combination that you think should work doesnt work make an issue
- document row-wise comparison
  - document all places where subqueries can be used
- get the wording right everywhere
  - sql fragment or raw sql...
