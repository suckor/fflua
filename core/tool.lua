local json = require("cjson")

local tool = {

	-- sql injection for input data by user
	trans_data = function(data)
		return ndk.set_var.set_quote_sql_str(data)
	end,

	-- get table's real length
	get_tbl_len = function(tbl)
		if type(tbl) ~= 'table' then
			return 0
		end

		local cnt = 0
		for k, v in pairs(tbl) do
			cnt = cnt + 1
		end

		return cnt
	end,

	-- get error code
	get_error_code = function(self, err_key)
		if err_key ~= nil and self[err_key] ~= nil then
			return self[err_key]
		else
			tool.set_errlog(string.format("not find error key [%d], please check...", err_key))
			return self.ERROR_UNKOWN
		end
	end,


	-- get random string
	get_random_str = function(len)
		local str='abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz01234556789'
		math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))
		local rest = {}
		local pos = 0
		for i=1,len do
			pos = math.random(1, string.len(str))
			table.insert(rest, string.sub(str, pos, pos))
		end

		return table.concat(rest)
	end,


	-- send sms message
	-- telphone_num: target telephone number, split by ","
	send_sms_message = function(telphone_num, msg, temp_code, signature_name)
		local access_key_id = "LTAITb4XVreEnPRL"
		local access_key_secret = "Uz5JoLWpFkmWcbenZVYZr9s1XElhZX"
		local action = "SingleSendSms"
		local format = "JSON"
		local param_string = json.encode(msg)
		local rec_num = telphone_num
		local region_id = "cn-hangzhou"
		local sign_name = signature_name == nil and "达摩健康之旅" or signature_name
		local signature_method = "HMAC-SHA1"
		local signature_nonce = ngx.md5(os.clock())
		local signature_version = "1.0"
		local template_code = temp_code == nil and "SMS_32765156" or temp_code
		local timestamp = string.gsub(ngx.utctime(), "%s", "T") .. "Z"
		local version = "2016-09-27"
		
		local param_string = "AccessKeyId=" .. access_key_id .. "&" .. "Action=" .. action .. "&Format=" .. format .. "&ParamString=" ..
							 param_string .. "&RecNum=" .. rec_num .. "&RegionId=" .. region_id .. "&SignName=" .. sign_name .. "&SignatureMethod=" ..
							 signature_method .. "&SignatureNonce=" .. signature_nonce .. "&SignatureVersion=" .. signature_version .. "&TemplateCode=" ..
							 template_code .. "&Timestamp=" .. timestamp .."&Version=".. version
		local param_string1 = string.gsub(param_string, "([^-_.~&=a-zA-Z0-9])", function(s) return ngx.escape_uri(s) end)
		local param_string_escape = ngx.escape_uri(param_string1)
		--param_string_escape = string.gsub(string.gsub(string.gsub(param_string_escape, "+", "%20"), "*", "%2A"), "%7E", "~")
		param_string_escape = string.gsub(param_string_escape, "%+", "%20")
		param_string_escape = string.gsub(param_string_escape, "%*", "%2A")
		param_string_escape = string.gsub(param_string_escape, "%%7E", "~")
		param_string_escape = string.gsub(param_string_escape, ",", "%%252C")
		local string_2_sign = "POST" .. "&" .. ngx.escape_uri("/") ..  "&" ..  param_string_escape
		--ngx.say(string_2_sign)

		local signature = ngx.escape_uri(ngx.encode_base64(ngx.hmac_sha1(access_key_secret .. "&", string_2_sign)))

		local http = require("resty.http")
		local httpc = http.new()
		local res, err = httpc:request_uri("http://sms.aliyuncs.com/", {
			method = "POST",
			body = "Signature=" .. signature .. "&" .. param_string,
			headers = {
				["Content-Type"] = "application/x-www-form-urlencoded",
			}
		})
		--ngx.say("Signature=" .. signature .. "&" .. param_string)
		return res, err
	end,

	-- send email
	-- @not work
	send_email=function(from, to, subject, content, config)
		local smtp = require("socket.smtp")
		local ret = 0

		local mesgt = {
			headers = {
				to = type(to) == "table" and table.concat(to, ",") or to,
				subject = subject,
				['content-type'] = 'text/html; charset="utf-8"'
			},
			body = content
		}
		
		local r,e = smtp . send{
			from = from,
			rcpt = to,
			source = smtp.message(mesgt),
			server = config.server,
			user = config.user,
			password = config.password
		} 

		if not r then 
			ngx.log(ngx.ERR, "faild send email, message: ", e)
		end

		return r
	end,
	test_send_email = function()
		local smtp = require("socket.smtp")
		from = "<zili.qi@chivox.com>" --发件人
		--发送列表
		rcpt = {
			"<908020645@qq.com>",
			"<490038366@qq.com>"
		}
		mesgt = {
			headers = {
				to = "<908020645@qq.com>", --收件人
				subject = "This is Mail Title" --主题
			},
			body = "This is Mail Content."
		}
		r, e = smtp.send{
			from = from,
			rcpt = rcpt,
			source = smtp.message(mesgt),
			server = "smtp.qiye.163.com",
			user = "zili.qi@chivox.com",
			password = "QZLy901107"
		}
		if not r then
			ngx.say(e)
		else
			ngx.say("send ok!")
		end
	end

}

return tool
