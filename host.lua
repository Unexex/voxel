-- This can run Delta scripts.

local parser = require "src.parser"
local generate = require "src.generator"
local host = {}

local function CopyFile(old_path, new_path)
	local old_file = io.open(old_path)
	local new_file = io.open(new_path, "w")
	if not old_file or not new_file then
	  return false
	end
	while true do
	  local block = old_file:read(2^13)
	  if not block then break end
	  new_file:write(block)
	end
	old_file:close()
	new_file:close()
	return true
end

local function loadLibraries(src,path)
	local add = "\n \n"
	CopyFile("src.delta", path..".delta")
	for i, v in pairs(require("src.delta")) do
		add = "var "..i.." = ".."= require(\"delta\")."..i.."\n"..add
	end
	
	return add..src
end

function host.lang:lua(src, path)
	src = loadLibraries(src, path)
	local ast = parser.parse(src)

	ast.navigateTree(nil,nil,false)
	ast.navigateTree(nil,nil,true)

	if next(ast.tree.errors) then
		for _,e in pairs(ast.tree.errors) do
			error(e.msg)
		end
	end

	local new_src = generate.code(ast.tree,true)
	return new_src
end

function host:interpret(src)
	return loadstring(host.lang:lua(src, path))
end


return host
