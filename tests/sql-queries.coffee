assert = require "assert"
{SQL, SQLPlus, Combine, Where, And, Or} = require "../coffee-sql"

describe "SQL Monad", ->
	it "bind query using SQLPlus with string argument", ->
		sql = SQL "SELECT * FROM press"
		query = sql.bind SQLPlus "JOIN tags ON tags.press_id = press.tags_id"

		assert.equal query.sql, "SELECT * FROM press JOIN tags ON tags.press_id = press.tags_id"

	it "bind query using SQLPlus with array params", ->
		sql = SQL "SELECT * FROM press"
		query = sql.bind SQLPlus "WHERE url_key = ?", ['press_url_key']

		assert.equal query.sql, "SELECT * FROM press WHERE url_key = $1"
		assert.deepEqual ['press_url_key'], query.params

	it "bind query using Combine", ->
		sql = SQL "SELECT * FROM press"
		query = sql.bind Combine [
			SQLPlus "JOIN tags ON tags.press_id = press.tags_id"
			SQLPlus "WHERE"
			And [
				SQLPlus "url_key = ?", ['press_url_key']
				SQLPlus "press.date = ?", ['press_date']
				SQLPlus "tag.url_key = ?", ['tag_url_key']
			]
		]

		assert.equal query.sql, \
		"SELECT * FROM press JOIN tags ON tags.press_id = press.tags_id 
			WHERE (url_key = $1 AND press.date = $2 AND tag.url_key = $3)"
		assert.deepEqual ['press_url_key', 'press_date', 'tag_url_key'], query.params

	it "bind query using Where", ->
		sql = SQL "SELECT * FROM press"
		query = sql.bind Where [
			SQLPlus "tags.press_id = press.tags_id"
			SQLPlus "tags.press_id = press.tags_id"
		]

		assert.equal query.sql, \
		"SELECT * FROM press WHERE tags.press_id = press.tags_id AND tags.press_id = press.tags_id"

	it "bind query using Where with empty arguments", ->
		sql = SQL "SELECT * FROM press"
		query = sql.bind Where [
			SQL
			SQL
			null
			undefined
		]

		assert.equal query.sql, "SELECT * FROM press"

	it "bind query using Where and Or operators", ->
		sql = SQL "SELECT * FROM press"
		query = sql.bind Where [
			SQLPlus "tags.press_id = press.tags_id"
			Or [
				SQLPlus "url_key = 'url_key'"
				SQLPlus "tag.url_key = 'tag_url_key'"
			]
		]

		assert.equal query.sql, \
		"SELECT * FROM press WHERE tags.press_id = press.tags_id 
			AND (url_key = 'url_key' OR tag.url_key = 'tag_url_key')"