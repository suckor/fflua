local core = require "core.core"
local rep = core.rep
local req = core.req
local json = require "cjson"
local auth = require "api.auth"
local err = core.err
local tool = core.tool
local mysql = core.mysql

local _M = {}

_M.add = function()
	local args = req.get_args("post")
	local cid = nil

	if not args or not args['access_token'] or not args['order_info'] then
		rep.set(err.format("ERROR_PARAMS"))
		return false
	end

	local user_info = auth.user_info(args['access_token'])

	if not user_info then
		return false
	end
	
	local order_info
	local st, errinfo = pcall(function(str) order_info = json.decode(str) end, args['order_info'])
	
	if not st then 
		rep.set(err.format("ERROR_PARAMS"))
		return false
	end
	
	local  tourist_list = ""

	local sql = ""
	if order_info.lv_list == "" and #order_info.lv_info > 0 then
		for k, v in pairs(order_info.lv_info) do
			sql = "insert into dm_user_frequent_contacts(user_id, zh_name, pp_en_name_1, pp_en_name_2, pp_number, pp_expire_date, nationality, birthday, sex, insert_time) values"
			sql = sql .. "(" .. user_info['id'] .. ","
			sql = sql .. tool.trans_data(order_info.lv_info[k]['zh_name']) .. "," 
			sql = sql .. tool.trans_data(order_info.lv_info[k]['pp_en_name_1']) .. "," 
			sql = sql .. tool.trans_data(order_info.lv_info[k]['pp_en_name_2']) .. "," 
			sql = sql .. tool.trans_data(order_info.lv_info[k]['pp_number']) .. "," 
			sql = sql .. tool.trans_data(order_info.lv_info[k]['pp_expire_date']) .. "," 
			sql = sql .. tool.trans_data(order_info.lv_info[k]['nationality']) .. "," 
			sql = sql .. tool.trans_data(order_info.lv_info[k]['birthday']) .. "," 
			sql = sql .. tool.trans_data(order_info.lv_info[k]['sex']) .. "," 
			sql = sql ..  "now())" 
			local res = mysql . query(mysql.wdb(), sql)

			if res['affected_rows'] > 0 then
				tourist_list = tourist_list .. res['insert_id'] .. ","
			end
		end

		tourist_list = string.sub(tourist_list, 1, -2)
	elseif string.find(order_info.lv_list, "%d+") then
		for v in string.gmatch(order_info.lv_list, "%d+") do
			tourist_list = tourist_list .. v .. ","
		end
		tourist_list = string.sub(tourist_list, 1, -2)
	end

	local address_id
	if tonumber(order_info.is_need_receipt) == 1 then
		if order_info.address_id == "" then
			sql = "insert into dm_user_addresses(user_id, addressee, telephone, province_id, city_id, address_detail, is_default, insert_time) values(" 
			sql = sql .. user_info['id'] .. "," 
			sql = sql .. tool.trans_data(order_info.address.addressee) .. "," 
			sql = sql .. tool.trans_data(order_info.address.telephone) .. "," 
			sql = sql .. tool.trans_data(order_info.address.province_id) .. "," 
			sql = sql .. tool.trans_data(order_info.address.city_id) .. "," 
			sql = sql .. tool.trans_data(order_info.address.address_detail) .. "," 
			sql = sql .. "1, now())"

			local res = mysql . query(mysql.wdb(), sql)
			if res['affected_rows'] > 0 then
				address_id = res['insert_id']
			end
		else
			address_id = tonumber(order_info.address_id)
		end
	end
	local oid = ngx.md5(core.conf.md5_str..user_info['id'] .. ngx.time()) .. tool . get_random_str(6)
	local parmas = {
		user_id = user_info['id'],
		oid = oid,
		dcid = tonumber(order_info.dcid),
		contact_user_name = order_info.contact_user_name,
		contact_telephone = order_info.contact_telephone,
		contact_email = order_info.contact_email,
		adult_num = order_info.adult_num,
		children_num = order_info.children_num,
		tourist_list = tourist_list,
		discount1 = tonumber(order_info.discount1),
		is_need_receipt = order_info.is_need_receipt,
		receipt_type = order_info.receipt_type,
		receipt_head_type = order_info.receipt_head_type,
		receipt_head = order_info.receipt_head,
		user_address_id = address_id,
		start_date = order_info.begindate,
		end_date = order_info.enddate,
		hotel_type = order_info.lodge_type,
		total_price = tonumber(order_info.total_price),
		status = 0,
		insert_time=os.date("%Y-%m-%d %H:%M:%S")
	}
	local res = mysql.insert(mysql.wdb(), "dm_orders", parmas)
	local ret = {}
	if res and res['affected_rows'] > 0 then
		local r = mysql.select(mysql.wdb(), "*", "dm_orders", "", {id=res['insert_id'], user_id=user_info['id']}, "1")
		if r and #r > 0 then
			ret.order_id = r[1]['oid']
			ret.total_price = r[1]['total_price']
			ret.adult_num = r[1]['adult_num']
			ret.children_num = r[1]['children_num']
			ret.start_date = r[1]['start_date']

			local re = mysql.select(mysql.rdb(), "title", "dm_deepcheck_details", "", {id=tonumber(order_info.dcid)})
			if re and #re > 0 then
				ret.dc_title = re[1]['title']
			end
		end
	end
	rep.set(err.format("ERROR_OK", ret))

end


return _M
