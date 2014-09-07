SQLMonad = (sql, params) ->
	if (sql instanceof SQLMonad)
		this.sql = sql.sql
		this.params = sql.params
	else
		this.sql = sql
		this.params = params || []
	this

SQLMonad.prototype.bind = (fn) ->
	throw "Bind exception. Only function can be passed to bind operator." if  typeof fn isnt "function"
	next = fn this.sql, this.params
	new SQLMonad next.sql, next.params

SQLMonad.prototype.bindLeft = (fns) ->
	fns.reduce((head, f) ->
			head.bind f
		, this)

SQL = (sql, params) ->
	new SQLMonad sql, params

Combine = (fns) -> (sql, params) ->
	(SQL sql, params).bindLeft(fns)

CombineWith = (opr, wrapStart = null, wrapEnd = null) -> (fns) -> (sql, params) ->
	qs = fns
		.reduce((acc, fn) ->
			last = acc[acc.length-1]
			acc.push SQL("", last.params).bind fn
			acc
		, [SQL("", params)])
		.filter (q) -> q.sql != ""

	rsSql = qs.map((q) -> q.sql).join " #{opr} "
	rsSql = "#{wrapStart}#{rsSql}#{wrapEnd}" if rsSql isnt "" and wrapStart isnt null and wrapEnd isnt null
	rsSql = if (sql isnt "") then "#{sql} #{rsSql}" else rsSql
	SQL rsSql, qs.pop()?.params

SQLPlus = (fn) -> (sql, params) ->
	tail = (
		if (typeof fn is "string")
			{sql: fn, params: params}
		else
			fn params.length + 1
	)

	rsSql = (
		if (sql isnt "")
			"#{sql} #{tail.sql}"
		else
			tail.sql
	)

	SQL rsSql, params.concat(tail.params)

whereCombine = (opr) -> (fns) -> (sql, params) ->
	CombineWith(opr)(fns)("", params).bind (rsSql, rsParams) ->
		return SQL(sql, params) if rsSql is ""
		SQL "#{sql} WHERE #{rsSql}", rsParams

And = CombineWith("AND", "(", ")")

Or = CombineWith("OR", "(", ")")

Where = whereCombine("AND")

WhereOr = whereCombine("OR")

module.exports = {
	SQLMonad
	SQL
	SQLPlus
	Combine
	Where
	WhereOr
	And
	Or
	CombineWith
}