local config = require("comm.conf")
local tool = require("core.tool")
local log = require("core.log")
local err = require("comm.error")
local rep = require("core.response")

local route = {
	get_method = function(uri)
		uri = string.gsub(uri, "/$", "")
		local class = nil
		local method = nil

		if type(config.route) == "table" and table.getn(config.route) > 0 then
			for i, rt in ipairs(config.route) do
				if type(rt) == "table" and table.getn(rt) >= 2 then
					local route_uri =  string.gsub(rt[1], "/$", "")
					if route_uri == uri then
						class = require(rt[2])
						if rt[3] then
							method = rt[3]
						else
							method = "index"					--defalut exec index function
						end
						break
					end
				end
			end
		end

		return class, method

	end,

	run = function(class, method, ...)

		if class == nil or method == nil then
			--result.response_set("ERROR_SERVER_URL_NOT_EXIST")
			rep.set(err.format("ERROR_SERVER_URL_NOT_EXIST"))
		end

		if class ~= nil and method ~= nil then
			local status, errinfo = pcall(class[method], ...)

			if not status then
				--tool.set_errlog(errinfo)
				log.set(log.ERROR, errinfo)
			end

		end


	end
}

return route
