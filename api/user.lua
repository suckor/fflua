local mysql = require("core.mysql")
local tool = require("core.tool")
local json = require("cjson")
local conf = require("comm.conf")
local rep = require("core.response")
local err = require("comm.error")
local req = require("core.request")

local user = {}

user.md5passwd = function(passwd)
	return ngx.md5(string.format("%s%s", password, conf.md5_str))
end

user.get_userinfo = function(username, password)
	local rdb = mysql.rdb()
	local res = mysql.select(rdb, "*", "user", "", {username=username, password=user.md5passwd(password)}, '1')
	
	if table.getn(res) > 0 then
		return res[1]
	else
		return nil
	end
end

user.check_args = function()
	local args = req.get_args('post')

	if args == nil then
		rep.set(err.format("ERROR_EMPTY_USERNAME_PASSWORD"))
		return false
	elseif args['username'] == nil or args['password'] == nil then
		rep.set(err.format("ERROR_EMPTY_USERNAME_PASSWORD"))
		return false
	elseif args['username'] == "" or args['password'] == "" then
		rep.set(err.format("ERROR_EMPTY_USERNAME_PASSWORD"))
		return false
	end

	return true
end

user.login = function()
	if not user.check_args() then return false end

	local args = req.get_args('post')
	local rdb = mysql.rdb()
	local res = mysql.select(rdb, "*", "user", "", {username=args['username'], password=user.md5passwd(args['password'])}, '1')

	if table.getn(res) <= 0 then
		--result.response_set("ERROR_USERNAME_PASSWORD_NOT_MATCH")
		rep.set(err.format("ERROR_USERNAME_PASSWORD_NOT_MATCH"))
		return false
	end

	--result.response_set("ERROR_OK", res[1])
	rep.set(err.format("ERROR_OK", res[1]))
	--rep.set(err.format("ERROR_OK", res[1]))
	return true
end

user.register = function()
	if not user.check_args() then return false end

	local args = req.get_args('post')

	local username = args['username']
	local password = args['password']

	local rdb = mysql.rdb()
	local wdb = mysql.wdb()

	local res = mysql.select(rdb, "*", "user", "", {username=username}, '1')

	if table.getn(res) > 0 then
		--result.response_set("ERROR_USERNAME_IS_EXISTED")
		rep.set(err.format("ERROR_USERNAME_IS_EXISTED"))
		return false
	end

	password = user.md5passwd(password)

	local params = {
		username=username,
		password=password,
		nickname=args['nickname'] or '',
		telphone=args['telphone'] or '',
		insert_time=os.date("%Y-%m-%d %H:%M:%S")
	}

	res = mysql.insert(wdb, 'user', params)

	if res.affected_rows > 0 then
		--result.response_set("ERROR_OK", user.get_userinfo(username, args['password']))
		rep.set(err.format("ERROR_OK", user.get_userinfo(username, args['password'])))
	else
		--result.response_set("ERROR_INSERT_NEW_USER_FAILED")
		rep.set(err.format("ERROR_INSERT_NEW_USER_FAILED"))
	end

	return true
end

user.update = function()
	if not user.check_args() then return false end

	local args = req.get_args()
	local wdb = mysql.wdb()
	local userinfo = user.get_userinfo(args['username'], args['password'])

	if type(userinfo) == 'nil' then
		--result.response_set("ERROR_USERNAME_PASSWORD_NOT_MATCH")
		rep.set(err.format("ERROR_USERNAME_PASSWORD_NOT_MATCH"))
		return false
	end

	local params = {}

	if args['nickname'] ~= nil then params['nickname'] = args['nickname'] end
	if args['telphone'] ~= nil then params['telphone'] = args['telphone'] end

	if tool.get_tbl_len(params) > 0 then
		local res = mysql.update(wdb, "user", params, {username=args['username'], password=user.md5passwd(args['password'])})
		
		if res['affected_rows'] > 0 then
			--result.response_set("ERROR_OK", user.get_userinfo(args['username'], args['password']))
			rep.set(err.format("ERROR_OK", user.get_userinfo(args['username'], args['password'])))
		else
			--result.response_set("ERROR_UPDATE_USERINFO_FAILED")
			rep.set(err.format("ERROR_UPDATE_USERINFO_FAILED"))
		end
	else
		--result.response_set("ERROR_NO_USERINFO_NEED_UPDATE")
		rep.set(err.format("ERROR_NO_USERINFO_NEED_UPDATE"))
	end

end

return user

