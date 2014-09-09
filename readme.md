# SQL DSL for CoffeeScript on Node.js for PostgreSQL (coffee-sql)#

is small set of functions to compose SQL queries using [`Monad`](http://en.wikipedia.org/wiki/Monad_(functional_programming)) and [`function composition`](http://en.wikipedia.org/wiki/Function_composition_(computer_science)) style in CoffeeScript

## About the SQL DSL ##
If you are authoring a CRUD services in Node.js, you might deal with SQL database and construct sql dynamically depends on client requirements. Using the DSL, you can construct sql queries easily with the high-level little language.

The idea of this DSL is to split complicated sql query to functions and use operators to create a sql query. The SQL DSL can be easily extended with new operators.

## Details ##

File:
- [`coffee-sql.coffee`](https://github.com/adek1/coffee-sql/blob/master/coffee-sql.coffee)

### `State Function`
- [`SQL`](#sqlsql-params)
- [`SQLMonad`](#sqlmonadsql-params)

### `Operators`
- [`And`](#andoperators)
- [`Combine`](#combineoperators)
- [`CombineWith`](#combinewithoperator)
- [`Or`](#oroperators)
- [`SQLMonad.bind`](#sqlmonadbindoperatorfunction)
- [`SQLMonad.bindLeft`](#sqlmonadbindleftoperators)
- [`SQLPlus`](#sqlplussql-params)
- [`Where`](#whereoperators)
- [`WhereOr`](#whereoroperators)

## State Function ##

### <a id="sqlfunction"></a>`SQL(sql, [params])`
Creates a SQLMonad that represents a sql query with parameters.

#### Arguments
1.	`sql` *(string)*: String that represents SQL chunk
2.	`params` *(array)*: Array of parameters. If not specified, defaults to empty array

#### Returns
The new SQLMonad

#### Example
```coffee
{SQL} = require "coffee-sql"

query = SQL "SELECT * FROM table"

# => query.sql == "SELECT * FROM table"
#    query.params == []
```

### <a id="sqlmoandfunction"></a>`SQLMonad(sql, [params])`
SQLMonad represents a sql query with parameters.

#### Arguments
1.	`sql` *(string)*: String that represents SQL chunk
2.	`params` *(array)*: Array of parameters. If not specified, defaults to empty array


#### Returns
instance of SQLMonad

#### Example
```coffee
{SQLMonad} = require "coffee-sql"

query = new SQLMonad "SELECT * FROM table"

# => query.sql == "SELECT * FROM table"
#    query.params == []
```

## Operators ##

### <a id="andoperator"></a>`AND(operators)`
AND joins sql states with 'AND'

#### Arguments
1.	`operators` *(array)*: Array of operators

#### Returns
The new SQLMonad

#### Example
```coffee
{SQL, SQLPlus, AND} = require "coffee-sql"

query = SQL "SELECT * FROM table WHERE"
query = query.bind AND [
	SQLPlus "name = 'Tom'"
	SQLPlus "location = 'Prague'"
]

# => query.sql == "SELECT * FROM table
#	WHERE (name = 'Tome' AND location = 'Prague')"
#    query.params == []
```

### <a id="combineoperator"></a>`Combine(operators)`
Combine operators together

#### Arguments
1.	`operators` *(array)*: Array of operators

#### Returns
The new SQLMonad

#### Example
```coffee
{SQL, SQLPlus, Combine} = require "coffee-sql"

query = SQL "SELECT * FROM table"
query = query.bind Combine [
	SQLPlus "JOIN table_next ON table_next.table_id = table.id"
	SQLPlus "JOIN table_new ON table_new.table_id = table.id"
]

# => query.sql == "SELECT * FROM table
#	JOIN table_next ON table_next.table_id = table.id
#	JOIN table_new ON table_new.table_id = table.id"
#    query.params == []
```

### <a id="combinewithoperator"></a>`CombineWith(operator)`
CombineWith joins sql states with input operator

#### Arguments
1.	`operator` *(string)*: SQL operator to join sql chunks

#### Returns
Function, that takes array of operators and join results with operator

#### Example
```coffee
{SQL, SQLPlus, CombinWith} = require "coffee-sql"

query = SQL().bind CombinWith("UNION") [
	SQLPlus "SELECT a,b,c FROM table"
	SQLPlus "SELECT a,b,c FROM table_next"
]

# => query.sql == "SELECT a,b,c FROM table UNION SELECT a,b,c FROM table_next"
#    query.params == []
```

### <a id="oroperator"></a>`Or(operators)`
Or joins sql states with 'OR',

#### Arguments
1.	`operators` *(array)*: Array of operators

#### Returns
The new SQLMonad

#### Example
Look <a href="#andoperators">AND</a> operator

### <a id="bindoperator"></a>`SQLMonad.bind(operator|function)`
A bind function allows a programmer to attach sql state (sql and parameters) to a new operator or function, which accepts a state, then outputs a SQLMonad with a new state

#### Arguments
1.	`operator` *(function)*: Function transoforms a state to new one

#### Returns
The new SQLMonad

#### Example
```coffee
{SQL} = require "coffee-sql"

query = SQL("SELECT * FROM table").bind (sql, params) ->
	SQL "SELECT count(*) FROM (" + sql + ")", params

# => query.sql == "SELECT count(*) FROM (SELECT * FROM table)"
#    query.params == []
```

### <a id="bindleftoperator"></a>`SQLMonad.bindLeft(operators)`
SQLMonad.bindLeft applies bind operator to list of operators or functions

#### Arguments
1.	`operators` *(array)*: Array of operators

#### Returns
The new SQLMonad

#### Example
```coffee
{SQL, SQLPlus} = require "coffee-sql"

query = SQL("SELECT * FROM table").bindLeft [
	SQLPlus "JOIN table_next ON table_next.table_id = table.id"
	SQLPlus "ORDER BY id"
]

# => query.sql == "SELECT * FROM table
#	JOIN table_next ON table_next.table_id = table.id ORDER BY id"
#    query.params == []
```

### <a id="sqlplusoperator"></a>`SQLPlus(sql, [params])`
SQLPlus operator joins two sql statements together.

#### Arguments
1.	`sql` *(string)*: Chunk of sql query
2.	`params` *(string)*: Array of parameters. If not specified, defaults to empty array

#### Returns
The new SQLMonad

#### Example
```coffee
{SQL, SQLPlus, Where} = require "coffee-sql"

nameEquals = (name) ->
	SQLPlus "name = ?", [name]

locationEquals = (place) ->
	SQLPlus "location = ?", [place]

query = SQL("SELECT * FROM table").bind Where [
	nameEquals "Tom"
	locationEquals "Prague"
]

# => query.sql == "SELECT * FROM table WHERE name = $1 AND location = $2"
#    query.params == ["Tom", "Prague"]

# or

query = SQL("SELECT * FROM table").bind SQLPlus "WHERE name = 'Tom'"

# => query.sql == "SELECT * FROM table WHERE name = 'Tom'"
#    query.params == []
```

### <a id="whereoperator"></a>`Where(operators)`
Where binds each operator in the set and joins non empty results with "AND"

#### Arguments
1.	`operators` *(Array)*: array of operators

#### Returns
The new SQLMonad

#### Example
```coffee
{SQL, SQLPlus, Where} = require "coffee-sql"

query = SQL("SELECT * FROM table").bind Where [
	SQLPlus "name = 'Tom'"
	SQLPlus "location = 'Prague'"
]

# => query.sql == "SELECT * FROM table
#	WHERE name = 'Tome' AND location = 'Prague'"
#    query.params == []

# or

query = SQL("SELECT * FROM table").bind Where [
	SQL
	SQL
]

# => query.sql == "SELECT * FROM table"
#    query.params == []
```

### <a id="whereoroperator"></a>`WhereOr(operators)`
Where binds each operator in the set and joins non empty results with "OR"

#### Arguments
1.	`operators` *(Array)*: array of operators

#### Returns
The new SQLMonad

#### Example
Look <a href="#whereoperators">Where</a> operator
