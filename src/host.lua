-- This can run Delta scripts.

local parser = require "src.parser"
local generate = require "src.generator"
local host = {}

function host:interpret(src)
	return src
end

return host
