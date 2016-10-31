local log = {}

log.INFO = 8
log.DEBUG = 4
log.WARNING = 2
log.ERROR = 1

log.set = function(level, msg)
	local ngx_level = ngx.ERR

	if level == log.ERROR then
		ngx_level = ngx.ERR
	elseif level == log.WARNING then
		ngx_level = ngx.WARN
	elseif level == log.DEBUG then
		ngx_level = ngx.DEBUG
	elseif level == log.INFO then
		ngx_level = ngx.INFO
	else
		ngx_level = ngx.ERR
	end

	if type(ngx.ctx.loglist) ~= "table" then
		ngx.log(ngx.WARN, "not set ngx.ctx.loglist.")
		ngx.ctx.loglist = {}
	end

	if type(ngx.ctx.log_report) ~= "number" then
		ngx.ctx.log_report = 1
	end

	if ngx.ctx.log_report >= level then
		table.insert(ngx.ctx.loglist, {level=ngx_level, msg=msg})
	end

	return true
end

log.flush = function()
	if type(ngx.ctx.loglist) == "table" and table.getn(ngx.ctx.loglist) > 0 then
		for k, v in ipairs(ngx.ctx.loglist) do
			ngx.log(v['level'], v['msg'])
		end
	end
end

return log
