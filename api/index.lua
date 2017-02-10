local core = require "core.core"
local mysql = core.mysql
local rep = core.rep
local err = core.err

local _M = {}

_M.get_index_header_covers = function()
	local rdb = mysql.rdb()
	local res = mysql.query(rdb, "select * from dm_home_shortcut where position=0 order by insert_time desc limit 5")
	local info = {}

	if type(res) == "table" and #res > 0 then
		for i, row in ipairs(res) do
			table.insert(info, {image_path=row['image_path'], target_url=row['target_url'], title=row['title']})
		end
	end

	return info
end

_M.get_index_middle_covers = function()
	local rdb = mysql . rdb()
	local res = mysql.query(rdb, "select * from dm_home_shortcut where position=1 order by sort_by asc, insert_time desc limit 10")
	local info = {}

	if type(res) == "table" and #res > 0 then
		for i, row in ipairs(res) do
			table.insert(info, {image_path=row['image_path'], target_url=row['target_url'], title=row['title']})
		end
	end

	return info
end


-----------------------  APIS  ----------------------------------

_M.get_info = function()
	local ret ={}
	ret.header_cover_list = _M.get_index_header_covers()
	ret.middle_cover_list = _M.get_index_middle_covers()

	rep.set(err.format("ERROR_OK", ret))
end

return _M
