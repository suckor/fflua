local mysql = require("core.mysql")
local tool = require("core.tool")
local conf = require("comm.conf")
local rep = require("core.response")
local err = require("comm.error")
local req = require("core.request")
local redis = require("core.redis")
local log = require("core.log")
local auth = require "api.auth"
local json = require("cjson")
local init = require("api.init")

local user = {}

user.md5passwd = function(passwd)
	return ngx.md5(string.format("%s%s", passwd, conf.md5_str))
end

user.get_userinfo = function(username, password)
	--local rdb = mysql.rdb()
	--local res = mysql.select(rdb, "*", "user", "", {username=username, password=user.md5passwd(password)}, '1')
	
	--if table.getn(res) > 0 then
	--	return res[1]
	--else
	--	return nil
	--end
	local st, res = auth.authorize(username, user.md5passwd(password), 1)
	
	if not st then 
		rep.set(err.format("ERROR_LOGIN_FAILED"))
		return nil
	end

	return res
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
	
	local st, res = auth.authorize(args['username'], user.md5passwd(args['password']), 1)
	
	if not st then 
		rep.set(err.format("ERROR_LOGIN_FAILED"))
	end

	--result.response_set("ERROR_OK", res[1])
	rep.set(err.format("ERROR_OK", res))
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

	local res = mysql.select(rdb, "*", "dm_user", "", {username=username}, '1')

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

	res = mysql.insert(wdb, 'dm_user', params)

	if res.affected_rows > 0 then
		--result.response_set("ERROR_OK", user.get_userinfo(username, args['password']))
		rep.set(err.format("ERROR_OK", user.get_userinfo(username, args['password'])))
	else
		--result.response_set("ERROR_INSERT_NEW_USER_FAILED")
		rep.set(err.format("ERROR_INSERT_NEW_USER_FAILED"))
	end

	return true
end

user._check_telphone = function()
	local args = req.get_args("post")

	if not args or not args['telphone'] then
		rep.set(err.format("ERROR_PARAMS"))
		return false
	end

	local res = mysql.select(mysql.rdb(), "*", "dm_user", "", {telphone=args['telphone']}, '1')

	if type(res) == "table" and #res > 0 then
		rep.set(err.format("ERROR_TELPHONE_EXIST"))
		return false
	end
	
	return true
end

user.check_telphone = function()
	if user._check_telphone() then
		rep.set(err.format("ERROR_OK"))
		return true
	end

	return false
end

user.send_telphone_check_code = function()
	local args = req.get_args("post")

	if not args or not args['telphone'] then
		rep.set(err.format("ERROR_PARAMS"))
		return false
	end

	local res = mysql.select(mysql.rdb(), "*", "dm_user", "", {telphone=args['telphone']}, '1')

	if type(res) == "table" and #res > 0 then
		rep.set(err.format("ERROR_TELPHONE_EXIST"))
		return false
	end

	local red = redis.redis()

	if not red then
		rep.set(err.format("ERROR_SERVER"))
		return false
	end
	local check_code = tool.get_random_str(6)
	--ngx.say(check_code)
	
	local res, e = tool.send_sms_message(args['telphone'], {no=check_code})

	if not res then
		rep.set(err.format("ERROR_SERVER"))
		return false
	end

	red:init_pipeline()
	red:set("user:" .. args['telphone'] .. ":check_code", check_code)
	red:expire("user:" .. args['telphone'] .. ":check_code", 300)		-- telphone check code will invalid after 5 minites

	local results, err1 = red:commit_pipeline()
	if not results then
		core.log.set(core.log.ERROR, string.format("failed to commit the pipelined requests: %s", err1))
		rep.set(err.format("ERROR_SERVER"))
		return false
	end

	redis.close(red, 1)
	
	rep.set(err.format("ERROR_OK", {check_code=check_code}))
end

user._check_telphone_check_code = function()
	local args = req.get_args("post")

	if not args or not args['telphone'] or not args['check_code'] then
		rep.set(err.format("ERROR_PARAMS"))
		return false
	end

	local red = redis.redis()

	if not red then
		rep.set(err.format("ERROR_SERVER"))
		return false
	end

	local key = "user:" .. args['telphone'] .. ":check_code"
	
	local res, e = red:get(key)
	if not res or res ~= args['check_code'] then
		rep.set(err.format("ERROR_TELPHONE_CHECK_CODE"))
		return false
	end

	redis.close(red, 1)

	return true

