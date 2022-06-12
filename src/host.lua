-- This can run Delta scripts.

local parser = require "src.delta" -- full library of terms.
local host = {}

function host:interpret(src)
	return src
end

return host
