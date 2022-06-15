local P = {} -- package
--namespace
local _REQUIREDNAME = ...
if _REQUIREDNAME == nil then
     vector = P
else
     _G[_REQUIREDNAME] = P
end

-- read version.info
function Information(t)
     for i, v in next, t do
          local index = "_"..i:upper()
          P[ index ] = v
     end
end
local infoGot, errMsg = pcall(dofile, _REQUIREDNAME.."/version.info")
if infoGot then
     if not P["_LUA_VERSIONS"][ _VERSION ] then
          error( _REQUIREDNAME..(" library not compatable with current Lua version (%s)"):format(_VERSION), 2 )
     end
end

-- dependencies:
local math = {
      random        = math.random,
      randomseed    = math.randomseed,
      floor         = math.floor,
      sqrt          = math.sqrt,
      cos           = math.cos,
      sin           = math.sin,
      atan2         = math.atan2,
}
local unpack        = table.unpack or unpack
local time          = os.time
local print         = print
local format        = string.format
local ipairs        = ipairs
local type          = type
local setmetatable  = setmetatable
local getmetatable  = getmetatable
local error         = error
local setfenv       = setfenv

-- Set the environment to the package, no more external access (hence the previous section)
local _ENV
if setfenv then     --lua 5.1 compat
     setfenv(1, P)
else                --lua 5.2 and onward
     _ENV = P
end

-- random
math.randomseed( time() )

--error messages
local err = {
     badArg         = "bad argument #%d,",
     invalid        = "invalid vector",
     wrongDim       = "attempt to %s vectors of wrong dimension (%d)",
     outOfRange     = "%d is out of range (%d)",
     NAN            = "not a number",
     notInteger     = "%f is not a positive integer",
     vecNonVec      = "attempt to %s vector and non-vector",
     diffDim        = "attempt to %s vectors of different dimension (%d, %d)",
     nonNum         = "attempt to %s vector by non-number",
}

--local vars
local defaultDim = 3
local mt

local function isValidVector(t)
     if #t == 0 then return false end
     for i, v in ipairs(t) do
          if type(v) ~= "number" then
               return false, i
          end
     end
     return true
end

local function sameDim(v1, v2)
     return #v1 == #v2
end

local function checkMeta(a, b)
     return getmetatable(a) == getmetatable(b)
end

local function doubleipairs(a, b)
     local i = 0
     return    function()
                    i = i + 1
                    if not a[i] and not b[i] then
                         return nil
                    end
                    return i, a[i], b[i]
               end
end

local function isPosInteger(n)
     return (n == math.floor(n) and n > 0)
end

function new(...)
     local args = {...}
     if not args[1] then 
          for i = 1, defaultDim do
               args[i] = 0 
          end
     end
     local valid, badIndex = isValidVector(args)
     if valid then
          setmetatable( args, mt )
          return args
     else
          error( err.badArg:format(badIndex).." "..err.invalid, 2 )
     end
end

function random(d)
     --gives a random d dimensional unit vector
     d = d or getDefaultDim()
     if not isPosInteger(d) then
          error( err.badArg:format(1).." "..err.notInteger:format(d), 2 )
     end
     local newV = {}
     for i = 1, d do
          newV[i] = math.random() - 0.5
     end 
     return new( unpack(newV) ):normalize()
end

function getDefaultDim()
     return defaultDim
end

function setDefaultDim(n)
     if type(n) == "number" then
          if isPosInteger(n) then
               defaultDim = n
               return true
          end
     end
     error( err.badArg:format(1).." "..err.notInteger:format(n), 2 )
end

function e(n, dim)
     --returns the unit vector pointing in the positive nth dimension
     dim = dim or getDefaultDim()
     if not isPosInteger(dim) then
          error( err.badArg:format(2).." "..err.notInteger:format(dim), 2 )
     end
     if n > dim then
          error( err.badArg:format(1).." "..err.outOfRange:format(n, dim) , 2 )
     end
     local newV = {}
     for i = 1, dim do
          newV[i] = 0
     end
     newV[n] = 1
     return new( unpack( newV ) )
end

function numVec(n, d)
     --returns a d-dimensional vector with all entries equal to n
     if type(n) ~= "number" then
          error( err.badArg:format(1).." "..err.NAN, 2 )
     end
     d = d or getDefaultDim()
     if not isPosInteger(d) then
          error( err.badArg:format(2).." "..err.notInteger:format(d), 2 )
     end
     local newV = {}
     for i = 1, d do
          newV[i] = n
     end
     return new( unpack(newV) )
end

