local core = require "core.core"

local _M = {valid_time=500}			--token valid time 5 min


_M._access_token = function(uid)
	local token = ngx.md5(string.format("%s%d%f", core.conf.md5_str, uid, os.clock()))
	return ngx.encode_base64(token)
end

_M.authorize = function(username, password, userinfo)
	local rdb = core.mysql.rdb()
	local res = core.mysql.select(rdb, "*", "dm_user", "", {username=username, password=password}, '1')

	if table.getn(res) <= 0 then
		core.rep.set(core.err.format("ERROR_USERNAME_PASSWORD_NOT_MATCH"))
		return false, nil
	end

	local red = core.redis.redis()

	if not red then
		return false, nil
	end

	local token = _M._access_token(res[1]['id'])
	red:init_pipeline()
	red:hmset("user:" .. token .. ":info", {username=res[1]['username'], nickname=res[1]['nickname'], avatar="", telphone=res[1]['telphone'], id=res[1]['id']})
	red:expire("user:" .. token .. ":info", _M.valid_time)
	local results, err = red:commit_pipeline()
	if not results then
		core.log.set(core.log.ERROR, string.format("failed to commit the pipelined requests: %s", err))
		return false, nil
	end
	
	core.redis.close(red, 1)

	if userinfo then
		return true, {token = token, userinfo = {username=res[1]['username'], nickname=res[1]['nickname'], avatar="", telphone=res[1]['telphone'], id=res[1]['id']}}
	else
		return true, {token = token}
	end
end

_M.valid = function(token)
	local key = "user:" .. token .. ":info"
	local red = core.redis.redis()

	if not red then
		return false
	end

	local res, err = red:hget(key, 'id')
	if not res then
		core.log.set(core.log.ERROR, string.format("failed to get %s: %s", key, err))
		core.rep.set(core.err.format("ERROR_SERVER"))
		return false
	end

	if res == ngx.null then
		core.rep.set(core.err.format("ERROR_ACCESS_TOKEN_EXPIRED"))
		return false
	end

	return _M.refresh_token(token)
end

_M.refresh_token = function(token)
	local key = "user:" .. token .. ":info"
	local red = core.redis.redis()

	if not red then
		return false
	end

	local res, err = red:expire(key, _M.valid_time)
	if not res then
		core.log.set(core.log.ERROR, string.format("failed to expire %s: %s", key, err))
		core.rep.set(core.err.format("ERROR_SERVER"))
		return false
	end

	core.redis.close(red, 1)

	if res == 1 then
		return true
	else
		return false
	end
end

_M.user_info = function(access_token)
	local key = "user:" .. access_token .. ":info"
	local red = core.redis.redis()

	if not red then
		return false
	end
	local res, err = red:hmget(key, 'id', 'username', 'nickname', 'telphone', 'avatar')
	if not res then
		core.log.set(core.log.ERROR, string.format("failed to get %s: %s", key, err))
		core.rep.set(core.err.format("ERROR_SERVER"))
		return false
	end

	if res == ngx.null or res[1] == ngx.null then
		core.rep.set(core.err.format("ERROR_ACCESS_TOKEN_EXPIRED"))
		return false
	end
	
	_M.refresh_token(access_token)

	local ret = {id=res[1], username=res[2], nickname=res[3], telphone=res[4], avatar=res[5]}
	return ret
end

return _M
