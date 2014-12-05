# criterion

[![NPM version](https://badge.fury.io/js/criterion.svg)](http://badge.fury.io/js/criterion)
[![Build Status](https://travis-ci.org/snd/criterion.svg?branch=master)](https://travis-ci.org/snd/criterion/branches)
[![Dependencies](https://david-dm.org/snd/criterion.svg)](https://david-dm.org/snd/criterion)

> criterion lifts SQL-where-conditions from strings into the realm of data:
data has the advantage to be programmatically accessible and formable than strings.
is a highly flexible and powerful, yet simple solution for modelling
easily build up and manipulated with code.
> be easily
> can be manipulated and composed.
> always drop down to raw-sql.
> SQL-where-conditions as data instead of strings.

> criterion parses SQL-where-conditions from a mongodb-like query-language into
> composable objects it can compile to SQL

#### WARNING !

**
this is the readme for criterion@0.4.0.
criterion@0.4.0 is not yet used by the newest versions of mesa and mohair.
it will be used very very soon !
to see the readme for criterion@0.3.3 which is used by the newest mesa and mohair [click here](https://github.com/snd/criterion/tree/0808d66443fd72aaece2f3e5134f49d3af0bf72e) !
to see what has changed in 0.4.0 [click here](#changelog).
**

- [background](#background)
- [get started](#get-started)
  - [install](#install)
  - [require](#require)
  - [condition-objects](#condition-objects)
  - [raw-sql](#raw-sql)
  - [the sql-fragment interface](#the-sql-fragment-interface)
- [for users of mesa and mohair](#for-users-of-mesa-and-mohair)
- [condition-object reference by example](#condition-object-reference-by-example)
  - [comparisons](#comparisons)
    - [equal](#equal)
    - [not equal](#not-equal)
    - [lower than](#lower-than)
    - [greater than](#greater-than)
    - [null](#null)
    - [not null](#not-null)
  - [boolean operations](#boolean-operations)
    - [and](#and)
    - [or](#or)
    - [not](#not)
    - [nesting](#nesting)
  - [lists of scalar expressions](#lists-of-scalar-expressions)
    - [in list](#in-list)
    - [not in list](#not-in-list)
  - [subqueries](#subqueries)
    - [in subquery](#in-subquery)
    - [not in subquery](#not-in-subquery)
    - [exists - whether subquery returns any rows](#exists-whether-subquery-returns-any-rows)
    - [row-wise comparison with subqueries](#row-wise-comparison-with-subqueries)
- [advanced topics](#advanced-topics)
  - [combining criteria with `.and()`](#combining-criteria-with-and)
  - [combining criteria with `.or()`](#combining-criteria-with-or)
  - [negating criteria with `.not()`](#negating-criteria-with-not)
  - [escaping column names](#escaping-column-names)
  - [param array explosion](#param-array-explosion)
- [changelog](#changelog)
- [license: MIT](#license-mit)

## background

criterion is part of three libraries for nodejs that strive to

> make SQL with Nodejs
> [simple](http://www.infoq.com/presentations/Simple-Made-Easy),
> succinct,
> DRY,
> functional
> data-driven
> composable
> flexible
- free
- close to the metal (sql, database, database-driver)
- well documented
- and FUN !

- succinct 
- FUN !

short code

high quality

- few lines of high quality code

well tested

philosophy

#### [CRITERION](http://github.com/snd/criterion) <- you are looking at it

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

criterion exports a single function `criterion()` which
can be called either with a [condition-object](#condition-objects)
or with [raw-sql](#raw-sql):

### condition-objects

a *condition-object* describes an SQL-where-condition
as data using a *query-language* that is inspired by the
[mongodb query language](http://docs.mongodb.org/manual/tutorial/query-documents/).

let's make a *condition-object*:

``` js
var condition = {
  a: 7,
  b: {$lt: 5},
  $not: {
    $or: {
      c: [1, 2, 3],
      d: {$null: false}
    }
  }
};
```

you see that the *query-language* uses special *modifier-keys* to model comparisons (`$lt`), boolean operations (`$not`, `$or`)
and [much much more](#reference-by-example) (not unlike the [mongodb query language](http://docs.mongodb.org/manual/tutorial/query-documents/)).

now we can make a *criterion* from the *condition-object*:

``` js
var c = criterion(condition);
```

we can then compile the *criterion* to SQL:

``` js
c.sql();
// ->
// '(a = ?)
//  AND
//  (b < ?)
//  AND
//  NOT (
//    (c IN (?, ?, ?))
//    OR
//    (d IS NOT NULL)
//  )'
```

we can also get the bound parameters of the *criterion*:

```js
c.params();
// -> [7, 5, 1, 2, 3]
```

[see the reference below for examples on how to model almost every SQL-where-condition using *condition-objects* !](#reference-by-example)

### raw-sql

*raw-sql* is a string of SQL followed by some optional parameter bindings.

use *raw-sql* for those rare cases where condition-objects and you have to fall back to using strings.

``` js
var c = criterion('LOG(y, ?)', 4);
```

a criterion made from *raw-sql* behaves exactly like one made from
a *condition-object*:

you can get the sql:

```js
c.sql();
// -> 'LOG(y, ?)'
```

...and the bound parameters:

```js
c.params();
// -> [4]
```

note that [*condition-objects* and *raw-sql* can be mixed](#mixing-condition-objects-and-sql-fragments) to keep *raw-sql* to a minimum.

in fact both the criterion made from *raw-sql* and one made from
a *condition-object* are *sql-fragments*:

### the sql-fragment interface

in
[mesa](http://github.com/snd/mesa),
[mohair](http://github.com/snd/mohair)
and
[criterion](http://github.com/snd/criterion)
every object that has a `.sql()` method and optionally a `.params()` method
is said to "be an *sql-fragment*" or "to implement the *sql-fragment* interface".

more precisely:

the mandatory `.sql()` method should return a string of valid SQL.
the `.sql()` method might be called with a function `escape()` as the only argument.
the function `escape()` takes a string and returns a string.
when the `escape` function is present then the `.sql()` method should call `escape()`
to transform table- and column-names in the returned SQL:
if `.sql()` constructs the SQL on-the-fly that should be easy.
in the case of *raw-sql* escaping is very complex, ambigous, not worth the effort and therefore not required.

the optional `.params()` method takes no arguments and must return an array.

#### things that are sql-fragments (already)

- EVERY *criterion*:
  - `criterion({x: 7})`
  - `criterion('LOG(y, ?)', 4)`
- EVERY [mesa](http://github.com/snd/mesa)-query or [mohair](http://github.com/snd/mohair)-query:
  - `mesa.table('post')`
  - `mesa.table('post').where({id: 7})`
  - `mohair.table('host')`
  - `mohair.table('host').select('name').where({created_at: {$lt: new Date()}})`
- EVERY return value of [mesa's](http://github.com/snd/mesa) or [mohair's](http://github.com/snd/mohair) `.raw()` method:
  - `mesa.raw('LOG(y, ?)', 4)`
  - `mohair.raw('LOG(y, ?)', 4)`
- EVERY object you create that implements the [sql-fragment interface](#sql-fragment-interface)

#### mixing condition-objects and sql-fragments

now to the FUN part !

**ANY** *sql-fragment* can be used in place of **ANY** value in a *condition-object*:

``` js
var c = criterion({x: {$ne: criterion('LOG(y, ?)', 4)}});

c.sql();
// -> 'x != LOG(y, ?)'
c.params();
// -> [4]
```

you can see how this allows mixing *condition-objects* with arbitrary sql. use it to keep *raw-sql* to a minimum.

*sql-fragments* can be mixed with *condition-objects* inside boolean operators:

``` js
var c = criterion({
  $or: [
    criterion('x BETWEEN ? AND ?', 5, 10),
    {y: {$ne: 12}}
    [
      criterion({x: {$ne: criterion('LOG(y, ?)', 4)}}),
      {x: {$lt: 10}}
    ]
  ]
});

c.sql();
// ->
// '(x BETWEEN ? AND ?)
//  OR
//  (y != ?)
//  OR
//  (
//    (x != LOG(y, ?))
//    AND
//    (x < ?)
//  )'
c.params();
// -> [5, 10, 12, 4, 10]
```

the fact that [mohair](http://github.com/snd/mohair)-queries are *sql-fragments*
makes the creation of criteria with subqueries quite elegant:
[see the examples !](#subqueries)

## for users of mesa and mohair

[EVERYTHING possible with criterion](http://github.com/snd/criterion#reference-by-example) is possible
for the where conditions in
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

## condition-object reference by example

*the first example in each section is always the preferred way !*

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

### subquery

the fact that [mohair](http://github.com/snd/mohair)-queries are *sql-fragments*
makes the creation of criteria with subqueries quite elegant.

#### in subquery

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

#### not in subquery

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

#### subquery returns any rows

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

#### compare to any in subquery

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

`subquery` can be any [sql-fragment](#sql-fragment)

[see also the postgres documentation on row and array comparisons](http://www.postgresql.org/docs/9.3/static/functions-comparisons.html)

#### compare to all in subquery

TODO

#### row-wise comparison with subqueries

find published posts that were created strictly-before the user with `id = 1` was created:

``` js
var mohair = require('mohair');

var creationDateOfUserWithId1 = mohair
  .table('user')
  .where({id: 1})
  .select('created_at');

var postsCreatedBeforeUser = mohair
  .table('post')
  .where({is_published: true})
  .where({created_at: {$lt: creationDateOfUserWithId1}});

postsCreatedBeforeUser.sql();
// ->
// 'SELECT *
//  FROM post
//  WHERE is_published = ?
//  AND created_at < (SELECT created_at FROM user WHERE id = ?)'
postsCreatedBeforeUser.params();
// -> [true, 1]
```

## advanced topics

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

### param array explosion

if a parameter binding is an array then
the corresponding binding `?` is exploded into a list of `?`:

``` js
var c = criterion('x = ? AND y IN (?)', 7, [8, 9, 10]);

c.sql();        // -> 'x = ? AND y IN (?, ?, ?)'
c.params();     // -> [7, 8, 9, 10]

var c = criterion('x = ? AND (y && ARRAY[?])', 7, [8, 9, 10]);

c.sql();        // -> 'x = ? AND (y && ARRAY[?, ?, ?])'
c.params();     // -> [7, 8, 9, 10]
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

- start all result comments on a new line
- sections in reference
  - boolean operators
- document query nesting
  - document that you can intersperse sql fragments in $or and $and
- "you can use sql-fragments pretty much anywhere"
- if some combination that you think should work doesnt work file an issue
  and if it makes sense i'll make it work !
- document row-wise comparison
  - document all places where subqueries can be used
