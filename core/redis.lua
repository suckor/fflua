local redis = require "resty.redis"
local config = require("comm.conf")
local tool = require("core.tool")
local log = require("core.log")

local _M ={}

_M._conf = function()
	return config.redis[1]
end

_M.redis = function()
	local red = redis:new()

	red:set_timeout(1000)

	local conf = _M._conf()

	if conf then
		local ok, err = red:connect(conf.host, conf.port)
		if not ok then
			log.set(log.ERROR, string.format("failed to connect: %s", err))
			return
		end

		if conf.requirepass then
			local res, err = red:auth(conf.requirepass)
			if not res then
				log.set(log.ERROR, string.format("failed to authenticate: %s", err))
				return
			end
		end
	else
		log.set(log.ERROR, "no redis config.")
	end

	return red
end

_M.close = function(red, keepalive)
	if not red then
		log.set(log.ERROR, "close redis failed.")
		return
	end

	if keepalive then
		-- put it into the connection pool of size 100,
		-- with 10 seconds max idle time
		local ok, err = red:set_keepalive(10000, 100)
		if not ok then
			log.set(log.ERROR, string.format("failed to set keepalive: %s", err))
			return 
		end
	else
		local ok, err = red:close()
		if not ok then
			log.set(log.ERROR, string.format("failed to close: %s", err))
			return
		end
	end

	return
end


return _M
