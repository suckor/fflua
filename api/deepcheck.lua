local mysql = require "core.mysql"
local req = require "core.request"
local rep = require "core.response"
local init = require "api.init"
local err = require "comm.error"

local _M = {}
_M._get_deepcheck_info = function(id)
	local ret ={}

	local rdb = mysql.rdb()
	if not id then
		return ret
	end

	local res = mysql.select(rdb, "dm_deepcheck_details.*, dm_deepcheck_hotals.details as hotal_details", 
						"dm_deepcheck_details", 
						"left join dm_deepcheck_hotals on dm_deepcheck_hotals.id = dm_deepcheck_details.hotal_id", 
						{['dm_deepcheck_details.id']=tonumber(id)}, "1")

	if type(res) == "table" and #res > 0 then
		ret = res[1]
		
		-- get trip list
		if type(res[1]['trip_list']) == "string" and string.find(res[1]['trip_list'], "%d+")  then
			local typs = "("
			for v in string.gmatch(res[1]['trip_list'], "%d+") do
				typs = typs .. v .. ","
			end
			local field = "field(id," .. string.sub(typs, 2, -2) .. ")"
			typs = string.sub(typs, 1, -2) .. ")"
			
			local r = mysql.query(mysql.rdb(), "select * from dm_deepcheck_days where id in " .. typs .. " order by ".. field)

			ret['trip_info'] = {}
			if type(r) == "table" and #r > 0 then
				ret['trip_info'] = r
			end
		end

		-- get play_types
		ret['play_type'] = {}
		local r = mysql.query(mysql.rdb(), "select * from dm_deepcheck_playtype where dcid=" .. id .. " order by update_time")
		if type(r) == "table" and #r > 0 then
			for i,v in ipairs(r) do
				v['play_type'] = tostring(v['play_type'])
				if init.deepcheck_tags.play_type[v['play_type']] then
					table.insert(ret['play_type'], {id=v['play_type'], init.deepcheck_tags.play_type[v['play_type']]})
				end
			end
		end
		-- get tags info
		if type(init.deepcheck_tags) == "table" then
			ret['day_type_id'] = ret['day_type']
			ret['check_type_id'] = ret['check_type']
			ret['play_path_id'] = ret['play_path']
			ret['day_type'] = tostring(ret['day_type'])
			ret['check_type'] = tostring(ret['check_type'])
			ret['play_path'] = tostring(ret['play_path'])
			ret['day_type'] = init.deepcheck_tags.day_type[ret['day_type']] and init.deepcheck_tags.day_type[ret['day_type']] or ''
			ret['check_type'] = init.deepcheck_tags.check_type[ret['check_type']] and init.deepcheck_tags.check_type[ret['check_type']] or ''
			ret['play_path'] = init.deepcheck_tags.play_path[ret['play_path']] and init.deepcheck_tags.play_path[ret['play_path']] or ''
		end
	end

	return ret
end


_M._list = function(day_type, check_type, play_path, play_type, p, num_per_page)
	
	local rdb = mysql . rdb()
	local ret = {total_page=0, cur_page=p}
	local sql = "select dm_deepcheck_details.id, dm_deepcheck_details.location, dm_deepcheck_details.title, dm_deepcheck_details.price, dm_deepcheck_details.cover_path " ..
				"from dm_deepcheck_details"
	local total_sql = "select count(*) as num from dm_deepcheck_details"
	
	local where = " where 1=1 "
	local join = ""
	local groupby = " group by dm_deepcheck_details.id order by dm_deepcheck_details.insert_time"
	local limit = " limit ".. (p-1)*num_per_page .. ", " .. num_per_page

	if type(play_type) == "string" and string.find(play_type, "%d+") then
		local typs = "( "
		for v in string.gmatch(play_type, "%d+") do
			typs = typs .. v .. ','
		end
		typs = string.sub(typs, 1, -2) .. " )"
		
		join = join .. " left join dm_deepcheck_playtype on dm_deepcheck_playtype.dcid = dm_deepcheck_details.id"
		where = where .. " and play_type in " .. typs
	end

	if type(day_type) == "number" and day_type ~= 0 then
		where = where .. " and day_type = " .. day_type
	end

	if type(play_path) == "number" and play_path ~= 0 then
		where = where .. " and play_path = " .. play_path
	end

	if type(check_type) == "number" and check_type ~= 0 then
		where = where .. " and check_type = " .. check_type
	end

	sql = sql .. join .. where .. groupby .. limit

	local res = mysql.query(rdb, sql)

	if res and #res > 0 then
		ret.items = res
	end

	total_sql = total_sql .. join .. where .. groupby 
	res = mysql.query(mysql.rdb(), total_sql)
	if res and #res > 0 then
		ret.total_page = math.ceil(res[1]['num']/num_per_page)
		ret.cur_page = p < ret.total_page and p or ret.total_page
	end

	return ret
	
end

_M._tags = function()
	return init.deepcheck_tags
end

_M._recommend = function(access_token)
	if access_token then
		
	end
	
	local res = mysql.query(mysql.rdb(), "select id, title, location, price, order_num, cover_path from dm_deepcheck_details order by insert_time desc limit 10")

	if type(res) == "table" and #res > 0 then
		return res
	end

	return nil
end
---------------------------------------  APIS  -----------------------------------------

_M.info = function()
	local args = req.get_args('post')
	local id = args and args['id'] or nil

	local ret = {}
	ret.product = _M._get_deepcheck_info(id)

	rep.set(err.format("ERROR_OK", ret))
end

_M.list = function()
	local args = req.get_args('post')
	local day_type = args and tonumber(args['day_type']) or 0
	local check_type = args and tonumber(args['check_type']) or 0
	local play_path = args and tonumber(args['play_path']) or 0
	local play_type = args and args['play_type'] or nil
	local p = args and tonumber(args['p']) or 1
	local num_per_page = args and tonumber(args['num_per_page']) or 18

	if type(p) ~= "number" or p < 1 then p = 1 end
	if type(num_per_page) ~= "number" or num_per_page < 1 then num_per_page = 18 end

	local ret = {}
	ret.list = _M._list(day_type, check_type, play_path, play_type, p, num_per_page)
	ret.tags = _M._tags()

	rep.set(err.format("ERROR_OK", ret))
end

_M.recommend = function()
	local args = req.get_args('post')
	local access_token = args and args['access_token'] or nil

	local ret = _M._recommend(access_token)
	
	rep.set = rep.set(err.format("ERROR_OK", ret))

	return true
end


--_M.product_like = function()
--	local args = req.get_args('post')
--	local id = args and args['id'] or nil
--
--	local ret = {}
--
--	if not _M._like(id, token) then
--		rep.set(err.format("ERROR_LIKE_FAILED"))
--	end
--end

return _M
