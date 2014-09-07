assert = require "assert"
{SQL} = require "../coffee-sql"

describe "Monad Laws", ->
	compare = (left, right) ->
		assert.equal left.sql, right.sql
		assert.deepEqual(left.params, right.params)

	it "should obey Left Identity Law (SQL(x).bind(fn) == SQL(fn(x)))", ->

		sql = "SELECT * FROM tags"
		params = ["brands"]
		fn = (sql, params) ->
			SQL sql + " WHERE tag = $1", params

		left = SQL(sql, params).bind(fn)
		right = SQL(fn(sql, params))

		compare left, right

	it "should obey Right Identity Law (SQL(x).bind((x) -> x) == SQL(x))", ->

		sql = "SELECT * FROM tags"
		params = ["brands"]

		fn = (sql, params) ->
			sql: sql
			params: params

		left = SQL(sql, params).bind(fn)
		right = SQL(sql, params)

		compare left, right

	it "should obey Associativity Law (SQL(x).bind(fn).bind(gn) == SQL(x).bind((x) -> gn(fn(x))))", ->

		sql = "SELECT * FROM tags"
		params = []

		fn = (sql, params) ->
			sql: sql + "WHERE tag = $1"
			params: params.concat(["brands"])

		gn = (sql, params) ->
			sql: sql + "AND type = $2"
			params: params.concat(["media"])

		left = SQL(sql, params).bind(fn).bind(gn)
		right = SQL(sql, params).bind (sql, params) ->
			rs = fn(sql, params)
			gn(rs.sql, rs.params)

		compare left, right