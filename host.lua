-- This can run Delta scripts.


require 'lxsh'
local parser = require "src.parser"
local generate = require "src.generator"
local host = {}

function host:lua(src)
	local ast = parser.parse(src)

	ast.navigateTree(nil,nil,false) -- run through the tree and inserts symbols / recovers from error 
	ast.navigateTree(nil,nil,true) -- run through the tree again just to show modified tree.

	-- Semantic error (undeclared things)
	if next(ast.tree.errors) then
		for _,e in pairs(ast.tree.errors) do
			error(e.msg)
		end
	end

	local new_src = generate.code(ast.tree,true)
	return new_src
end

function host:interpret(src)
	loadstring(host:lua()) -- lol what did you expect me to do, I will add bytecode soon.
end

return host
