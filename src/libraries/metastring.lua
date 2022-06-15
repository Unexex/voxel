require( "lib.stdlib" )
local mt = getmetatable( "" )
mt.__index = function( t, k )
	check( t, 1, "string" )
	check( k, 2, "string", "number" )
	if string[k] then
		return string[k]
	else
		return string.sub( t, k, k )
	end
end
mt.__mul = function( t, rep )
	check( t, 1, "string" )
	check( rep, 2, "number" )
	return t:rep( rep )
end
mt.__add = function( t, cat )
	check( t, 1, "string" )
	check( cat, 2, "string" )
	return t .. cat
end
mt.__mod = function( t, formats )
	check( t, 1, "string" )
	check( formats, 2, "string", "number", "table" )
	if type( formats ) == "table" then
		local k, err = pcall( string.format, t, unpack( formats ) )
		if k then
			return err
		else
			return error( err, 2 )
		end
	else
		local k, err = pcall( string.format, t, formats )
		if k then
			return err
		else
			return error( err, 2 )
		end
	end
end
function string:escape()
	check( self, 1, "string" )
	return self:gsub( "[%^%$%(%)%%%.%[%]%*%+%-%?]", function( c ) return "%" .. c end )
end

return string