--metatable stuffs
mt = {}
do
     local new = new
     local _ENV
     if setfenv then
          setfenv(1, mt)
     else
          _ENV = mt
     end
     __metatable = "vector"
     function __add(self, other)
          if not checkMeta(self, other) then
               error( err.vecNonVec:format("__add"), 2 )
          elseif not sameDim(self, other) then
               error(   err.diffDim:format("__add", #self, #other), 2 )
          end
          local newV = {}
          for i, v1, v2 in doubleipairs(self, other) do
               newV[i] = v1 + v2
          end
          return new( unpack(newV) )
     end
     function __sub(self, other)
          if not checkMeta(self, other) then
               error( err.vecNonVec:format("__sub"), 2 )
          elseif not sameDim(self, other) then
               error(   err.diffDim:format("__sub", #self, #other), 2 )
          end
          local newV = {}
          for i, v1, v2 in doubleipairs(self, other) do
               newV[i] = v1 - v2
          end
          return new( unpack(newV) )
     end
     function __mul(self, other)
          --other must be a number
          if getmetatable(self) ~= mt.__metatable and getmetatable(other) == mt.__metatable then
               self, other = other, self
          end
          if getmetatable(self) == mt.__metatable and type(other) ~= "number" then
               error( err.nonNum:format("__mul"), 2 )
          end
          local newV = {}
          for i, v in ipairs(self) do
               newV[i] = v * other
          end
          return new( unpack(newV) )
     end
     function __div(self, other)
          --other must be a number
          if getmetatable(self) == mt.__metatable and type(other) ~= "number" then
               error( err.nonNum:format("__div"), 2 )
          elseif getmetatable(self) ~= mt.__metatable then
               error("attempt to __div "..type(self).." by vector", 2)
          end
          local newV = {}
          for i, v in ipairs(self) do
               newV[i] = v / other
          end
          return new( unpack(newV) )
     end
     function __unm(self)
          local newV = {}
          for i, v in ipairs(self) do
               newV[i] = -v
          end
          return new( unpack(newV) )
     end
     function __eq(self, other)
          for i, v1, v2 in doubleipairs(self, other) do
               if v1 ~= v2 then
                    return false
               end
          end
          return true
     end
     function __tostring(self)
          local str = "<"
          local sep = ""
          for i, v in ipairs(self) do
               str = str .. sep .. v
               sep = ", "
          end
          return str..">"
     end
     __index = {}
     do
          local _ENV
          if setfenv then
               setfenv(1, __index)
          else
               _ENV = __index
          end
          function dot(self, other)
               if not checkMeta(self, other) then
                    error( err.vecNonVec:format("dot"), 2 )
               elseif not sameDim(self, other) then
                    error( err.diffDim:format("dot", #self, #other), 2 )
               end
               local sum = 0
               for i, selfVal, otherVal in doubleipairs(self, other) do
                    sum = sum + selfVal * otherVal
               end
               return sum
          end
          function cross(self, other)
               if not checkMeta(self, other) then
                    error( err.vecNonVec:format("cross"), 2 )
               elseif not sameDim(self, other) then
                    error( err.diffDim:format("cross", #self, #other), 2 )
               elseif not #self == 3 then
                    error( err.wrongDim:format("cross", #self), 2 )
               end
               return    new(
                              self[2] * other[3] - self[3] * other[2],
                              self[3] * other[1] - self[1] * other[3],
                              self[1] * other[2] - self[2] * other[1]
                         )
          end
          function magnitude(self)
               return math.sqrt( self:dot(self) )
          end
          norm = magnitude
          function normalize(self)
               return self / self:magnitude()
          end
          function distance(self, other)
               if not checkMeta(self, other) then
                    error( err.vecNonVec:format("distance"), 2 )
               elseif not sameDim(self, other) then
                    error( err.diffDim:format("distance", #self, #other), 2 )
               end
               local sum = 0
               for i, v1, v2 in doubleipairs(self, other) do
                    sum = sum + (v1-v2)^2
               end
               return math.sqrt( sum )
          end
          function decimalPlaces(self, places)
               places = places or 2 --decimal places
               newV = {}
               for i, v in ipairs(self) do
                    newV[i] = math.floor(v * (10^places) ) / (10^places)
               end
               return new( unpack(newV) )
          end
          function floor(self)
               newV = {}
               for i, v in ipairs(self) do
                    newV[i] = math.floor(v)
               end
               return new( unpack(newV) )
          end
          function round(self)
               newV = {}
               for i, v in ipairs(self) do
                    newV[i] = math.floor( v + 0.5 )
               end
               return new( unpack(newV) )    
          end
          function applyMatrix( self, matrix )
               -- n x m matrix, m must be equal to #self
               -- #matrix = rows, #matrix[1] = columns
               if #matrix[1] ~= #self then
                    error( "wrong matrix size", 2 )
               end
               -- convert each row of matrix into a vector, then dot it with self to get new vector entry
               local newV = {}
               for i, v in ipairs( matrix ) do -- for each row in matrix
                    v = new( unpack(v) )
                    newV[i] = self:dot(v)
               end
               return new( unpack(newV) )
          end
          function rotate3D( self, angle, axis )
               local u = axis:normalize()
               return u*(u:dot(self)) + (math.cos(angle)*(u:cross(self))):cross(u) + math.sin(angle)*(u:cross(self))
          end
     end
end



return P