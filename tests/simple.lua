function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
 end

local code = [[
    var x = 0;
    x = x + 1;
    if (x == 1) {
     print(x); -- should be 1
    }
]]

print(require("host").lang:lua(code, script_path())) -- to lua

-- response:
--[[
 local x = 0
 x = x + 1
 if (x == 1) then
    print(x)
 end
]]