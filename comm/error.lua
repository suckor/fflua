local log = require("core.log")
local json = require("cjson")

local err={
	ERROR_OK = {errid=0, errmsg="成功"},

	ERROR_SERVER_URL_NOT_EXIST = {errid=10001, errmsg='服务器错误,请求地址不存在'},
	ERROR_SERVER = {errid=10000, errmsg='服务器错误'},

	ERROR_EMPTY_USERNAME_PASSWORD = {errid=20001, errmsg='用户名或秘密为空，请重新输入。'},
	ERROR_USERNAME_PASSWORD_NOT_MATCH = {errid=20002, errmsg='用户名密码不匹配，请确认后重新输入'},
	ERROR_USERNAME_IS_EXISTED = {errid=20003, errmsg='用户名已存在，请重新输入'},
	ERROR_INSERT_NEW_USER_FAILED = {errid=20004, errmsg='注册失败'},
	ERROR_UPDATE_USERINFO_FAILED = {errid=20005, errmsg='用户信息更新失败'},
	ERROR_NO_USERINFO_NEED_UPDATE = {errid=20006, errmsg='没有信息需要更新'},
	ERROR_ACCESS_TOKEN_EXPIRED = {errid=20007, errmsg='access_token已过期，请重新登陆'},
	ERROR_LOGIN_FAILED = {errid=20008, errmsg='登陆失败'},
	ERROR_PARAMS = {errid=20009, errmsg='输入参数错误'},
	ERROR_TELPHONE_EXIST = {errid=20010, errmsg='手机号已存在'},
	ERROR_TELPHONE_CHECK_CODE = {errid=20011, errmsg='手机验证码错误'},
	ERROR_CREATE_PLAN = {errid=20012, errmsg="预约失败"},
	ERROR_NONE_CONTACTS = {errid=20013, errmsg="常用联系人不存在"},
	ERROR_NONE_ADDRESSES = {errid=20014, errmsg="常用联系人不存在"},

	ERROR_UNKOWN = {errid=99999, errmsg="未知错误"},
	

}

err.get_err_info = function(err_key)
	if err_key ~= nil and err[err_key] ~= nil then
		return err[err_key]
	else
		log.set(log.ERROR, string.format("not find error key [%s], please check...", err_key))
		return err.ERROR_UNKOWN
	end
end

err.format = function(err_key, json_data)
	local ret = {}
	local ret_str = ''
	local id = err.get_err_info(err_key)
	ret.err_id = id['errid']
	ret.msg = id['errmsg']
	ret.info = {}
	ret.runtime = os.clock() - ngx.ctx.time

	if type(json_data) == "table" then
		ret.info = json_data
	end

	local status, errinfo

	status, errinfo = pcall(function(str) ret_str = json.encode(ret)  end, ret)

	if status then
		return ret_str
	else
		log.set(log.ERROR, string.format("create json result faild, json format error. errinfo: %s", errinfo))
		return false
	end
end

return err