end

user.check_telphone_check_code = function()
	if user._check_telphone_check_code() then
		rep.set(err.format("ERROR_OK"))
		return true
	end

	return false
end

user.register_by_telphone = function()
	local args = req.get_args("post")

	if not args or not args['password'] then
		rep.set(err.format("ERROR_PARAMS"))
		return false
	end

	if not user._check_telphone() then
		return false
	end

	if not user._check_telphone_check_code() then
		return false
	end
	local password = user.md5passwd(args['password'])

	local params = {
		username=args['telphone'],
		password=password,
		nickname=args['telphone'] or '',
		telphone=args['telphone'],
		insert_time=os.date("%Y-%m-%d %H:%M:%S")
	}

	res = mysql.insert(mysql.wdb(), 'dm_user', params)

	if res.affected_rows > 0 then
		--result.response_set("ERROR_OK", user.get_userinfo(username, args['password']))
		rep.set(err.format("ERROR_OK", user.get_userinfo(username, args['password'])))
	else
		--result.response_set("ERROR_INSERT_NEW_USER_FAILED")
		rep.set(err.format("ERROR_INSERT_NEW_USER_FAILED"))
	end

	return true
end

user.login_by_telphone = function()
	local args = req.get_args("post")

	if not args or not args['telphone'] or not args['password'] then
		rep.set(err.format("ERROR_PARAMS"))
		return false
	end

	local st, res = auth.authorize(args['telphone'], user.md5passwd(args['password']), 1)
	
	if not st then 
		rep.set(err.format("ERROR_LOGIN_FAILED"))
		return false
	end

	--result.response_set("ERROR_OK", res[1])
	rep.set(err.format("ERROR_OK", res))
	--rep.set(err.format("ERROR_OK", res[1]))
	return true
end


user.userinfo_by_token = function()
	local args = req.get_args("post")
	
	if not args or not args['access_token'] then
		rep.set(err.format("ERROR_PARAMS"))
		return false
	end

	local info = auth.user_info(args['access_token'])

	if info then
		rep.set(err.format("ERROR_OK", info))
	end

	return false
end

user._trans_plan_email_body = function(template, userinfo, planinfo)
	local temp = template
	return temp:gsub("%$check_cnt", init['create_plan']['check_cnt'][planinfo['check_cnt']]):gsub("%$address", init['create_plan']['address'][planinfo['address']]):gsub("%$person_num", 
			planinfo['person_num']):gsub("%$go_date", planinfo['go_date']):gsub("%$day_num", planinfo['day_num']):gsub("%$order_telphone",
			planinfo['order_telphone']):gsub("%$order_name", planinfo['order_name']):gsub("%$order_weixin", planinfo['order_weixin']):gsub("%$order_comment", 
			planinfo['order_comment']):gsub("%$user_name", userinfo['username']):gsub("%$user_telphone", userinfo['telphone']):gsub("%$user_nickname", userinfo['nickname'])
end

