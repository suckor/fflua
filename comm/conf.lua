local config = {
	md5_str = "helloworld",
	mysql = {
		write = {
			host = "127.0.0.1",
			port = 3306,
			database = "test",
			user = "root",
			password = "123456",
			max_packet_size = 1024 * 1024
		},
		read = {
			{
				host = "127.0.0.1",
				port = 3306,
				database = "test",
				user = "root",
				password = "123456",
				max_packet_size = 1024 * 1024
			}
		}
	},
	redis = {
		{
			host = "127.0.0.1",
			port = 6379,
			requirepass = "123456"
		}
	},
	route = {
		{"/user/login", "api.user", "login"},
		{"/user/register", "api.user", "register"},
		{"/user/update", "api.user", "update"},
		{"/user/upload", "api.user", "upload"},
		{"/user/check_telphone", "api.user", "check_telphone"},
		{"/user/check_telphone_check_code", "api.user", "check_telphone_check_code"},
		{"/user/register_by_telphone", "api.user", "register_by_telphone"},
		{"/user/send_telphone_check_code", "api.user", "send_telphone_check_code"},
		{"/user/login_by_telphone", "api.user", "login_by_telphone"},
		{"/user/userinfo_by_token", "api.user", "userinfo_by_token"},
		{"/user/create_plan", "api.user", "create_plan"},
		{"/user/check_token", "api.user", "check_token"},
		{"/user/edit_contact", "api.user", "edit_frequent_contacts"},
		{"/user/del_contact", "api.user", "del_frequent_contacts"},
		{"/user/get_contacts", "api.user", "get_frequent_contacts"},
		{"/user/get_addresses", "api.user", "get_addresses"},
		{"/user/del_address", "api.user", "del_address"},
		{"/user/edit_address", "api.user", "edit_address"},
		{"/user/set_default_address", "api.user", "set_default_address"},
		{"/index/get", "api.index", "get_info"},
		{"/deepcheck/get", "api.deepcheck", "info"},
		{"/deepcheck/list", "api.deepcheck", "list"},
		{"/deepcheck/recommend", "api.deepcheck", "recommend"},
		{"/staff/get_index_list","api.staff","get_index_list"},
		{"/order/add", "api.order", "add"},
	},
	
	email_template = {
		plan_create = {
			server = "smtp.sina.com",
			user = "test123@sina.com",
			password = "123456",
			port = 25,
			to = {"<908020645@qq.com>", "<chenyi@cla-technology.com>"},
			subject = "[达摩健康] 新的定制游",
			body = "<h3>定制详情：</h3>" .. 
				"<p>检查内容：$check_cnt <br /> 地区：$address <br /> 人数：$person_num <br /> 出发日期：$go_date <br /> 天数：$day_num </p>" ..
				"<h3>联系人信息：</h3>" ..
				"<p>手机号：$order_telphone <br /> 姓名：$order_name <br /> 微信：$order_weixin <br /> 备注：$order_comment</p>" ..
				"<h3>预约人信息：</h3>" ..
				"<p>手机号：$user_telphone <br /> 用户名：$user_name <br /> 昵称：$user_nickname</p>"
		}
	}
}


return config
