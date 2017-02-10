local mysql = require("resty.mysql")
local config = require("comm.conf")
local tool = require("core.tool")
local log = require("core.log")


local _db_close = function(db, keepalive)

	if not db then
		--tool.set_errlog("close mysql failed..")
		log.set(log.ERROR, "close mysql failed..")
	end

	if keepalive then

		-- put it into the connection pool of size 100,
		-- with 10 seconds max idle timeout
		local ok, err = db:set_keepalive(10000, 100)
		if not ok then
			--tool.set_errlog(string.format("failed to set keepalive: %s", err))
			log.set(log.ERROR, string.format("failed to set keepalive: %s", err))
		end
	else
		local ok, err = db:close()
		if not ok then
			--tool.set_errlog(string.format("failed to set keepalive: %s", err))
			log.set(log.ERROR, string.format("failed to set keepalive: %s", err))
		end
	end

end

local _mysql = {

	wdb = function()
		local db, err = mysql:new()
		if not db then 
			--tool.set_serlog(string.format("failed to instantiate mysql: %s", err))
			log.set(log.ERROR, string.format("failed to instantiate mysql: %s", err))
		end

		db:set_timeout(1000)

		local ok, err, errcode, sqlstate = db:connect(config.mysql.write)
		if not ok then
			--tool.set_errlog(string.format("failed to connect: %s: %s $s", err, errcode, sqlstate))
			log.set(log.ERROR, string.format("failed to connect: %s: %s $s", err, errcode, sqlstate))
		end

		db:query("set names 'utf8'")

		return db

	end,

	rdb = function()
		local db, err = mysql:new()
		if not db then 
			--tool.set_errlog(string.format("failed to instantiate mysql: %s", err))
			log.set(log.ERROR, string.format("failed to instantiate mysql: %s", err))
		end

		db:set_timeout(1000)
		
		math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))
		local key = math.random(1, table.getn(config.mysql.read))

		local ok, err, errcode, sqlstate = db:connect(config.mysql.read[key])
		if not ok then
			--tool.set_errlog(string.format("failed to connect: %s: %s $s", err, errcode, sqlstate))
			log.set(log.ERROR, string.format("failed to connect: %s: %s $s", err, errcode, sqlstate))
		end
		db:query("set names 'utf8'")

		return db
	end,

	insert = function(db, tblname, info)
		if type(info) ~= 'table'  then
			return false
		end

		local sql = {'INSERT INTO ', tblname, '('}

		for k, v in pairs(info) do
			table.insert(sql, '`')
			table.insert(sql, k)
			table.insert(sql, '`')
			table.insert(sql, ',')
		end
		table.remove(sql)
		table.insert(sql, ') VALUES(')

		for k,v in pairs(info) do
			if type(v) == "number" then
				table.insert(sql, v)
			else
				table.insert(sql, tool.trans_data(v))
			end
			table.insert(sql, ',')
		end
		table.remove(sql)
		table.insert(sql, ')')
		
		sql = table.concat(sql)
		--ngx.say(sql)

		local res, err, errcode, sqlstate = db:query(sql)
		if not res then 
			--tool.set_errlog(string.format("bad result: %s: %s: %s.", err, errcode, sqlstate))
			--tool.set_errlog(string.format("ERROR SQL: [ %s ], bad result: %s: %s: %s.", sql, err, errcode, sqlstate))
			log.set(log.ERROR, string.format("ERROR SQL: [ %s ], bad result: %s: %s: %s.", sql, err, errcode, sqlstate))
		end

		_db_close(db, true)

		return res
	end,

	delete = function(db, tblname, where)
		if type(where) ~= 'table' then
			return false
		end

		local sql = {'DELETE FROM ', tblname, ' WHERE '}

		for k, v in pairs(where) do
			table.insert(sql, string.format("%s = ", k))
			table.insert(sql, tool.trans_data(v))
			table.insert(sql, ' AND ')
		end
		table.remove(sql)

		sql = table.concat(sql)
		
		local res, err, errcode, sqlstate = db:query(sql)
		if not res then 
			--tool.set_errlog(string.format("bad result: %s: %s: %s.", err, errcode, sqlstate))
			--tool.set_errlog(string.format("ERROR SQL: [ %s ], bad result: %s: %s: %s.", sql, err, errcode, sqlstate))
			log.set(log.ERROR, string.format("ERROR SQL: [ %s ], bad result: %s: %s: %s.", sql, err, errcode, sqlstate))
		end

		_db_close(db, true)
		return res
	end,

	update = function(db, tblname, info, where)
		if type(info) ~= 'table' then
			return false
		end

		if type(where) ~= 'table' or tool.get_tbl_len(where) == 0 then
			where = {1}
		end

		local sql = {'UPDATE ', tblname, ' SET '}
		
		for k, v in pairs(info) do
			table.insert(sql, string.format("%s = ", k))
			table.insert(sql, tool.trans_data(v))
			table.insert(sql, ',')
		end
		table.remove(sql)
		table.insert(sql, ' WHERE ')
		for k, v in pairs(where) do
			table.insert(sql, string.format('%s = ', k))
			table.insert(sql, tool.trans_data(v))
			table.insert(sql, ' AND ')
		end
		table.remove(sql)

		sql = table.concat(sql)
		--ngx.say(sql)

		local res, err, errcode, sqlstate = db:query(sql)
		if not res then 
			--tool.set_errlog(string.format("bad result: %s: %s: %s.", err, errcode, sqlstate))
			--tool.set_errlog(string.format("ERROR SQL: [ %s ], bad result: %s: %s: %s.", sql, err, errcode, sqlstate))
			log.set(log.ERROR, string.format("ERROR SQL: [ %s ], bad result: %s: %s: %s.", sql, err, errcode, sqlstate))
		end

		_db_close(db, true)
		return res
	end,

	select = function(db, select_var, tblname, join, where, limit)
		if type(select_var) ~= "string" or type(tblname) ~= "string" or type(join) ~= "string" then
			return false
		end

		if type(where) ~= 'table' or tool.get_tbl_len(where) == 0 then
			where = {1}
		end

		local sql = {"SELECT ", select_var, " FROM ", tblname, " ", join, " WHERE "}
		for k, v in pairs(where) do
			table.insert(sql, string.format('%s = ', k))
			table.insert(sql, tool.trans_data(v))
			table.insert(sql, ' AND ')
		end
		table.remove(sql)
		if type(limit) == "string" and limit ~= "" then
			table.insert(sql, " LIMIT ")
			table.insert(sql, limit)
		end

		sql = table.concat(sql)
		 --ngx.say(sql)

		local res, err, errcode, sqlstate = db:query(sql)
		if not res then 
			--tool.set_errlog(string.format("ERROR SQL: [ %s ], bad result: %s: %s: %s.", sql, err, errcode, sqlstate))
			log.set(log.ERROR, string.format("ERROR SQL: [ %s ], bad result: %s: %s: %s.", sql, err, errcode, sqlstate))
		end

		_db_close(db, true)
		return res
	end,

	query = function(db, sql)
		local res, err, errcode, sqlstate = db:query(sql)
		if not res then 
			--tool.set_errlog(string.format("ERROR SQL: [ %s ], bad result: %s: %s: %s.", sql, err, errcode, sqlstate))
			log.set(log.ERROR, string.format("ERROR SQL: [ %s ], bad result: %s: %s: %s.", sql, err, errcode, sqlstate))
		end
		--ngx.say(sql)

		_db_close(db, true)
		return res
	end,

}


return _mysql
