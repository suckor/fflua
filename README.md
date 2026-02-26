# fflua

A lightweight RESTful API framework for OpenResty based on Lua.

## Overview

fflua is a simple yet powerful web framework designed for building RESTful APIs with OpenResty. It provides a clean architecture with modular components for database operations, authentication, routing, and request/response handling.

## Features

- **RESTful API Design** - Clean routing system for REST endpoints
- **MySQL Support** - Read/write separation with connection pooling
- **Redis Integration** - Caching and session management
- **Token-based Authentication** - JWT-like access token system
- **Modular Architecture** - Separation of concerns with core, comm, and api layers
- **Error Handling** - Centralized error code management
- **Logging** - Built-in logging with multiple levels
- **File Upload** - Support for file upload handling

## Project Structure

```
fflua/
├── api/                  # API endpoint handlers
│   ├── auth.lua          # Authentication logic
│   ├── deepcheck.lua     # Deepcheck API
│   ├── index.lua         # Index/home API
│   ├── init.lua          # API initialization & config
│   ├── order.lua         # Order management API
│   └── user.lua          # User management API
├── comm/                 # Common modules
│   ├── conf.lua          # Configuration (DB, Redis, Routes)
│   └── error.lua         # Error codes and messages
├── core/                 # Core framework components
│   ├── core.lua          # Core module aggregator
│   ├── log.lua           # Logging utility
│   ├── mysql.lua         # MySQL database operations
│   ├── redis.lua         # Redis operations
│   ├── request.lua       # Request handling
│   ├── response.lua      # Response formatting
│   ├── route.lua         # URL routing
│   └── tool.lua          # Utility functions
├── content.lua           # Application entry point
├── log.lua               # Log flush handler
└── rewrite.lua           # URL rewrite rules
```

## Requirements

- [OpenResty](https://openresty.org/) (Nginx + LuaJIT)
- MySQL 5.7+
- Redis 3.0+
- lua-resty-mysql
- lua-resty-redis
- lua-cjson

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url> fflua
   cd fflua
   ```

2. Install OpenResty dependencies:
   ```bash
   # Using luarocks
   luarocks install lua-resty-mysql
   luarocks install lua-resty-redis
   luarocks install lua-cjson
   ```

3. Configure your environment (see Configuration section)

## Configuration

Edit `comm/conf.lua` to configure your environment:

```lua
local config = {
    md5_str = "your_secret_key",
    mysql = {
        write = {
            host = "127.0.0.1",
            port = 3306,
            database = "your_database",
            user = "your_user",
            password = "your_password",
            max_packet_size = 1024 * 1024
        },
        read = {
            {
                host = "127.0.0.1",
                port = 3306,
                database = "your_database",
                user = "your_user",
                password = "your_password",
                max_packet_size = 1024 * 1024
            }
        }
    },
    redis = {
        {
            host = "127.0.0.1",
            port = 6379,
            requirepass = "your_redis_password"
        }
    },
    route = {
        {"/user/login", "api.user", "login"},
        {"/user/register", "api.user", "register"},
        -- Add more routes here
    }
}
```

## OpenResty Configuration

Add the following to your `nginx.conf`:

```nginx
http {
    lua_package_path "/path/to/fflua/?.lua;;";
    
    server {
        listen 80;
        server_name your_domain.com;
        
        location / {
            content_by_lua_file /path/to/fflua/content.lua;
            log_by_lua_file /path/to/fflua/log.lua;
        }
    }
}
```

## Usage

### Creating a New API Endpoint

1. **Add route** in `comm/conf.lua`:
   ```lua
   {"/api/endpoint", "api.your_module", "method_name"}
   ```

2. **Create handler** in `api/your_module.lua`:
   ```lua
   local core = require "core.core"
   local rep = core.rep
   local req = core.req
   local err = core.err
   
   local _M = {}
   
   _M.method_name = function()
       local args = req.get_args("post")
       -- Your logic here
       rep.set(err.format("ERROR_OK", {data = result}))
   end
   
   return _M
   ```

### Database Operations

```lua
local mysql = require "core.mysql"

-- Get write database connection
local wdb = mysql.wdb()
mysql.query(wdb, "INSERT INTO table (col) VALUES ('val')")

-- Get read database connection
local rdb = mysql.rdb()
local result = mysql.select(rdb, "*", "table_name", "", {id = 1})
```

### Redis Operations

```lua
local redis = require "core.redis"

local red = redis.redis()
red:set("key", "value")
local val = red:get("key")
redis.close(red, 1)  -- 1 = keepalive
```

### Authentication

```lua
local auth = require "api.auth"

-- Generate token
local token = auth._access_token(user_id)

-- Validate token
local valid = auth.valid(token)

-- Get user info from token
local user_info = auth.user_info(token)
```

## API Response Format

All responses follow a consistent JSON format:

```json
{
    "err_id": 0,
    "msg": "成功",
    "info": {
        // Response data here
    },
    "runtime": 0.00123
}
```

## Error Codes

Defined in `comm/error.lua`:

| Error ID | Code | Description |
|----------|------|-------------|
| 0 | ERROR_OK | Success |
| 10000 | ERROR_SERVER | Server error |
| 10001 | ERROR_SERVER_URL_NOT_EXIST | URL not found |
| 20001 | ERROR_EMPTY_USERNAME_PASSWORD | Empty credentials |
| 20002 | ERROR_USERNAME_PASSWORD_NOT_MATCH | Invalid credentials |
| 20007 | ERROR_ACCESS_TOKEN_EXPIRED | Token expired |
| ... | ... | See `comm/error.lua` for full list |

## Logging

The framework supports multiple log levels:

```lua
local log = require "core.log"

log.set(log.DEBUG, "Debug message")
log.set(log.INFO, "Info message")
log.set(log.WARNING, "Warning message")
log.set(log.ERROR, "Error message")
```

## License

See [LICENSE](LICENSE) file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request