user.create_plan = function()
	local args = req.get_args("post")

	if not args or not args['access_token'] then
		rep.set(err.format("ERROR_PARAMS"))
		return false
	end

	local user_info = auth.user_info(args['access_token'])

	if not user_info then
		return false
	end

	local params = {
		['user_id'] = user_info['id'],
		['check_cnt'] = args['check_cnt'] == nil and 0 or args['check_cnt'],
		['address'] = args['address'] == nil and 0 or args['address'],
		['person_num'] = args['person_num'] == nil and 0 or args['person_num'],
		['day_num'] = args['day_num'] == nil and 0 or args['day_num'],
		['go_date'] = args['go_date'] == nil and '0000-00-00' or args['go_date'],
		['order_name'] = args['order_name'] == nil and '' or args['order_name'],
		['order_telphone'] = args['order_telphone'] == nil and '' or args['order_telphone'],
		['order_weixin'] = args['order_weixin'] == nil and '' or args['order_weixin'],
		['order_comment'] = args['order_comment'] == nil and '' or args['order_comment'],
		insert_time=os.date("%Y-%m-%d %H:%M:%S")
	}

	local res, e = mysql.insert(mysql.wdb(), "dm_plan_info", params)

	if res.affected_rows > 0 then
		-- send email to customer service

		local red = redis.redis()

		if not red then
			rep.set(err.format("ERROR_SERVER"))
			return false
		end
		local msg_info = conf.email_template.plan_create
		msg_info['body'] = user._trans_plan_email_body(msg_info['body'], user_info, args)
		local res, e = red:lpush("list:email", json.encode(msg_info))
		if not res  then
			rep.set(err.format("ERROR_SERVER"))
			return false
		end
		redis.close(red, 1)
		
		--result.response_set("ERROR_OK", user.get_userinfo(username, args['password']))
		rep.set(err.format("ERROR_OK"))
	else
		--result.response_set("ERROR_INSERT_NEW_USER_FAILED")
		rep.set(err.format("ERROR_CREATE_PLAN"))
	end



end


user.check_token = function()
	local args = req.get_args()
	
	if not args or not args['access_token'] then
		rep.set(err.format("ERROR_PARAMS"))
		return false
	end

	local ret = auth.valid(args['access_token'])

	if ret then
		rep.set(err.format("ERROR_OK"))
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


---------------------------   user center    -----------------------------------------
user.edit_frequent_contacts = function()
	local args = req.get_args("post")
	local cid = nil

	if not args or not args['access_token'] then
		rep.set(err.format("ERROR_PARAMS"))
		return false
	end

	local user_info = auth.user_info(args['access_token'])

	if not user_info then
		return false
	end

	if args['cid'] and type(tonumber(args['cid'])) == 'number' then
		cid = tonumber(args['cid'])
	end
	if cid == 0 then 
		cid = nil
	end

	local user_id = user_info['id']
	local parms = {
		["user_id"] = user_id,
		["zh_name"] = args['zh_name'],
		["pp_en_name_1"] = args['pp_en_name_1'],
		["pp_en_name_2"] = args['pp_en_name_2'],
		["pp_number"] = args['pp_number'],
		["pp_expire_date"] = args['pp_expire_date'],
		["nationality"] = args['nationality'],
		["birthday"] = args['birthday'],
		["sex"] = tonumber(args['sex']),
	}

	if parms["sex"] ~= 0 and parms["sex"] ~= 1 then
		parms["sex"] = nil
	end
	
	if cid then
		local res = mysql.update(mysql.wdb(), "dm_user_frequent_contacts", parms, {id=cid})
	else
		parms['insert_time']=os.date("%Y-%m-%d %H:%M:%S")
		local res = mysql.insert(mysql.wdb(), "dm_user_frequent_contacts", parms)
	end
	
	rep.set(err.format("ERROR_OK"))
end

user.del_frequent_contacts = function()
	local args = req.get_args("post")
	local cid = nil

	if not args or not args['access_token'] or not args['cid'] or not string.find(args['cid'], "%d+") then
		rep.set(err.format("ERROR_PARAMS"))
		return false
	end

	local user_info = auth.user_info(args['access_token'])

	if not user_info then
		return false
	end

	local sql = "delete from dm_user_frequent_contacts where user_id = " .. user_info['id'] .. " and id in ("
	for v in string.gmatch(args['cid'], "%d+") do
		sql = sql .. v .. ","
	end
	sql = string.sub(sql, 1, -2) .. ")"

	local res = mysql.query(mysql.wdb(), sql)

	rep.set(err.format("ERROR_OK"))
end

