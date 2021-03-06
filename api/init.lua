--  
--  config static attr 
--

local _M = {}

-- deepcheck tags list

_M.deepcheck_tags = {

	day_type = {
		['0'] = "全部",
		['3'] = "三天团",
		['4'] = "四天团",
		['5'] = "五天团",
		['6'] = "六天团",
	},
	check_type = {
		['0'] = "全部",
		['1'] = "深度防癌体检",
		['2'] = "胃镜检查",
		['3'] = "肠镜检查",
	},
	play_path = {
		['0'] = "全部",
		['1'] = "东京一地",
		['2'] = "东京+富士山",
		['3'] = "东京+箱根",
		['4'] = "东京+横滨",
		['5'] = "东京+伊豆热海",
		['6'] = "东京+迪士尼",
		['7'] = "东京+横滨+镰仓",
		['8'] = "东京+横滨+镰仓+富士山",
		['9'] = "东京+京都+大阪",
	},
	play_type = {
		['1'] = "时尚购物", 
		['2'] = "米其林体检", 
		['3'] = "富士观光", 
		['4'] = "自然养生", 
		['5'] = "温泉", 
		['6'] = "设计艺术", 
		['7'] = "迪士尼", 
		['8'] = "沿海风情", 
		['9'] = "宫崎骏", 
		['10'] = "茶道", 
		['11'] = "经典回顾", 
		['12'] = "日本传统", 
	}
}

_M.create_plan = {
	check_cnt = {
		['1'] = "深度癌症检查",
		['2'] = "胃肠镜检查",
	},
	address = {
		['1'] = "东京以及东京周边",
	}
}



return _M
