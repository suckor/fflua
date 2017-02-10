local route = require("core.route")
local log = require("core.log")
local rep = require("core.response")

-----   init ctx values -------

ngx.ctx.loglist = {}
ngx.ctx.result = ""
ngx.ctx.log_report = 1
ngx.ctx.time = os.clock()


----    run route --------

local status, errinfo = pcall(route.run, route.get_method(ngx.var.uri))


if not status then
	log.set(log.ERROR, string.format("exec failed. uri: %s", ngx.var.uri))
end

rep.flush()
