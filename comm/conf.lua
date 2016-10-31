local config = {
	md5_str = "damojiankang2016",
	mysql = {
		write = {
			host = "127.0.0.1",
			port = 3306,
			database = "kule",
			user = "root",
			password = "123456",
			max_packet_size = 1024 * 1024
		},
		read = {
			{
				host = "127.0.0.1",
				port = 3306,
				database = "kule",
				user = "root",
				password = "123456",
				max_packet_size = 1024 * 1024
			}
		}
	},
	route = {
		{"/user/login", "api.user", "login"},
		{"/user/register", "api.user", "register"},
		{"/user/update", "api.user", "update"},
	}
}


return config