user.get_frequent_contacts=function()
	local args = req.get_args("post")
	local cid = nil

	if not args or not args['access_token'] then
		rep.set(err.format("ERROR_PARAMS"))
		return false
	end

	local user_info = auth.user_info(args['access_token'])

	if not user_info then
		return false
	end

	local res;
	if args['cid'] and string.find(args['cid'], "%d+") then
		local sql = "select * from dm_user_frequent_contacts where user_id = " .. user_info['id'] .. " and id in ("
		for v in string.gmatch(args['cid'], "%d+") do
			sql = sql .. v .. ","
		end
		sql = string.sub(sql, 1, -2) .. ")"

		res = mysql.query(mysql.wdb(), sql)
	else
		res = mysql.select(mysql.rdb(), "*", "dm_user_frequent_contacts", "", {user_id=user_info['id']})
	end
	
	if type(res) == "table" and #res > 0 then
		rep.set(err.format("ERROR_OK", res))
	else
		rep.set(err.format("ERROR_NONE_CONTACTS"))
	end
end

user.get_addresses=function()
	local args = req.get_args("post")
	local aid = nil

	if not args or not args['access_token'] then
		rep.set(err.format("ERROR_PARAMS"))
		return false
	end

	local user_info = auth.user_info(args['access_token'])

	if not user_info then
		return false
	end

	if args['aid'] and type(tonumber(args['aid'])) == 'number' then
		aid = tonumber(args['aid'])
	end

	local res;
	if aid then
		res = mysql.select(mysql.rdb(), "*", "dm_user_addresses", "", {user_id=user_info['id'], id=aid}, 1)
	else
		res = mysql.select(mysql.rdb(), "*", "dm_user_addresses", "", {user_id=user_info['id']})
	end
	
	if type(res) == "table" and #res > 0 then
		rep.set(err.format("ERROR_OK", res))
	else
		rep.set(err.format("ERROR_NONE_CONTACTS"))
	end
end

user.del_address=function()
	local args = req.get_args("post")
	local aid = nil

	if not args or not args['access_token'] or not args['aid'] or not string.find(args['aid'], "%d+") then
		rep.set(err.format("ERROR_PARAMS"))
		return false
	end

	local user_info = auth.user_info(args['access_token'])

	if not user_info then
		return false
	end

	local sql = "delete from dm_user_addresses where user_id = " .. user_info['id'] .. " and id in ("
	for v in string.gmatch(args['aid'], "%d+") do
		sql = sql .. v .. ","
	end
	sql = string.sub(sql, 1, -2) .. ")"

	local res = mysql.query(mysql.wdb(), sql)

	rep.set(err.format("ERROR_OK"))
end

user.edit_address=function()
	local args = req.get_args("post")
	local aid = nil

	if not args or not args['access_token'] then
		rep.set(err.format("ERROR_PARAMS"))
		return false
	end

	local user_info = auth.user_info(args['access_token'])

	if not user_info then
		return false
	end

	if args['aid'] and type(tonumber(args['aid'])) == 'number' then
		aid = tonumber(args['aid'])
	end
	if aid == 0 then 
		aid = nil
	end

	local user_id = user_info['id']
	local parms = {
		["user_id"] = user_id,
		["addressee"] = args['addressee'],
		["telephone"] = args['telephone'],
		["province_id"] = args['province_id'],
		["city_id"] = args['city_id'],
		["address_detail"] = args['address_detail'],
	}

	if aid then
		local res = mysql.update(mysql.wdb(), "dm_user_addresses", parms, {id=aid})
	else
		parms['insert_time']=os.date("%Y-%m-%d %H:%M:%S")
		local res = mysql.insert(mysql.wdb(), "dm_user_addresses", parms)
	end
	
	rep.set(err.format("ERROR_OK"))
end

user.set_default_address=function()
	local args = req.get_args("post")
	local aid = nil

	if not args or not args['access_token'] or not args['aid'] or type(tonumber(args['aid'])) ~= 'number' then
		rep.set(err.format("ERROR_PARAMS"))
		return false
	end

	local user_info = auth.user_info(args['access_token'])

	if not user_info then
		return false
	end

	aid = tonumber(args['aid'])

	--@todo
	local res = mysql.update(mysql.wdb(), "dm_user_addresses", {is_default=0}, {user_id=user_info['id']})
	local res = mysql.update(mysql.wdb(), "dm_user_addresses", {is_default=1}, {user_id=user_info['id'], id=aid})

	rep.set(err.format('ERROR_OK'))
end

user.upload = function()
	local file, errinfo = req.upload()
	rep.set(err.format("ERROR_OK", file))
end

return user

