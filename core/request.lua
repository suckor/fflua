local log = require("core.log")
local resty_md5 = require("resty.md5")
local json = require("cjson")
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
		ngx.req.read_body()
		args = ngx.req.get_post_args()
	end

	return args
end

request.get_real_ip = function()
	return request.headers['X-Forwarded-For'] or request.headers['X-Real-IP'] or self.remote_addr
end

---- upload files ------
request._upload_filename = function(res)
	local name = nil
	local filename = nil
	
	local tmp=ngx.re.match(res, "(.+) name=\"(.+)\";(.*)")
	if tmp then name = tmp[2] end
	
	tmp=ngx.re.match(res, "(.+)filename=\"(.+)\"(.*)")
	if tmp then filename = tmp[2] end

	return name, filename
end

request.upload = function(chunk_size, time_out, tmp_path)
	local upload = require "resty.upload"
	local str = require "resty.string"
	local file
	local md5num=""
	local i=1
	local curtime = ngx.time()
	local ret = {}

	if chunk_size == nil then chunk_size = 4096 end
	if time_out == nil then time_out = 1000 end
	if tmp_path == nil then tmp_path = "/tmp" end

	local form, err = upload:new(chunk_size)

	if not form then
		log.set(log.ERROR, string.format("failed to new upload: %s", err))
		return nil, err
	end

	form:set_timeout(time_out)

	local md5 = resty_md5:new()

	while true do
		local typ, res, err = form:read()

		if not typ then
			log.set(log.ERROR, string.format("faild to read: %s"), err)
			return nil, err
		end

		if typ == "header" then 
			if ret[i] == nil then ret[i] = {size=0} end
			if res[1] == "Content-Disposition" then
				local name, filename = request._upload_filename(res[2])
				if name == nil or filename == nil then
					log.set(log.ERROR, string.format("upload file failed, Content-Disposition param error."))
					return nil, nil
				end
				local tmp_name = table.concat({tmp_path, "/", ngx.md5(filename), "_", curtime, i})
				file = io.open(tmp_name, "w+")
				if not file then
					log.set(log.ERROR, string.format("upload file failed, can not open target file %s", tmp_name))
					return nil, nil
				end
				
				ret[i]['name'] = name
				ret[i]['filename'] = filename
				ret[i]['tmpname'] = tmp_name
			elseif res[1] == "Content-Type" then
				ret[i]['type'] = res[2]
			end
			--ngx.say("read: ", json.encode({typ, res}))
			--file = io.open(target_name, "w+")
			--if not file then 
			--	log.set(log.ERROR, string.format("upload file failed, can not open target file %s", target_name))
			--	return nil, nil
			--end
		elseif typ == "body" then
			if file then
				file:write(res)
				md5:update(res)
				ret[i].size = ret[i].size + string.len(res)
			end
		elseif typ == "part_end" then
			if file then
				file:close()
				file = nil
				md5num = md5:final()
				md5:reset()
				ret[i]['md5sum'] = str.to_hex(md5num)
			end
			i = i + 1
		elseif typ == "eof" then
			break
		else
			-- write log
			log.set(log.ERROR, "error typ.")
		end
	end

	return	ret, "success."

end

return request
