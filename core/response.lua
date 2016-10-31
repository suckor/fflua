local log = require("core.log")

local response = {}

response.set = function(result_json)
	if ngx.ctx.result == nil or ngx.ctx.result == "" then
		ngx.ctx.result = result_json
	else
		log.set(log.ERR, string.format("rewrite result, want override [%s]", ngx.ctx.result))
		response.flush()
	end

	return true
end


response.flush = function()
	if type(ngx.ctx.result) == "string" and ngx.ctx.result ~= "" then
		ngx.say(ngx.ctx.result)
	else
		ngx.say("{err_id:-1, msg:\"no result.\", info:{}}")
	end
	ngx.exit(ngx.HTTP_OK)
	return true
end

return response
