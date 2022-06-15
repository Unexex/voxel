local P = {}   -- package
--namespace
local _REQUIREDNAME = tostring(...)
if _REQUIREDNAME == nil then
     set = P
else
     _G[_REQUIREDNAME] = P
end

-- dependencies:
local math          = require "math"
local table         = require "table"
local os            = os
local print         = print
local next          = next
local tostring      = tostring
local setmetatable  = setmetatable
local getmetatable  = getmetatable
local error         = error

-- Set the environment to the package, no more external access (hence the previous section)
local _ENV = P

-- Any global variables are part of the package, any local variables are private
local mt = {}


function new(t)
     --takes an array and returns a set
     local newSet = {}
     for i, v in next, t do
          newSet[v] = true
     end
     setmetatable( newSet, mt )
     return newSet
end


function mt:__tostring()
     local str = "{"
     local sep = ""
     for e in self:elements() do
          str = tostring(str) .. sep .. e
          sep = ", "
     end
     return str.."}"
end

mt.__index = {}
local ind = mt.__index

function ind:elements() --iterator
     return    function(t, key)
                    key = next(t, key)
                    return key
               end, self
end

function ind:union( other )
     local newSet = {}
     for e in self:elements() do
          table.insert( newSet, e )
     end
     for e in other:elements() do
          table.insert( newSet, e )
     end
     return new( newSet )
end

function ind:intersection( other )
     local newSet = {}
     for e in self:elements() do
          if other[e] then
               table.insert( newSet, e )
          end
     end
     return new( newSet )
end

function ind:difference( other )
     local newSet = {}
     for e in self:elements() do
          if not other[e] then
               table.insert( newSet, e )
          end
     end
     return new( newSet )
end

return P