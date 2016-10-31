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

}

return tool
