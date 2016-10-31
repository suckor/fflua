local log = require("core.log")
local request = {}

request.request_method = ngx.var.request_method
request.host = ngx.var.host
request.hostname = ngx.var.hostname
request.remote_addr = ngx.var.remote_addr
request.headers = ngx.req.get_headers()

request.get_args = function(http_method)
	local args = nil

	if http_method == nil then
		http_method = "post"
	end

	if string.lower(request.request_method) ~= string.lower(http_method) then
		log.set(log.ERROR, "request method err.")
		return args
	end

	if string.lower(request.request_method) == "get" then
		args = ngx.req.get_uri_args()
	elseif string.lower(request.request_method) == "post" then
		args = ngx.req.get_post_args()
	end

	return args
end

request.get_real_ip = function()
	return request.headers['X-Forwarded-For'] or request.headers['X-Real-IP'] or self.remote_addr
end

return request
