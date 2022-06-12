-- This can run voxel scripts.

local parser = require "src.voxel" -- full library of terms.
local host = {}

function host:interpret(src)
	return src
end

return host
