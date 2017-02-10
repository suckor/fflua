local _M = {}

----- require core modules -----

_M.log		= require("core.log")

_M.mysql	= require("core.mysql")

_M.redis	= require("core.redis")

_M.req		= require("core.request")

_M.rep		= require("core.response")

_M.route	= require("core.route")

_M.tool		= require("core.tool")


----- require comm modules -----

_M.conf		= require("comm.conf")

_M.err		= require("comm.error")



return _M
