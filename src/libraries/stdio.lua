--[[
	stdio.lua, automatically gets added to the script.
]]
-------------------------------------------------------------------------
local function isWindows()
	return type(package) == 'table' and type(package.config) == 'string' and package.config:sub(1,1) == '\\'
  end
  
  local supported = not isWindows()
  if isWindows() then supported = os.getenv("ANSICON") end
  
  local keys = {
	-- reset
	reset =      0,
  
	-- misc
	bright     = 1,
	dim        = 2,
	underline  = 4,
	blink      = 5,
	reverse    = 7,
	hidden     = 8,
  
	-- foreground colors
	black     = 30,
	red       = 31,
	green     = 32,
	yellow    = 33,
	blue      = 34,
	magenta   = 35,
	cyan      = 36,
	white     = 37,
  
	-- background colors
	blackbg   = 40,
	redbg     = 41,
	greenbg   = 42,
	yellowbg  = 43,
	bluebg    = 44,
	magentabg = 45,
	cyanbg    = 46,
	whitebg   = 47
  }
  
  local escapeString = string.char(27) .. '[%dm'
  local function escapeNumber(number)
	return escapeString:format(number)
  end
  
  local function escapeKeys(str)
  
	if not supported then return "" end
  
	local buffer = {}
	local number
	for word in str:gmatch("%w+") do
	  number = keys[word]
	  assert(number, "Unknown key: " .. word)
	  table.insert(buffer, escapeNumber(number) )
	end
  
	return table.concat(buffer)
  end
  
  local function replaceCodes(str)
	str = string.gsub(str,"(%%{(.-)})", function(_, str) return escapeKeys(str) end )
	return str
  end
  
  -- public
  
  local function ansicolors( str )
	str = tostring(str or '')
  
	return replaceCodes('%{reset}' .. str .. '%{reset}')
  end
  
  
 printc =  function(text)
	local get = setmetatable({noReset = replaceCodes}, {__call = function (_, str) return ansicolors (str) end}) -- 
	print(get(text))
 end

local flux = { _version = "0.1.5" }
flux.__index = flux

flux.tweens = {}
flux.easing = { linear = function(p) return p end }

local easing = {
  quad    = "p * p",
  cubic   = "p * p * p",
  quart   = "p * p * p * p",
  quint   = "p * p * p * p * p",
  expo    = "2 ^ (10 * (p - 1))",
  sine    = "-math.cos(p * (math.pi * .5)) + 1",
  circ    = "-(math.sqrt(1 - (p * p)) - 1)",
  back    = "p * p * (2.7 * p - 1.7)",
  elastic = "-(2^(10 * (p - 1)) * math.sin((p - 1.075) * (math.pi * 2) / .3))"
}

local makefunc = function(str, expr)
  local load = loadstring or load
  return load("return function(p) " .. str:gsub("%$e", expr) .. " end")()
end

for k, v in pairs(easing) do
  flux.easing[k .. "in"] = makefunc("return $e", v)
  flux.easing[k .. "out"] = makefunc([[
    p = 1 - p
    return 1 - ($e)
  ]], v)
  flux.easing[k .. "inout"] = makefunc([[
    p = p * 2
    if p < 1 then
      return .5 * ($e)
    else
      p = 2 - p
      return .5 * (1 - ($e)) + .5
    end
  ]], v)
end



local tween = {}
tween.__index = tween

local function makefsetter(field)
  return function(self, x)
    local mt = getmetatable(x)
    if type(x) ~= "function" and not (mt and mt.__call) then
      error("expected function or callable", 2)
    end
    local old = self[field]
    self[field] = old and function() old() x() end or x
    return self
  end
end

local function makesetter(field, checkfn, errmsg)
  return function(self, x)
    if checkfn and not checkfn(x) then
      error(errmsg:gsub("%$x", tostring(x)), 2)
    end
    self[field] = x
    return self
  end
end

tween.ease  = makesetter("_ease",
                         function(x) return flux.easing[x] end,
                         "bad easing type '$x'")
tween.delay = makesetter("_delay",
                         function(x) return type(x) == "number" end,
                         "bad delay time; expected number")
tween.onstart     = makefsetter("_onstart")
tween.onupdate    = makefsetter("_onupdate")
tween.oncomplete  = makefsetter("_oncomplete")


function tween.new(obj, time, vars)
  local self = setmetatable({}, tween)
  self.obj = obj
  self.rate = time > 0 and 1 / time or 0
  self.progress = time > 0 and 0 or 1
  self._delay = 0
  self._ease = "quadout"
  self.vars = {}
  for k, v in pairs(vars) do
    if type(v) ~= "number" then
      error("bad value for key '" .. k .. "'; expected number")
    end
    self.vars[k] = v
  end
  return self
end


function tween:init()
  for k, v in pairs(self.vars) do
    local x = self.obj[k]
    if type(x) ~= "number" then
      error("bad value on object key '" .. k .. "'; expected number")
    end
    self.vars[k] = { start = x, diff = v - x }
  end
  self.inited = true
end


function tween:after(...)
  local t
  if select("#", ...) == 2 then
    t = tween.new(self.obj, ...)
  else
    t = tween.new(...)
  end
  t.parent = self.parent
  self:oncomplete(function() flux.add(self.parent, t) end)
  return t
end


function tween:stop()
  flux.remove(self.parent, self)
end



function flux.group()
  return setmetatable({}, flux)
end


function flux:to(obj, time, vars)
  return flux.add(self, tween.new(obj, time, vars))
end


function flux:update(deltatime)
  for i = #self, 1, -1 do
    local t = self[i]
    if t._delay > 0 then
      t._delay = t._delay - deltatime
    else
      if not t.inited then
        flux.clear(self, t.obj, t.vars)
        t:init()
      end
      if t._onstart then
        t._onstart()
        t._onstart = nil
      end
      t.progress = t.progress + t.rate * deltatime
      local p = t.progress
      local x = p >= 1 and 1 or flux.easing[t._ease](p)
      for k, v in pairs(t.vars) do
        t.obj[k] = v.start + x * v.diff
      end
      if t._onupdate then t._onupdate() end
      if p >= 1 then
        flux.remove(self, i)
        if t._oncomplete then t._oncomplete() end
      end
    end
  end
end


function flux:clear(obj, vars)
  for t in pairs(self[obj]) do
    if t.inited then
      for k in pairs(vars) do t.vars[k] = nil end
    end
  end
end


function flux:add(tween)
  -- Add to object table, create table if it does not exist
  local obj = tween.obj
  self[obj] = self[obj] or {}
  self[obj][tween] = true
  -- Add to array
  table.insert(self, tween)
  tween.parent = self
  return tween
end


function flux:remove(x)
  if type(x) == "number" then
    -- Remove from object table, destroy table if it is empty
    local obj = self[x].obj
    self[obj][self[x]] = nil
    if not next(self[obj]) then self[obj] = nil end
    -- Remove from array
    self[x] = self[#self]
    return table.remove(self)
  end
  for i, v in ipairs(self) do
    if v == x then
      return flux.remove(self, i)
    end
  end
end



local bound = {
  to      = function(...) return flux.to(flux.tweens, ...) end,
  update  = function(...) return flux.update(flux.tweens, ...) end,
  remove  = function(...) return flux.remove(flux.tweens, ...) end,
}
setmetatable(bound, flux)
-- Functions
local middleclass = {
	_VERSION     = 'middleclass v4.1.1',
	_DESCRIPTION = 'Object Orientation for Lua',
	_URL         = 'https://github.com/kikito/middleclass',
	_LICENSE     = [[
	  MIT LICENSE
  
	  Copyright (c) 2011 Enrique García Cota
  
	  Permission is hereby granted, free of charge, to any person obtaining a
	  copy of this software and associated documentation files (the
	  "Software"), to deal in the Software without restriction, including
	  without limitation the rights to use, copy, modify, merge, publish,
	  distribute, sublicense, and/or sell copies of the Software, and to
	  permit persons to whom the Software is furnished to do so, subject to
	  the following conditions:
  
	  The above copyright notice and this permission notice shall be included
	  in all copies or substantial portions of the Software.
  
	  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
	  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
	  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
	  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
	  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
	]]
  }
  
  local function _createIndexWrapper(aClass, f)
	if f == nil then
	  return aClass.__instanceDict
	elseif type(f) == "function" then
	  return function(self, name)
		local value = aClass.__instanceDict[name]
  
		if value ~= nil then
		  return value
		else
		  return (f(self, name))
		end
	  end
	else -- if  type(f) == "table" then
	  return function(self, name)
		local value = aClass.__instanceDict[name]
  
		if value ~= nil then
		  return value
		else
		  return f[name]
		end
	  end
	end
  end
  
  local function _propagateInstanceMethod(aClass, name, f)
	f = name == "__index" and _createIndexWrapper(aClass, f) or f
	aClass.__instanceDict[name] = f
  
	for subclass in pairs(aClass.subclasses) do
	  if rawget(subclass.__declaredMethods, name) == nil then
		_propagateInstanceMethod(subclass, name, f)
	  end
	end
  end
  
  local function _declareInstanceMethod(aClass, name, f)
	aClass.__declaredMethods[name] = f
  
	if f == nil and aClass.super then
	  f = aClass.super.__instanceDict[name]
	end
  
	_propagateInstanceMethod(aClass, name, f)
  end
  
  local function _tostring(self) return "class " .. self.name end
  local function _call(self, ...) return self:new(...) end
  
  local function _createClass(name, super)
	local dict = {}
	dict.__index = dict
  
	local aClass = { name = name, super = super, static = {},
					 __instanceDict = dict, __declaredMethods = {},
					 subclasses = setmetatable({}, {__mode='k'})  }
  
	if super then
	  setmetatable(aClass.static, {
		__index = function(_,k)
		  local result = rawget(dict,k)
		  if result == nil then
			return super.static[k]
		  end
		  return result
		end
	  })
	else
	  setmetatable(aClass.static, { __index = function(_,k) return rawget(dict,k) end })
	end
  
	setmetatable(aClass, { __index = aClass.static, __tostring = _tostring,
						   __call = _call, __newindex = _declareInstanceMethod })
  
	return aClass
  end
  
  local function _includeMixin(aClass, mixin)
	assert(type(mixin) == 'table', "mixin must be a table")
  
	for name,method in pairs(mixin) do
	  if name ~= "included" and name ~= "static" then aClass[name] = method end
	end
  
	for name,method in pairs(mixin.static or {}) do
	  aClass.static[name] = method
	end
  
	if type(mixin.included)=="function" then mixin:included(aClass) end
	return aClass
  end
  
  local DefaultMixin = {
	__tostring   = function(self) return "instance of " .. tostring(self.class) end,
  
	initialize   = function(self, ...) end,
  
	isInstanceOf = function(self, aClass)
	  return type(aClass) == 'table'
		 and type(self) == 'table'
		 and (self.class == aClass
			  or type(self.class) == 'table'
			  and type(self.class.isSubclassOf) == 'function'
			  and self.class:isSubclassOf(aClass))
	end,
  
	static = {
	  allocate = function(self)
		assert(type(self) == 'table', "Make sure that you are using 'Class:allocate' instead of 'Class.allocate'")
		return setmetatable({ class = self }, self.__instanceDict)
	  end,
  
	  new = function(self, ...)
		assert(type(self) == 'table', "Make sure that you are using 'Class:new' instead of 'Class.new'")
		local instance = self:allocate()
		instance:initialize(...)
		return instance
	  end,
  
	  subclass = function(self, name)
		assert(type(self) == 'table', "Make sure that you are using 'Class:subclass' instead of 'Class.subclass'")
		assert(type(name) == "string", "You must provide a name(string) for your class")
  
		local subclass = _createClass(name, self)
  
		for methodName, f in pairs(self.__instanceDict) do
		  if not (methodName == "__index" and type(f) == "table") then
			_propagateInstanceMethod(subclass, methodName, f)
		  end
		end
		subclass.initialize = function(instance, ...) return self.initialize(instance, ...) end
  
		self.subclasses[subclass] = true
		self:subclassed(subclass)
  
		return subclass
	  end,
  
	  subclassed = function(self, other) end,
  
	  isSubclassOf = function(self, other)
		return type(other)      == 'table' and
			   type(self.super) == 'table' and
			   ( self.super == other or self.super:isSubclassOf(other) )
	  end,
  
	  include = function(self, ...)
		assert(type(self) == 'table', "Make sure you that you are using 'Class:include' instead of 'Class.include'")
		for _,mixin in ipairs({...}) do _includeMixin(self, mixin) end
		return self
	  end
	}
  }
  
  function middleclass.class(name, super)
	assert(type(name) == 'string', "A name (string) is needed for the new class")
	return super and super:subclass(name) or _includeMixin(_createClass(name), DefaultMixin)
  end
  
  setmetatable(middleclass, { __call = function(_, ...) return middleclass.class(...) end })


local perlin = {}
perlin.p = {}

-- Hash lookup table as defined by Ken Perlin
-- This is a randomly arranged array of all numbers from 0-255 inclusive
local permutation = {151,160,137,91,90,15,
  131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
  190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
  88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
  77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
  102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
  135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
  5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
  223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
  129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
  251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
  49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
  138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
}

-- p is used to hash unit cube coordinates to [0, 255]
for i=0,255 do
    -- Convert to 0 based index table
    perlin.p[i] = permutation[i+1]
    -- Repeat the array to avoid buffer overflow in hash function
    perlin.p[i+256] = permutation[i+1]
end

-- Return range: [-1, 1]
function perlin:noise(x, y, z)
    y = y or 0
    z = z or 0

    -- Calculate the "unit cube" that the point asked will be located in
    local xi = bit32.band(math.floor(x),255)
    local yi = bit32.band(math.floor(y),255)
    local zi = bit32.band(math.floor(z),255)

    -- Next we calculate the location (from 0 to 1) in that cube
    x = x - math.floor(x)
    y = y - math.floor(y)
    z = z - math.floor(z)

    -- We also fade the location to smooth the result
    local u = self.fade(x)
    local v = self.fade(y)
    local w = self.fade(z)

    -- Hash all 8 unit cube coordinates surrounding input coordinate
    local p = self.p
    local A, AA, AB, AAA, ABA, AAB, ABB, B, BA, BB, BAA, BBA, BAB, BBB
    A   = p[xi  ] + yi
    AA  = p[A   ] + zi
    AB  = p[A+1 ] + zi
    AAA = p[ AA ]
    ABA = p[ AB ]
    AAB = p[ AA+1 ]
    ABB = p[ AB+1 ]

    B   = p[xi+1] + yi
    BA  = p[B   ] + zi
    BB  = p[B+1 ] + zi
    BAA = p[ BA ]
    BBA = p[ BB ]
    BAB = p[ BA+1 ]
    BBB = p[ BB+1 ]

    -- Take the weighted average between all 8 unit cube coordinates
    return self.lerp(w,
        self.lerp(v,
            self.lerp(u,
                self:grad(AAA,x,y,z),
                self:grad(BAA,x-1,y,z)
            ),
            self.lerp(u,
                self:grad(ABA,x,y-1,z),
                self:grad(BBA,x-1,y-1,z)
            )
        ),
        self.lerp(v,
            self.lerp(u,
                self:grad(AAB,x,y,z-1), self:grad(BAB,x-1,y,z-1)
            ),
            self.lerp(u,
                self:grad(ABB,x,y-1,z-1), self:grad(BBB,x-1,y-1,z-1)
            )
        )
    )
end

-- Gradient function finds dot product between pseudorandom gradient vector
-- and the vector from input coordinate to a unit cube vertex
perlin.dot_product = {
    [0x0]=function(x,y,z) return  x + y end,
    [0x1]=function(x,y,z) return -x + y end,
    [0x2]=function(x,y,z) return  x - y end,
    [0x3]=function(x,y,z) return -x - y end,
    [0x4]=function(x,y,z) return  x + z end,
    [0x5]=function(x,y,z) return -x + z end,
    [0x6]=function(x,y,z) return  x - z end,
    [0x7]=function(x,y,z) return -x - z end,
    [0x8]=function(x,y,z) return  y + z end,
    [0x9]=function(x,y,z) return -y + z end,
    [0xA]=function(x,y,z) return  y - z end,
    [0xB]=function(x,y,z) return -y - z end,
    [0xC]=function(x,y,z) return  y + x end,
    [0xD]=function(x,y,z) return -y + z end,
    [0xE]=function(x,y,z) return  y - x end,
    [0xF]=function(x,y,z) return -y - z end
}
function perlin:grad(hash, x, y, z)
    return self.dot_product[bit32.band(hash,0xF)](x,y,z)
end

-- Fade function is used to smooth final output
function perlin.fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

function perlin.lerp(t, a, b)
    return a + t * (b - a)
end

local String = {}

function String.startsWith(obj,lookingFor,caseSensitive)
	if caseSensitive then
		return tostring(obj):match("^"..lookingFor) and true or false
	elseif not caseSensitive then
		return tostring(obj:lower()):match("^"..lookingFor:lower()) and true or false
	end
end

function String.endsWith(obj,lookingFor,caseSensitive)
	if caseSensitive then
		return tostring(obj):match(lookingFor.."$") and true or false
	elseif not caseSensitive then
		return tostring(obj:lower()):match(lookingFor:lower().."$") and true or false
	end
end

function String.includes(obj,lookingFor,caseSensitive)
	if caseSensitive then
		return tostring(obj):find(lookingFor:lower()) and true or false
	elseif not caseSensitive then
		return tostring(obj:lower()):find(lookingFor:lower()) and true or false
	end
end


function String.titleCase(obj,optExempt)
	local exempt = {"and", "or", "of"}
	local customExempt = optExempt:split(":")
	for index,valueExempt in pairs(customExempt) do
		table.insert(exempt,valueExempt:lower())
	end
	local sentence = {}
	for word in obj:gmatch("%w+") do
		if table.find(exempt,word:lower()) then
			table.insert(sentence,word:lower())
		end
		local start, rest = word:sub(1,1), word:sub(2)
		table.insert(sentence,start:upper()..rest:lower())
	end
	return table.concat(sentence, " ")
end

function String.reverseCase(obj)
	local split = obj:split("")
	local newObj = {}
	for index,value in pairs(split) do
		if value:match("%l") then
			table.insert(newObj,value:upper())
		elseif value:match("%u") then
			table.insert(newObj,value:lower())
		end
	end
	return table.concat(newObj,"")
end

local Table = {}
Table.__index = Table

--[[
    Utilities
--]]

--- Returns a string containing all of the elements within an array separated by `glue`.
---
--- @param array table The table to implode.
--- @param glue string The string to separate each value with.
--- @return string result A string containing all of the elements within an array separated by `glue`.
function Table.Implode(array, glue)
	-- Set a default value for `glue`.
	if not glue then glue = "," end
	
	local arrayString = ""
	
	-- Iterate through each value in the array and concatenate them to the string
	for index, value in pairs(array) do
		arrayString = arrayString .. tostring(value)

		-- If this is not the last index in the array
		if index ~= #array then
			arrayString = arrayString .. glue
		end
	end
	
	return arrayString
end

--- Returns a boolean indicating whether or not the table is an array.
--- An array is defined as a table containing positive integer indexes.
---
--- @param array table The table to evaluate.
--- @return boolean isArray Whether or not the table is an array.
function Table.IsArray(array)
	-- Return false if the table is nil
	if typeof(array) ~= "table" then
		return false
	end

	-- Make sure the table is not empty
	if next(array) == nil then
		return false
	end

	-- Make sure that all keys are positive integers
	for key, value in pairs(array) do
		if typeof(key) ~= "number" or key % 1 ~= 0 or key < 1 then
			return false
		end
	end

	return true
end

--- Returns a boolean indicating whether or not the table is a dictionary.
--- A dictionary is defined as a table containing keys that are not positive integers.
---
--- @param array table The table to evaluate.
--- @return boolean isDictionary Whether or not the table is a dictionary.
function Table.IsDictionary(array)
	return typeof(array) == "table" and not Table.IsEmpty(array) and not Table.IsArray(array)
end

--- Returns a boolean indicating whether or not the table is empty.
---
--- @param array table The table to evaluate.
--- @return boolean isEmpty Whether or not the table is empty.
function Table.IsEmpty(array)
	return type(array) == "table" and next(array) == nil
end

--- Returns the number of elements that exist within a table. Works on all tables, including dictionaries.
---
--- @param array table The table whose length to return.
--- @return number length The number of elements that exist within a table.
function Table.Length(array)
	return #Table.Values(array)
end

--- Returns a mapped version of a table based on the values returned by `callback` for each element in the array.
---
--- The callback will be passed `value`, and `key` from the key/value pairs within the table.
---
--- @param array table The table to map.
--- @param callback function The callback function that determines the mapped value of table elements.
--- @return table results A table containing the mapped table elements.
function Table.Map(array, callback)
	local results = {}

	-- Iterate through the array and set each key/value pair to the result of calling `callback()` on them
	for key, value in pairs(array) do
		results[key] = callback(value, key)
	end

	return results
end

--[[
	Getters
--]]

--- Returns a deep copy of the table.
---
--- @param array table The table to deep copy.
--- @return table copy A deep copy of the origin table.
function Table.Clone(array)
	-- Create a new array with memory allocated for the size we know it will be
	local result = Table.Create(#array)

	-- Iterate through each value of the original array and add them to the new array
	for key, value in pairs(array) do
		-- If the value is a table, call `Table.clone()` on that as well, to make it a deep copy.
		if type(value) == "table" then
			value = Table.Clone(value)
		end

		result[key] = value
	end

	return result
end

--- Collapses a table consisting of multiple tables into a single table.
---
--- @param array table The table to collapse.
--- @return table
function Table.Collapse(array)
	return Table.Merge(unpack(array))
end

--- Divides a table into two arrays: one containing the keys, one containing the values.
---
--- @param array table The table whose keys and values should be returned as separate arrays.
--- @return table keys An array containing the table's keys.
--- @return table values An array containing the table's values.
function Table.Divide(array)
	return Table.Keys(array), Table.Values(array)
end

--- Returns a boolean indicating whether or not the array has the requested key.
---
--- @param array table The table to search.
--- @param key any The key to search for within the array.
--- @return boolean
function Table.Has(array, key)
	return array[key] ~= nil
end

--- Returns a boolean indicating whether or not the array has any of the requested keys.
---
--- @param array table The table whose keys to evaluate.
--- @param keys table An array of keys to search for within the table.
--- @return boolean
function Table.HasAny(array, keys)
	for index, value in ipairs(keys) do
		if Table.Has(array, value) then
			return true
		end
	end
end

--- Returns all of the keys within a table.
---
--- @param array table The table whose keys to return.
--- @return table
function Table.Keys(array)
	local keys = {}

	for key in pairs(array) do
		table.insert(keys, key)
	end

	return keys
end

--- Merges the elements one or more tables together. Number indexes will be appended to the new array, receiving a new index.
--- Non-number indexes will be retained, and will overwritten by values from later tables with the same property.
---
--- Accepts a list of tables as arguments.
---
--- @return table
function Table.Merge(...)
	local arguments = {...}
	local results = {}
	
	for tableIndex, array in pairs(arguments) do
		for key, value in pairs(array) do
			if typeof(key) == "number" then
				table.insert(results, value)
			else
				results[key] = value
			end
		end
	end

	return results
end

--- Returns a random value from the table. Also returns the selected key.
---
--- @param array table The table from which to select a random value.
--- @return any value A random value from the table.
--- @return any key The randomly selected key from the table.
function Table.Random(array)
	local keys = Table.Keys(array)
	
	local randomGenerator = Random.new()
	local randomKey = keys[randomGenerator:NextInteger(1, #keys)]
	return array[randomKey], randomKey
end

--- Returns a reversed version of `array`.
---
--- @param array table The table to reverse.
--- @return table
function Table.Reverse(array)
	local result = table.create(#array)
	local reverseIterator = #array

	for iterator = 1, #array do
		result[reverseIterator] = array[iterator]
		reverseIterator = reverseIterator - 1
	end

	return result
end

--- Returns a shuffled copy of `array`.
---
--- @param array table The table to shuffle.
--- @return table result The shuffled table.
function Table.Shuffle(array)
	local result = Table.Clone(array)

	for i = #result, 2, -1 do
		local randomGenerator = Random.new()
		local randomIndex = math.random(randomGenerator:NextInteger(1, i))
		result[i], result[randomIndex] = result[randomIndex], result[i]
	end

	return result
end

--- Returns all of the values within a table.
---
--- @param array table The table whose values to return.
--- @return table
function Table.Values(array)
	local values = {}

	for key, value in pairs(array) do
		table.insert(values, value)
	end

	return values
end

--[[
	Mutators
	--
	These methods alter the original table.
--]]

--- Adds a property to a table if it does not already exist.
---
--- @param array table The table to alter.
--- @param key any The key to assign to.
--- @param value any The value to assign to array[key]
--- @return table
function Table.Add(array, key, value)
	if not array[key] then
		array[key] = value
	end

	return array
end

--- Returns the value of `key` in `array` and removes it from `array`.
--- @param array table The table to pull from.
--- @param key any The key to pull from the table.
--- @return any value The value pulled from `array[key]`
function Table.Pull(array, key)
	local value = array[key]
	array[key] = nil
	return value
end

--[[
	Filters
	--
	These methods return filtered tables without impacting the original table.
--]]

--- Returns a filtered version of `array` ommitting the blacklisted properties.
---
--- @param array table The table.
--- @param blacklist table An array of keys to omit from the results.
--- @return table results The table without blacklisted properties.
function Table.Except(array, blacklist)
	local results = Table.Clone(array)

	for index, value in ipairs(blacklist) do
		results[value] = nil
	end

	return results
end

--- Returns a filtered version of a table containing elements for which `callback` returns a truthy value.
---
--- The callback will be passed `value`, and `key` from the key/value pairs within the table.
---
--- @param array table The table to filter.
--- @param callback function A callback function that determines whether or not an element should be filtered.
--- @return table results A table containing the filtered table elements.
function Table.Filter(array, callback)
	local results = {}

	for key, value in pairs(array) do
		if callback(value, key) then
			results[key] = value
		end
	end

	return results
end

--- Returns the first value in the table for which `callback` returns `true`.
--- @param array table The table to evaluate.
--- @param callback function The callback.
--- @return any first The first value in the array for which `callback` returns `true`.
function Table.First(array, callback)
	for key, value in pairs(array) do
		if callback(value) then
			return value
		end
	end
end

--- Returns the last value in the table for which `callback` returns `true`.
--- @param array table The table to evaluate.
--- @param callback function The callback.
--- @return any first The last value in the array for which `callback` returns `true`.
function Table.Last(array, callback)
	return Table.First(Table.Reverse(array), callback)
end

--- Returns a table containing only the whitelisted keys from `array`.
---
--- @param array table The table to search.
--- @param whitelist table An array of keys from the original array to whitelist.
--- @return table results A table only containing whitelisted key/pair values from `array`.
function Table.Only(array, whitelist)
	local results = {}

	for index, arrayKey in ipairs(whitelist) do
		local arrayValue = array[arrayKey]
		if arrayValue then
			results[arrayKey] = arrayValue
		end
	end

	return results
end

--- Returns the values associated with the indexes between array[offset] and array[offset + length] in a new array.
---
--- @param array table The origin table.
--- @param offset number The array index to begin with.
--- @param length number The number of indexes that should be selected.
--- @return table
function Table.Slice(array, offset, length)
	local results = {}

	for index = offset or 1, length or #array do
		table.insert(results, array[index])
	end

	return results
end

--[[
	Wrapper Methods
	--
	These methods are simply wrappers over the standard `table` liibrary.
	
	While they are provided here in order to provide a consistent API for interacting with tables, it is usually
	adviseable to use the `table` library directly for better performance.
--]]

--- Returns a string resulting from concatenating all of the values within this array.
--- Only works on arrays. Use `Table.implode()` for support for dictionaries as well.
---
--- @param array table The table to concatenate.
--- @param separator string? The string to concatenate between array elements.
--- @param beginIndex number The first element in the table to concatenate.
--- @param lastIndex number The last element in the table to concatenate.
--- @return string
function Table.Concat(array, separator, beginIndex, lastIndex)
	return table.concat(array, separator, beginIndex, lastIndex)
end

--- Creates an array sized for `count` elements. Populated by `value` if set.
---
--- @param count number The number of elements to size the array for.
--- @param value any The value to optionally populate the array with `count` times.
--- @return table
function Table.Create(count, value)
	return table.create(count, value)
end

--- Returns the key of the first occurence of `needle` in the array `haystack` after `haystack[init]`.
---
--- @param haystack table The table to search.
--- @param needle any The value to search for.
--- @param beginIndex number The index to begin searching at.
--- @return any
function Table.Find(haystack, needle, beginIndex)
	return table.find(haystack, needle, beginIndex)
end

--- Iterates through the provided table, calling `callback()` and passing the key/value for each element as arguments.
---
--- @param array table The table to iterate through.
--- @param callback function The function to call for each iteration.
function Table.ForEach(array, callback)
	return table.foreach(array, callback)
end

--- Iterates through the provided array, calling `callback()` and passing the index/value for each element as arguments.
--- Basically the same as `Table.foreach()` except uses `ipairs()` instead of `pairs()` for the iteration.
---
--- @param array table The table to iterate through.
--- @param callback function The function to call for each iteration.
function Table.ForEachIPairs(array, callback)
	return table.foreachi(array, callback)
end

--- Returns the number of elements in the array passed. Will not work for dictionary tables, use `Table.length()` for that instead.
---
--- @param array table The table whose length to return.
--- @return number
function Table.GetN(array)
	return table.getn(array)
end

--- Appends `value` to `pos` or, if `pos` is empty, to the end of the array.
--- @param array table The table to append to.
--- @param pos number The position to append to. Defaults to `#array + 1`.
--- @param value any The value to append to the array.
function Table.Insert(array, pos, value)
	return table.insert(array, pos, value)
end

--- Moves elements from one table to another.
---
--- @param arrayOne table The first table.
--- @param firstIndex number The first index in `a1` to move elements from.
--- @param lastIndex number The last index in `a2` to move elements from.
--- @param insertIndex number The index to begin inserting elements from `a1` into `a2` at.
--- @param arrayTwo table The second table. Defaults to `a1`.
--- @return table
function Table.Move(arrayOne, firstIndex, lastIndex, insertIndex, arrayTwo)
	return table.move(arrayOne, firstIndex, lastIndex, insertIndex, arrayTwo)
end

--- Returns a new table with each argument as an element inside an array.
function Table.Pack(...)
	return table.pack(...)
end

--- Removes and returns an element from an array at the specified position.
---
--- @param array table The table to remove from.
--- @param pos number The position of the element to remove.
function Table.Remove(array, pos)
	return table.remove(array, pos)
end

--- Sorts elements in a table based on the return values of the callback.
---
--- The callback should return `true` when the first argument should come before
--- the second argument in the sorted table.
---
--- If a callback is not provided, the Lua operator `<` is used to compare elements.
---
--- @param array table The table to sort.
--- @param callback function The callback used to determine the sorting order.
function Table.Sort(array, callback)
	return table.sort(array, callback)
end

--- Returns the selected elements from the table `list`.
---
--- @param array table The table whose elements to return.
--- @param beginIndex number The starting index.
--- @param finalIndex number The final index to return.
--- @return Tuple
function Table.Unpack(array, beginIndex, finalIndex)
	return table.unpack(array, beginIndex, finalIndex)
end


local 	_type, setmetatable, getmetatable, select, ipairs, pairs,  tostring, error, assert, print, unpack, fmt = type, setmetatable, getmetatable, select, ipairs, pairs, tostring, error, assert, print, table.unpack, string.format

-- print(("%s %s %s"):match("%%"))

local have_debug, debug = pcall(require, 'debug')

_ENV = {}

local function get_ud_name(ud)
	if not have_debug then return "userdata" end

	local ud_mt = getmetatable(ud)
	local registry = debug.getregistry()
	for i, v in pairs(registry) do
		if v == ud_mt then
			return i
		end
	end
end
local type = setmetatable({}, {
	__call = function(t, ...)
		if  select("#", ...) == 1 then

			return _type(...)
		else
			return t.check(...)
		end

	end
})

local function normalize_to_type(...)

	if select("#", ...) ~= 0 then
		return _type((...), "type") and (...) or type.get((...)), normalize_to_type(select(2,...))
	else
		return nil
	end

end

type.types = setmetatable({}, {
	__mode = "v", 
	__type={types = 1, "types", table = true}}
)

local  type_mt = {
	__type = {type = 1, "type", table = true},
	__call = function(self, o)
		return type.cast(o, self)
	end,
	__tostring = function(self)
		return self[1]
	end,
	__eq = function(a,b)
		return type.eq(a,b)
	end,
	__lt = function(a, b)

		return type.le(a,b)
	end,
	__le = function(a, b)
		return  type.le(a,b)
	end
}

local types = type.types
function type.new(t)

	if _type(t) == "string" then
		t = {t}
	elseif _type(t) ~= "table" then
		error("Expected string or table of type names.") 
	end


	local new_type = {}

	for i,v in ipairs(t) do
		new_type[i] = v
		new_type[v] = i
	--	print("making",new_type[v],new_type[i])
	end


	--make a table entry, but don't index it.
	--that way #length points to how many types
	--are assigned to it, but not the obvious ones.
	--also, tables that are passed in can be done this way too.
	if t.table or t.table == nil and not t.userdata then -- default path
		new_type.table, new_type.userdata = true, false
	elseif t.userdata and not t.table then --userdata is true
		new_type.table, new_type.userdata = false, true
	elseif t.table and t.userdata then--
		error("A type can't be a table and a userdata value.")
	else --the specified it. probably t.table is false and so is userdata (native type.)
		new_type.table, new_type.userdata =  t.table, t.userdata
	end

	types[new_type[1]] = new_type

	return setmetatable(new_type, type_mt)

end
function type.get(o)
	local obj_type = _type(o)
	if obj_type == "table" then
		local o_mt =   getmetatable(o)
		return o_mt and o_mt.__type or types["table"]

	elseif have_debug and obj_type == "userdata" then
		local ud_name =  get_ud_name(o)
		if types[ud_name] then
			if not types[ud_name].userdata then
				error(fmt("Name clash! Previous type with the name '%s' was defined in userspace (not a metatable).", 
					ud_name),
				2)
			end 

			return types[ud_name]
		elseif ud_name then
			return type.new({ud_name, userdata = true, table = false})
		else
			return types.userdata --couldn't find it.
		end

	else
		return types[_type(o)] or error(fmt("Undefined type: %s",_type(o)), 2)
	end
end
function type.find(type_name)
	return types[type_name]
end

function type.check(...)

	local arg_len = select("#", ...) 

	if arg_len == 0 then
		return types.undefined[1], types.undefined[2]
	elseif arg_len == 1 then 
		return type.tostring((...))
	end

	local o_type = type.get((...))

	-- o is at one, so skip that. make i 2
	for i = 2, arg_len do
		local cur_search = (select(i , ...))
		if o_type[cur_search] then
				return o_type[1],  cur_search
		end
	end
	
	--didn't find it.
	return false

end



function type.tostring(o)
	return tostring(type.get(o))

end
function type.cast (o, new_type)

	if _type(o) ~= "table" then
		error("Expected a table as first argument to  type.cast. Received %s", _type(o) )
	end

	local o_mt = getmetatable(o) or {}

	--if a string is passed in, and that string is  an index of types,
	--then they want to cast an existing type.
	if _type(t) == "string" and types[new_type] then
		o_mt.__type =  types[new_type]

	--Maybe they're removing the type?
	elseif new_type == nil then
		o_mt.__type = nil
	--Are the placing an existing type?
	elseif type.check(new_type, "type") then
		o_mt.__type = new_type
	--Is it a new type?
	else
		o_mt.__type = type.new(new_type)
	end

	return setmetatable(o,  o_mt)
	
end


--this isn't right. if all of the types in a
--are found in b, then it should be true
--so type.le(a,b) and type.le(b, a)?
function type.eq(a, b)

	a, b = normalize_to_type(a, b)


	return  type.le(a,b) and type.le(b, a)

end
function type.lt(a,b)

	return type.le(a,b) and not type.le(b, a)
end

-- Does not return true for equality. Only less than.
local function assert_type(o)
	if not _type(o, "type") then
		error(fmt("Error: expected 'type' and received %s", type.tostring(o)),2)
	else
		return o
	end

end
function type.le(a, b)

	a,b = normalize_to_type(a,b)

	

	if a[1] == "table" or a[1] == "userdata" then
		return b[a[1]] and true or false
	--two complex types.
	else
		for i, v in ipairs(a) do
			if not b[v] then
	
				return false
			end
		end
		return true
	end
end

type.native = {
	type.new({"userdata", table = false, userdata = true}),
	type.new({"table", userdata = false}),
	type.new({"string", table = false}),
	type.new({"number", table = false}),

	type.new({"boolean", table = false}),
	type.new({"function", table = false}),
	type.new({"thread", table = false}),
	type.new({"nil", table = false}),
	type.new({"undefined", "nil", table = false})
}

local NIL = {} -- this value represents "nil" values inside "initial_config" table

-- Initial values of configurable parameters.
local initial_config = {
   -- To preserve module compatibility, don't modify anything in this table.
   -- In order to use modified configuration, create specific instance of "alert()" function:
   --   local alert = require("alert")(nil, {param_name_1=param_value_1, param_name_2=param_value_2, ...})

   -------------------------------------------------------
   -- Default values for omitted alert() arguments
   -------------------------------------------------------
   default_arg_text   = NIL,               -- [string] or [function returning a string]
   default_arg_title  = NIL,               -- [string] or [function returning a string]
   default_arg_colors = NIL,               -- [string] or [function returning a string]
   default_arg_wait                             = true,   -- [boolean]
   default_arg_admit_linebreak_inside_of_a_word = false,  -- [boolean]

   ------------------------------------------------------
   -- Parameters concerning to terminal window geometry
   ------------------------------------------------------
   enable_geometry_beautifier = true,                     -- [boolean]
   -- true:  set terminal window width and height, center the text in the window, break lines only at word boundaries
   -- false: never change size of terminal window, don't center text, don't move linebreaks in the text

   -- Terminal window size constraints:
   max_width  = 80,    -- [positive integers]
   max_height = 25,
   min_width  = 44,
   min_height = 15,

   always_use_maximum_size_of_terminal_window = false,    -- [boolean]
   -- false: geometry beautifier chooses nice-looking size from range (min_width..max_width)x(min_height..max_height)
   -- true:  geometry beautifier always sets terminal window size to constant dimensions (max_width)x(max_height)

   -- Desired number of unused rows and columns near window borders:
   horiz_padding = 4,    -- [non-negative integers]
   vert_padding = 2,

   ------------------------------------
   -- OS-specific behavior parameters
   ------------------------------------
   -- This parameter is applicable only for CYGWIN.
   always_use_cmd_exe_under_cygwin = false,               -- [boolean]
   -- false: when Cygwin/X is running, terminal emulators are being tried first, failed that CMD.EXE is used.
   -- true:  when Cygwin/X is running, CMD.EXE is always used (it opens faster, but has limited UTF-8 support).

   -- This parameter is applicable only for MacOSX.
   always_use_terminal_app_under_macosx = false,          -- [boolean]
   -- false: when XQuartz is running, *nix terminal emulators are being tried first, failed that Terminal.app is used.
   -- true:  when XQuartz is running, Terminal.app is always used.

   -- This parameter is applicable only for Windows and Wine.
   use_windows_native_encoding = false,                   -- [boolean]
   -- false: "text" and "title" arguments are handled as UTF-8 strings whenever possible
   --        (if they both are correct UTF-8 strings), otherwise native Windows ANSI codepage is assumed for both of them
   -- true:  "text" and "title" arguments are always interpreted as strings in native Windows ANSI codepage
   -- Please note that Windows ANSI codepage depends on current locale settings, it can be modified by user in
   -- "Windows Control Panel" -> "Regional and Language" -> "Language for non-Unicode Programs"

   -- This parameter is applicable for all systems except Windows and Wine.
   terminal = NIL,                                     -- [any key from "terminals" table]
   -- This parameter selects preferred terminal emulator, which will be given highest priority during auto-detection

}  -- end of table "initial_config"


-- This is the list of supported terminal emulators.
-- Feel free to add additional terminal emulators that must be here (and send your patch to the module's author).

local terminals = {
   -- Description of fields:
   --    priority                   optional  number    terminal emulators will be checked for being installed in order
   --                                                   from highest priority to lowest
   --    option_title               required  string    a command line option to set window title (for example, "--title")
   --    option_geometry            optional  string    a command line option to set width in columns and height in rows
   --    options_misc               optional  string    miscellaneous command line options for this terminal emulator
   --    only_8_colors              optional  boolean   if this terminal emulator can display only 8 colors instead of 16
   --    option_colors              optional  string    a command line option to set foreground and background colors
   --                                                   (if omitted, Esc-sequence will be used to set terminal colors)
   -- Next two fields are for terminal emulators:
   --    option_command             required  string    an option to provide a shell command to execute (for example, "-e")
   --    command_requires_quoting   required  boolean   should shell command be quoted in the command line?
   -- Next two fields are for native dialogs, such as "zenity":
   --    option_text                required  string    a command line option to pass user text to be displayed
   --    text_preprocessor          optional  function  text preprocessing function to implement escaping, etc.

   ["xfce4-terminal"] = {
      priority = -0,
      option_geometry = "--geometry=%dx%d", -- actual usage == string.format(option_geometry, my_columns, my_rows)
      option_title = "-T",                  -- actual usage == option_title..[[ 'My Title']]
      option_command = "-x",                -- actual usage == option_command..[[ command arguments]]
      command_requires_quoting = false,     -- if true then == option_command..[[ "command arguments"]]
      options_misc = "--disable-server --hide-menubar", -- other useful options
   },
   ["mlterm"] = {
      priority = -1,
      option_geometry = "-g %dx%d",         -- actual usage == string.format(option_geometry, my_columns, my_rows)
      option_title = "-T",                  -- actual usage == option_title..[[ 'My Title']]
      option_colors = "-f '%s' -b '%s'",    -- actual usage == string.format(option_colors, fg#RRGGBB, bg#RRGGBB)
      option_command = "-e",                -- actual usage == option_command..[[ command arguments]]
      command_requires_quoting = false,     -- if true then == option_command..[[ "command arguments"]]
      options_misc = "-O none",             -- other useful options
   },
   ["urxvt"] = {  -- rxvt-unicode
      priority = -2,
      option_geometry = "-g %dx%d",         -- actual usage == string.format(option_geometry, my_columns, my_rows)
      option_title = "-T",                  -- actual usage == option_title..[[ 'My Title']]
      option_colors = "-fg '%s' -bg '%s'",  -- actual usage == string.format(option_colors, fg#RRGGBB, bg#RRGGBB)
      option_command = "-e",                -- actual usage == option_command..[[ command arguments]]
      command_requires_quoting = false,     -- if true then == option_command..[[ "command arguments"]]
      options_misc = "-sr +sb",             -- other useful options
   },
   ["uxterm"] = {
      priority = -3,
      option_geometry = "-geometry %dx%d",  -- actual usage == string.format(option_geometry, my_columns, my_rows)
      option_title = "-T",                  -- actual usage == option_title..[[ 'My Title']]
      option_colors = "-fg '%s' -bg '%s'",  -- actual usage == string.format(option_colors, fg#RRGGBB, bg#RRGGBB)
      option_command = "-e",                -- actual usage == option_command..[[ command arguments]]
      command_requires_quoting = false,     -- if true then == option_command..[[ "command arguments"]]
   },
   ["xterm"] = {
      priority = -4,
      option_geometry = "-geometry %dx%d",  -- actual usage == string.format(option_geometry, my_columns, my_rows)
      option_title = "-T",                  -- actual usage == option_title..[[ 'My Title']]
      option_colors = "-fg '%s' -bg '%s'",  -- actual usage == string.format(option_colors, fg#RRGGBB, bg#RRGGBB)
      option_command = "-e",                -- actual usage == option_command..[[ command arguments]]
      command_requires_quoting = false,     -- if true then == option_command..[[ "command arguments"]]
   },
   ["lxterminal"] = {
      priority = -5,
      option_geometry = "--geometry=%dx%d", -- actual usage == string.format(option_geometry, my_columns, my_rows)
      option_title = "-t",                  -- actual usage == option_title..[[ 'My Title']]
      option_command = "-e",                -- actual usage == option_command..[[ command arguments]]
      command_requires_quoting = true,      -- if true then == option_command..[[ "command arguments"]]
   },
   ["gnome-terminal"] = {
      priority = -6,
      option_geometry = "--geometry=%dx%d", -- actual usage == string.format(option_geometry, my_columns, my_rows)
      option_title = "-t",                  -- actual usage == option_title..[[ 'My Title']]
      option_command = "-x",                -- actual usage == option_command..[[ command arguments]]
      command_requires_quoting = false,     -- if true then == option_command..[[ "command arguments"]]
      options_misc = "--disable-factory",   -- other useful options
   },
   ["mate-terminal"] = {
      priority = -7,
      option_geometry = "--geometry=%dx%d", -- actual usage == string.format(option_geometry, my_columns, my_rows)
      option_title = "-t",                  -- actual usage == option_title..[[ 'My Title']]
      option_command = "-x",                -- actual usage == option_command..[[ command arguments]]
      command_requires_quoting = false,     -- if true then == option_command..[[ "command arguments"]]
      options_misc = "--disable-factory",   -- other useful options
   },
   ["sakura"] = {
      priority = -8,
      option_geometry = "-c %d -r %d",      -- actual usage == string.format(option_geometry, my_columns, my_rows)
      option_title = "-t",                  -- actual usage == option_title..[[ 'My Title']]
      only_8_colors = true,                 -- this terminal emulator can display only 8 colors instead of 16
      option_command = "-e",                -- actual usage == option_command..[[ command arguments]]
      command_requires_quoting = true,      -- if true then == option_command..[[ "command arguments"]]
   },
   ["roxterm"] = {
      priority = -9,
      option_geometry = "--geometry=%dx%d", -- actual usage == string.format(option_geometry, my_columns, my_rows)
      option_title = "-T",                  -- actual usage == option_title..[[ 'My Title']]
      option_command = "-e",                -- actual usage == option_command..[[ command arguments]]
      command_requires_quoting = false,     -- if true then == option_command..[[ "command arguments"]]
      options_misc = "--hide-menubar --separate -n ' '", -- other useful options (how to hide tabbar?)
   },

   -- The following terminal emulators don't support UTF-8
   ["mrxvt"] = {
      priority = -100,
      option_geometry = "-g %dx%d",         -- actual usage == string.format(option_geometry, my_columns, my_rows)
      option_title = "-T",                  -- actual usage == option_title..[[ 'My Title']]
      option_colors = "-fg '%s' -bg '%s'",  -- actual usage == string.format(option_colors, fg#RRGGBB, bg#RRGGBB)
      option_command = "-e",                -- actual usage == option_command..[[ command arguments]]
      command_requires_quoting = false,     -- if true then == option_command..[[ "command arguments"]]
      options_misc = "+sb -aht +showmenu",  -- other useful options
   },
   ["rxvt"] = {
      priority = -101,
      option_geometry = "-g %dx%d",         -- actual usage == string.format(option_geometry, my_columns, my_rows)
      option_title = "-T",                  -- actual usage == option_title..[[ 'My Title']]
      option_colors = "-fg '%s' -bg '%s'",  -- actual usage == string.format(option_colors, fg#RRGGBB, bg#RRGGBB)
      option_command = "-e",                -- actual usage == option_command..[[ command arguments]]
      command_requires_quoting = false,     -- if true then == option_command..[[ "command arguments"]]
      options_misc = "-sr +sb",             -- other useful options
   },
   ["Eterm"] = {
      priority = -102,
      option_geometry = "-g %dx%d",         -- actual usage == string.format(option_geometry, my_columns, my_rows)
      option_title = "-T",                  -- actual usage == option_title..[[ 'My Title']]
      option_colors = "-f '%s' -b '%s'",    -- actual usage == string.format(option_colors, fg#RRGGBB, bg#RRGGBB)
      option_command = "-e",                -- actual usage == option_command..[[ command arguments]]
      command_requires_quoting = false,     -- if true then == option_command..[[ "command arguments"]]
      options_misc = "--scrollbar 0 -P ''", -- other useful options
   },
   ["aterm"] = {
      priority = -103,
      option_geometry = "-g %dx%d",         -- actual usage == string.format(option_geometry, my_columns, my_rows)
      option_title = "-T",                  -- actual usage == option_title..[[ 'My Title']]
      option_colors = "-fg '%s' -bg '%s'",  -- actual usage == string.format(option_colors, fg#RRGGBB, bg#RRGGBB)
      option_command = "-e",                -- actual usage == option_command..[[ command arguments]]
      command_requires_quoting = false,     -- if true then == option_command..[[ "command arguments"]]
      options_misc = "-sr +sb",             -- other useful options
   },
   ["xvt"] = {
      priority = -104,
      option_geometry = "-geometry %dx%d",  -- actual usage == string.format(option_geometry, my_columns, my_rows)
      option_title = "-T",                  -- actual usage == option_title..[[ 'My Title']]
      option_colors = "-fg '%s' -bg '%s'",  -- actual usage == string.format(option_colors, fg#RRGGBB, bg#RRGGBB)
      option_command = "-e",                -- actual usage == option_command..[[ command arguments]]
      command_requires_quoting = false,     -- if true then == option_command..[[ "command arguments"]]
   },

   -- the following terminal emulators do support UTF-8, but don't have an option to set its width and height in characters
   ["evilvte"] = {
      priority = -200,
      -- option_geometry =                  -- there is no way to set number of rows and columns for this terminal emulator
      option_title = "-T",                  -- actual usage == option_title..[[ 'My Title']]
      option_command = "-e",                -- actual usage == option_command..[[ command arguments]]
      command_requires_quoting = false,     -- if true then == option_command..[[ "command arguments"]]
   },
   ["konsole"] = {
      priority = -201,
      -- the following "option_geometry" should work but it doesn't
      -- (bugs.kde.org/show_bug.cgi?id=345403)
      -- option_geometry = "-p TerminalColumns=%d -p TerminalRows=%d",
      option_title = "--caption",           -- actual usage == option_title..[[ 'My Title']]
      -- konsole <-e> option has a problem: it expands all environment variables inside <-e command arguments>
      -- despite of protecting them with single quotes, so all $VARs in your text will be forcibly expanded
      -- (bugs.kde.org/show_bug.cgi?id=361835)
      option_command = "-e",                -- actual usage == option_command..[[ command arguments]]
      command_requires_quoting = false,     -- if true then == option_command..[[ "command arguments"]]
      options_misc = "--nofork --hide-tabbar --hide-menubar -p ScrollBarPosition=2",  -- other useful options
   },

   -- native dialogs (they don't have ability to set background color, so colors are not used)
   ["zenity"] = { -- user should press Enter or Spacebar, or "OK" button with mouse (instead of pressing any key)
      priority = -1000,
      -- option_geometry =                  -- zenity does not allow setting number of rows and columns for monospaced font
      option_title = "--title",             -- actual usage == option_title..[[ 'My Title']]
      option_colors = "",                   -- zenity can't set its window color, so we don't use colors at all
      -- option_command =                   -- "zenity" uses "option_text" instead of "option_command"
      option_text = "--text",               -- actual usage == option_text..[[ 'My Text']]
      text_preprocessor =                   -- Pango Markup Language requires some escaping
         function(text)
            return "<tt>"..text:match"^\n*(.-)\n*$":gsub(".", {
               ["\\"]="\\\\", ["&"]="&amp;", ["<"]="&lt;", [">"]="&gt;", ["\n"]="\\n"
            }).."</tt>"
         end,
      options_misc = "--info --icon-name=", -- other useful options
   },

}  -- end of table "terminals"

-- all 16 colors available for foreground and background in terminal emulators
local all_colors = {--ANSI_FG  ANSI_BG   EGA     #RRGGBB            SYNONYMS
   ["dark red"]      = {"31",    "41",   "4",   "#800000", "          maroon"},
   ["light red"]     = {"91",   "101",   "C",   "#FF0000", "             red"},
   ["dark green"]    = {"32",    "42",   "2",   "#008000", "           green"},
   ["light green"]   = {"92",   "102",   "A",   "#00FF00", "            lime"},
   ["dark yellow"]   = {"33",    "43",   "6",   "#808000", "           olive"},
   ["light yellow"]  = {"93",   "103",   "E",   "#FFFF00", "          yellow"},
   ["dark blue"]     = {"34",    "44",   "1",   "#000080", "            navy"},
   ["light blue"]    = {"94",   "104",   "9",   "#0000FF", "            blue"},
   ["dark magenta"]  = {"35",    "45",   "5",   "#800080", "          purple"},
   ["light magenta"] = {"95",   "105",   "D",   "#FF00FF", "magenta, fuchsia"},
   ["dark cyan"]     = {"36",    "46",   "3",   "#008080", "            teal"},
   ["light cyan"]    = {"96",   "106",   "B",   "#00FFFF", "      aqua; cyan"},
   ["black"]         = {"30",    "40",   "0",   "#000000", "    afroamerican"},
   ["dark gray"]     = {"90",   "100",   "8",   "#808080", "            gray"},
   ["light gray"]    = {"37",    "47",   "7",   "#C0C0C0", "          silver"},
   ["white"]         = {"97",   "107",   "F",   "#FFFFFF", "                "},
}                         -- all_colors[color_name] = color_value

-- create "all_colors" table entries for color synonyms
local color_synonyms = {}
local ega_colors = {}     -- ega_colors[0..15] = color_value
for name, value in pairs(all_colors) do
   ega_colors[tonumber(value[3], 16)] = value
   color_synonyms[name:lower():gsub("%W", "")] = value
   for syn in value[5]:gmatch"[^,;/]+" do
      syn = syn:lower():gsub("%W", "")
      if syn ~= "" then
         color_synonyms[syn] = value
      end
   end
end
for name, value in pairs(color_synonyms) do
   all_colors[name] = value
   all_colors[name:gsub("gray", "grey")] = value
   name = name:gsub("^light", "lt"):gsub("^dark", "dk")
   all_colors[name] = value
   all_colors[name:gsub("gray", "grey")] = value
end

-- calculate best contrast counterparts for all colors
local best_contrast = {}  -- best_contrast[color_value] = color_value
for ega_color_id = 0, 15 do
   best_contrast[ega_colors[ega_color_id]] =
      ega_color_id <= 9 and ega_color_id ~= 7 and all_colors.white or all_colors.black
end

-- function to convert a string "fg/bg" to pair of color values
local function get_color_values(color_names, terminal_is_able_to_display_only_8_colors, avoid_using_default_terminal_colors)
   local fg_color_name, bg_color_name = (color_names or "black/silver"):match"^%s*([^/]-)%s*/%s*([^/]-)%s*$"
   if not fg_color_name then
      error('Wrong "colors" argument for "alert": expected format is "fg_color_name/bg_color_name"', 3)
   end
   local fg_color_value = all_colors[fg_color_name:gsub("%W", ""):lower()]
   local bg_color_value = all_colors[bg_color_name:gsub("%W", ""):lower()]
   if fg_color_name ~= "" or bg_color_name ~= "" then
      if not (fg_color_value or fg_color_name == "") then
         error('"alert" doesn\'t know this color: "'..fg_color_name..'"', 3)
      end
      if not (bg_color_value or bg_color_name == "") then
         error('"alert" doesn\'t know this color: "'..bg_color_name..'"', 3)
      end
      fg_color_value = fg_color_value or best_contrast[bg_color_value]
      bg_color_value = bg_color_value or best_contrast[fg_color_value]
      if terminal_is_able_to_display_only_8_colors then
         local colors_were_different = fg_color_value ~= bg_color_value
         fg_color_value = ega_colors[tonumber(fg_color_value[3], 16) % 8]
         bg_color_value = ega_colors[tonumber(bg_color_value[3], 16) % 8]
         if colors_were_different and fg_color_value == bg_color_value then
            -- pair of fg/bg colors is beyond terminal abilities, default terminal colors will be used
            fg_color_value, bg_color_value = nil
         end
      end
   end
   if avoid_using_default_terminal_colors then
      fg_color_value, bg_color_value = fg_color_value or all_colors.black, bg_color_value or all_colors.white
   end
   return fg_color_value, bg_color_value
end  -- end of function "get_color_values()"

local one_byte_char_pattern = "."                    -- Lua pattern for characters in Windows ANSI strings
local utf8_char_pattern = "[^\128-\191][\128-\191]*" -- Lua pattern for characters in UTF-8 strings

local function geometry_beautifier(
   cfg,                      --  configuration of current alert() instance
   text,                     --  text which layout should be beautified (text centering and padding, nice line splitting)
   char_pattern,             --  Lua pattern for matching one symbol in the text
   early_line_overflow,      --  true: cursor jumps to next line when previous line has been filled but not yet overflowed
   admit_linebreak_inside_of_a_word,  --  true: disable inserting additional LF in the safe locations of the text
   exact_geometry_is_unknown --  true (or number): we have no control over width and height of the terminal window
)  -- Three values returned:
   --    text (all newlines CR/CRLF/LF are converted to LF, last line is not terminated by LF)
   --    chosen terminal width  (nil if geometry beautifier is disabled)
   --    chosen terminal height (nil if geometry beautifier is disabled)
   text = (text or ""):gsub("\r\n?", "\n"):gsub("%z","\n"):gsub("[^\n]$", "%0\n")
   local width, height
   if cfg.enable_geometry_beautifier then
      local min_width  = math.max(12, cfg.min_width )
      local min_height = math.max( 3, cfg.min_height)
      local max_width  = math.max(12, cfg.max_width )
      local max_height = math.max( 3, cfg.max_height)
      if exact_geometry_is_unknown then
         -- we have no control over width and height of the terminal window, but we assume
         -- that terminal window has exactly 80 columns and at least 23 rows (this is very probable)
         max_width  = 80
         max_height = _type(exact_geometry_is_unknown) == "number" and exact_geometry_is_unknown or 23
      end
      local pos, left_cut, right_cut = 0, math.huge, 0
      local line_no, top_cut, bottom_cut = 0, math.huge, 0
      local line_is_not_empty
      text = text:gsub(char_pattern,
         function(c)
            if c == "\n" then
               pos = 0
               if line_is_not_empty then
                  line_is_not_empty = false
                  top_cut = math.min(top_cut, line_no)
                  bottom_cut = math.max(bottom_cut, line_no + 1)
               end
               line_no = line_no + 1
            elseif c == "\t" then
               local delta = 8 - pos % 8
               pos = pos + delta
               return (' '):rep(delta)
            else
               if c:find"%S" then
                  left_cut = math.min(left_cut, pos)
                  right_cut = math.max(right_cut, pos + 1)
                  line_is_not_empty = true
               end
               pos = pos + 1
            end
         end
      )
      left_cut = math.min(left_cut, right_cut)
      width = math.min(max_width, math.max(right_cut - left_cut + 2*cfg.horiz_padding,
         (cfg.always_use_maximum_size_of_terminal_window or exact_geometry_is_unknown) and max_width or min_width))
      local line_length_limit =
         not admit_linebreak_inside_of_a_word and right_cut - left_cut > max_width and max_width - 2*cfg.horiz_padding
      local left_indent =
         (" "):rep(line_length_limit and cfg.horiz_padding or math.max(math.floor((width - right_cut + left_cut)/2), 0))
      top_cut = math.min(top_cut, bottom_cut)
      local actual_height, new_text, line_no = 0, "", 0
      for line in text:gmatch"(.-)\n" do
         if line_no >= top_cut and line_no < bottom_cut then
            local prefix, prefix_len, new_line, new_line_len, pos, tail_of_spaces = "", 0, "", 0, 0, ""
            local punctuation, remove_leading_spaces
            for c in (line.." "):gmatch(char_pattern) do
               if pos >= left_cut then
                  if line_length_limit and (                  -- There are two kinds of locations to split a line nicely:
                     punctuation and (c:find"%w" or c:byte() > 127)                 -- 1) alphanumeric after punctuation
                     or tail_of_spaces == "" and pos > left_cut and not c:find"%S"  -- 2) space after non-space
                  ) then
                     if prefix_len + new_line_len > line_length_limit and prefix ~= ""
                           and #new_line:match"%S.*" < line_length_limit/3 then
                        new_text = new_text..left_indent..prefix.."\n"
                        actual_height = actual_height + 1
                        prefix, prefix_len, remove_leading_spaces = "", 0, true
                     end
                     repeat
                        if new_line == "" then
                           local length_in_bytes = 0
                           for _ = 1, line_length_limit do
                              length_in_bytes = select(2, prefix:find(char_pattern, length_in_bytes + 1))
                           end
                           local next_line = (left_indent..prefix:sub(1, length_in_bytes)):match".*%S"
                           remove_leading_spaces = next_line ~= nil
                           new_text = new_text..(next_line or "").."\n"
                           actual_height = actual_height + 1
                           prefix, prefix_len = prefix:sub(1 + length_in_bytes), prefix_len - line_length_limit
                        end
                        prefix, new_line, prefix_len, new_line_len = prefix..new_line, "", prefix_len + new_line_len, 0
                        local spaces_at_the_beginning = #prefix:match"%s*"
                        if remove_leading_spaces and spaces_at_the_beginning > 0 then
                           prefix, prefix_len = prefix:sub(1 + spaces_at_the_beginning), prefix_len - spaces_at_the_beginning
                        end
                     until prefix_len <= line_length_limit
                  end
                  if c:find"%S" then
                     new_line = new_line..tail_of_spaces..c
                     new_line_len = new_line_len + #tail_of_spaces + 1
                     tail_of_spaces = ""
                  else
                     tail_of_spaces = tail_of_spaces..c
                  end
                  punctuation = (",;"):find(c, 1, true)  -- dot was excluded to avoid splitting of numeric literals
               end
               pos = pos + 1
            end
            if line_length_limit then
               new_line, new_line_len = prefix, prefix_len
            end
            new_text = new_text..(new_line == "" and "" or left_indent)..new_line.."\n"
            actual_height = actual_height + math.max(math.ceil(new_line_len/width), 1)
         end
         line_no = line_no + 1
      end
      height = math.min(max_height, math.max(actual_height + 2*cfg.vert_padding,
         (cfg.always_use_maximum_size_of_terminal_window or exact_geometry_is_unknown) and max_height or min_height))
      local top_indent_size = math.floor((height - actual_height)/2)
      text = ("\n"):rep(math.max(top_indent_size, exact_geometry_is_unknown and cfg.vert_padding or 0))
         ..new_text..("\n"):rep(height - actual_height - top_indent_size - 1)
      if early_line_overflow then
         text = text:gsub("(.-)\n",
            function(line)
               return line ~= "" and select(2, line:gsub(char_pattern, "")) % width == 0 and line
            end
         )
      end
   end
   return text:gsub("\n$", ""), width, height
end  -- end of function "geometry_beautifier()"

-- the must-have system functions for this module:
local os_execute, io_popen, os_getenv = os.execute, io.popen, os.getenv

-- the following functions are required only under Wine and CJK Windows
local io_open, os_remove = io.open, os.remove -- they are needed to create and delete temporary file

local function get_output(command, format, binary_mode)
   local pipe = io_popen(command, binary_mode and "rb" or "r")
   local result = pipe:read(format or "*a")
   pipe:close()
   return result
end

local test_echo, env_var_os, cmd_echo, system_name, xinit_proc_cnt, wait_key_method_code
local tempfolder, tempfileid, sbcs, mbcs, ansi_to_utf16, utf16_to_ansi, utf16_to_oem, utf8_to_sbcs, tempfilespec
local locale_dependent_chars
local display_CLOSE_THIS_WINDOW_message = true

local function create_function_alert(cfg)   -- function constructor

   if not (os_execute and io_popen) then
      error('"alert" requires "os.execute" and "io.popen"', 3)
   end
   test_echo = test_echo or get_output"echo Test"  -- command "echo Test" should work on any OS
   if not test_echo:match"^Test" then
      error('"alert" requires non-sandboxed "os.execute" and "io.popen"', 3)
   end

   env_var_os = env_var_os or os_getenv"oS" or ""
   -- "oS" is not a typo.  It prevents Cygwin from being incorrectly identified as Windows.
   -- Cygwin inherits Windows environment variables, but treats them as if they were case-sensitive.

   if env_var_os:find"^Windows" then

      ----------------------------------------------------------------------------------------------------
      -- Windows or Wine
      ----------------------------------------------------------------------------------------------------

      local function get_binary_output(command)
         return get_output(command, nil, true)
      end

      local function create_binary_file(filename, content)
         local file = assert(io_open(filename, "wb"))
         file:write(content)
         file:close()
      end

      local function getwindowstempfilespec()
         if not tempfolder then
            tempfolder = assert(os_getenv"TMP" or os_getenv"TEMP", "%TMP% environment variable is not set")
            tempfileid = os.time() * 3456793  -- tempfileid is an integer number in the range 0..(2^53)-1
            -- We want to make temporary file name different for every run of the program
            -- %random% is 15-bit random integer generated by OS
            -- %time% is current time with 0.01 seconds precision on Windows (one-minute precision on Wine)
            -- tostring{} contains table's address inside the heap, heap location is changed on every run due to ASLR
            ;(tostring{}..get_output"echo %random%%time%%date%"):gsub("..",
               function(s)
                  tempfileid = tempfileid % 68719476736 * 126611
                     + math.floor(tempfileid/68719476736) * 505231
                     + s:byte() * 3083 + s:byte(2)
               end)
         end
         tempfileid = tempfileid + 1
         return tempfolder..("\\alert_%.f.tmp"):format(tempfileid)
      end

      if not locale_dependent_chars then
         locale_dependent_chars = {}
         for code = 128, 255 do
            locale_dependent_chars[code - 127] = string.char(code)
         end
         locale_dependent_chars = table.concat(locale_dependent_chars)
      end

      local function is_utf8(str)
         local is_ascii7 = true
         for c in str:gmatch"[^\128-\191]?[\128-\191]*" do
            local len, first = #c, c:byte()
            if len > 4 or len == 4 and not (first >= 0xF0 and first < 0xF5)
                       or len == 3 and not (first >= 0xE0 and first < 0xF0)
                       or len == 2 and not (first >= 0xC2 and first < 0xE0)
                       or len == 1 and not (first < 0x80) then
               return false
            end
            is_ascii7 = is_ascii7 and len < 2
         end
         return true, is_ascii7
      end

      local function convert_char_utf8_to_utf16(c)
         local c1, c2, c3, c4 = c:byte(1, 4)
         local unicode
         if c4 then      -- [1111 0xxx] [10xx xxxx] [10xx xxxx] [10xx xxxx]
            unicode = ((c1 % 8 * 64 + c2 % 64) * 64 + c3 % 64) * 64 + c4 % 64
         elseif c3 then  -- [1110 xxxx] [10xx xxxx] [10xx xxxx]
            unicode = (c1 % 16 * 64 + c2 % 64) * 64 + c3 % 64
         elseif c2 then  -- [110x xxxx] [10xx xxxx]
            unicode = c1 % 32 * 64 + c2 % 64
         else            -- [0xxx xxxx]
            unicode = c1
         end
         if unicode < 0x10000 then
            return string.char(unicode % 256, math.floor(unicode/256))
         else   -- make surrogate pair for unicode code points above 0xFFFF
            local unicode1 = 0xD800 + math.floor((unicode - 0x10000)/0x400) % 0x400
            local unicode2 = 0xDC00 + (unicode - 0x10000) % 0x400
            return string.char(unicode1 % 256, math.floor(unicode1/256),
                               unicode2 % 256, math.floor(unicode2/256))
         end
      end

      local function convert_string_utf8_to_utf16(str, with_bom)
         return (with_bom and "\255\254" or "")..str:gsub(utf8_char_pattern, convert_char_utf8_to_utf16)
      end

      -- Wine and Windows parse command line differently, we use it for Wine detection
      cmd_echo = cmd_echo or get_output'cmd /d/c "echo "^^""'
      local is_wine = cmd_echo:find"%^^"

      if not is_wine then

         ----------------------------------------------------------------------------------------------------
         -- Invocation of CMD.EXE on WINDOWS
         ----------------------------------------------------------------------------------------------------

         local function convert_string_utf8_to_oem(str, filename)
            -- convert UTF-8 to UTF-16LE with BOM
            create_binary_file(filename, convert_string_utf8_to_utf16(str.."#", true))  -- create temporary file
            -- convert UTF-16LE to OEM
            local converted = assert(get_binary_output('type "'..filename..'"'):match"^(.*)#")
            assert(os_remove(filename))                                                 -- delete temporary file
            return converted
         end

         local function to_native(str)
            if not (sbcs or mbcs) then
               local converted = get_binary_output("cmd /u/d/c echo("..locale_dependent_chars.."$")
               if converted:sub(257, 258) == "$\0" then
                  -- Windows native codepage is Single-Byte Character Set
                  sbcs = true
                  -- create table for fast conversion of UTF-8 characters to Single-Byte Character Set
                  utf8_to_sbcs = {}
                  for code = 128, 255 do
                     local low, high = converted:byte(2*code - 255, 2*code - 254)
                     local unicode = high * 256 + low
                     if unicode > 0x7FF then    -- [1110 xxxx] [10xx xxxx] [10xx xxxx]
                        utf8_to_sbcs[string.char(
                           0xE0 + math.floor(unicode/4096),
                           0x80 + math.floor(unicode/64) % 64,
                           0x80 + unicode % 64)] = string.char(code)
                     elseif unicode > 0x7F then -- [110x xxxx] [10xx xxxx]
                        utf8_to_sbcs[string.char(
                           0xC0 + math.floor(unicode/64),
                           0x80 + unicode % 64)] = string.char(code)
                     end
                  end
               else
                  -- Windows native codepage is Multi-Byte Character Set
                  mbcs = true
                  tempfilespec = getwindowstempfilespec()  -- temporary file for converting unicode strings to MBCS
               end
            end
            if sbcs then
               -- UTF-8 to SBCS
               return (str:gsub(utf8_char_pattern, function(c) return #c > 1 and (utf8_to_sbcs[c] or "?") end))
            else
               -- UTF-8 to MBCS
               -- on multibyte Windows encodings ANSI codepage is the same as OEM codepage
               return convert_string_utf8_to_oem(str, tempfilespec)
            end
         end

         return function (text, title, colors, wait, admit_linebreak_inside_of_a_word)
            text, title = text or "", title or "Press any key"
            if not cfg.use_windows_native_encoding then
               local text_is_utf8,  text_is_ascii7  = is_utf8(text)
               local title_is_utf8, title_is_ascii7 = is_utf8(title)
               if text_is_utf8 and title_is_utf8 then
                  text  = text_is_ascii7  and text  or to_native(text)
                  title = title_is_ascii7 and title or to_native(title)
               end
            end
            local text, width, height =
               geometry_beautifier(cfg, text, one_byte_char_pattern, true, admit_linebreak_inside_of_a_word)
            local fg, bg = get_color_values(colors)
            local lines = {}
            local function add_line(prefix, line)
               table.insert(lines, prefix..line:gsub(".", {
                  ["("]="^(", [")"]="^)", ["&"]="^&",  ["|"]="^|", ["^"]="^^",
                  [">"]="^>", ["<"]="^<", ["%"]="%^<", ['"']="%^>"
               }))
            end
            title = title:sub(1,200):match"%C+" or ""
            -- the following check is needed to avoid invocation of "title /?"
            if title:find'["%%]' and not title:find"/[%s,;=]*%?" then
               add_line("title ", title)
               title = ""
            end
            for line in (text.."\n"):gmatch"(.-)\n" do
               add_line("echo(", line)
            end
            os_execute(
               '"start "'..title:gsub(".", {['"']="'", ["%"]=" % "})..'" '
               ..(wait and "/wait " or "")
               ..'cmd /d/c"'
               ..(width and "mode "..width..","..height.."&" or "")
               ..(fg and "color "..bg[3]..fg[3].."&" or "")
               ..'for /f "tokens=1-3delims=_" %^< in ("%_"_"")do @('..table.concat(lines, "&")..")&"
               ..'pause>nul:""'
            )
         end

      end

      ----------------------------------------------------------------------------------------------------
      -- Invocation of CMD.EXE on Wine
      ----------------------------------------------------------------------------------------------------

      local function initialize_convertor(filename)
         local converted_ansi = get_binary_output("cmd /u/d/c echo "..locale_dependent_chars.."$")
         if converted_ansi:sub(257, 258) == "$\0" then
            -- Wine codepage is Single-Byte Character Set
            sbcs = true
            -- create tables for fast conversion UTF-16 to/from Single-Byte Character Set
            ansi_to_utf16 = {}          --  ansi_to_utf16[ansi char] = utf-16 char
            utf16_to_ansi = {}          --  utf16_to_ansi[utf-16 char] = ansi char
            utf16_to_oem = {}           --  utf16_to_oem[utf-16 char] = oem char
            create_binary_file(filename, locale_dependent_chars)
            local converted_oem = get_binary_output("cmd /u/d/c type "..filename)
            for code = 0, 255 do
               local c = string.char(code)
               local w_ansi = code < 128 and c.."\0" or converted_ansi:sub(2*code - 255, 2*code - 254)
               if code < 128 or w_ansi:byte(2) * 256 + w_ansi:byte() > 0x7F then
                  ansi_to_utf16[c] = w_ansi
                  utf16_to_ansi[w_ansi] = c
               end
               local w_oem = code < 128 and w_ansi or converted_oem:sub(2*code - 255, 2*code - 254)
               if code < 128 or w_oem:byte(2) * 256 + w_oem:byte() > 0x7F then
                  utf16_to_oem[w_oem] = c
               end
            end
         else
            -- Wine codepage is Multi-Byte Character Set
            mbcs = true
         end
      end

      return function (text, title, colors, wait, admit_linebreak_inside_of_a_word)
         text, title = text or "", (title or "Press any key"):sub(1,200):match"%C+" or ""
         local text_is_utf8,  text_is_ascii7  = is_utf8(text)
         local title_is_utf8, title_is_ascii7 = is_utf8(title)
         local char_pattern =
            (not cfg.use_windows_native_encoding and text_is_utf8 and title_is_utf8)
            and utf8_char_pattern
            or one_byte_char_pattern
         local text = geometry_beautifier(cfg, text, char_pattern, true, admit_linebreak_inside_of_a_word, 25)
         local fg, bg = get_color_values(colors)
         local tempfilename = getwindowstempfilespec()       -- temporary file for saving text
         -- convert title to ANSI codepage
         if not title_is_ascii7 and char_pattern == utf8_char_pattern then
            if not (sbcs or mbcs) then
               initialize_convertor(tempfilename)
            end
            if sbcs then
               title = convert_string_utf8_to_utf16(title)
                  :gsub("..", function(w) return utf16_to_ansi[w] or "?" end)
            end
         end
         -- convert text to OEM codepage and save to temporary file
         text = (text.."\n"):gsub("\n", "\r\n")
         if not text_is_ascii7 then
            if not (sbcs or mbcs) then
               initialize_convertor(tempfilename)
            end
            if sbcs then
               if char_pattern == utf8_char_pattern then
                  text = convert_string_utf8_to_utf16(text)
               else
                  text = text:gsub(".", ansi_to_utf16)
               end
               text = text:gsub("..", function(w) return utf16_to_oem[w] or "?" end)
            end
         end
         create_binary_file(tempfilename, text)
         os_execute(
            "start "
            ..(wait and "/wait " or "")
            ..'cmd /d/c "'
            ..(fg and "color "..bg[3]..fg[3].."&" or "")
            .."title "..title:gsub("/%?", "/ ?")  -- to avoid invocation of "title /?"
               :gsub(".", {["&"]="^&", ["|"]="^|", ["^"]="^^", [">"]="^>", ["<"]="^<", ["%"]=" % ", ['"']="'"})
            .."&type "..tempfilename
            .."&del "..tempfilename.." 2>nul:"
            ..'&pause>nul:"'
         )
      end

   end

   ----------------------------------------------------------------------------------------------------
   -- *NIX
   ----------------------------------------------------------------------------------------------------

   local function q(text)   -- quoting under *nix shells
      if text == "" then
         text = '""'
      elseif text:match"%W" then
         local t = {}
         for s in (text.."'"):gmatch"(.-)'" do
            t[#t + 1] = s:match"%W" and "'"..s.."'" or s
         end
         text = table.concat(t, "\\'")
      end
      return text
   end

   system_name = system_name or get_output"uname":match"%C+"
   local is_macosx = system_name == "Darwin"
   local is_cygwin = system_name:find"^CYGWIN" or system_name:find"^MINGW" or system_name:find"^MSYS"
   local xless_system =
      is_macosx and cfg.always_use_terminal_app_under_macosx
      or is_cygwin and cfg.always_use_cmd_exe_under_cygwin
   if not xless_system and (is_macosx or is_cygwin) then
      xinit_proc_cnt = xinit_proc_cnt or get_output("(ps ax|grep /bin/xinit|grep -c -v grep)2>/dev/null", "*n") or 0
      xless_system = xinit_proc_cnt == 0
   end

   if not xless_system then

      ----------------------------------------------------------------------------------------------------
      -- Auto-detection of terminal emulator on *nix
      ----------------------------------------------------------------------------------------------------

      local function get_terminal_priority(terminal)
         return terminal == cfg.terminal and math.huge or terminals[terminal].priority or -math.huge
      end
      local terminal_names = {}
      for terminal in pairs(terminals) do
         table.insert(terminal_names, terminal)
      end
      table.sort(terminal_names,
         function(a, b)
            local pr_a, pr_b = get_terminal_priority(a), get_terminal_priority(b)
            return pr_a < pr_b or pr_a == pr_b and a < b
         end
      )
      local command, delta = "exit 0", 70
      for k, terminal in ipairs(terminal_names) do
         command = "command -v "..terminal.."&&exit "..k+delta.."||"..command
      end
      local function run_quietly_and_get_exit_code(shell_command)
         return get_output("("..shell_command..")>/dev/null 2>&1;echo $?", "*n") or -1
      end
      local terminal = terminal_names[run_quietly_and_get_exit_code(command) - delta]

      if terminal then

         ----------------------------------------------------------------------------------------------------
         -- Invocation of terminal emulator on *nix
         ----------------------------------------------------------------------------------------------------

         -- choosing a method of waiting for user pressed a key
         local mc
         if terminals[terminal].option_command then
            wait_key_method_code = wait_key_method_code or
               run_quietly_and_get_exit_code"command -v dd&&command -v stty&&exit 69||command -v bash&&exit 68||exit 0"
            mc = wait_key_method_code
         end
         local method = ({
            [68] = {default_title = "Press any key",
                    shell = "bash",
                    wait_a_key = "read -rsn 1"},
            [69] = {default_title = "Press any key",
                    shell = "sh",
                    wait_a_key = "stty -echo raw;dd bs=1 count=1 >/dev/null 2>&1;stty sane"}
         })[mc] or {default_title = "Press Enter",
                    shell = "sh",
                    wait_a_key = "read a"}

         local function nop(...) return ... end
         local exact_geometry_is_unknown = not terminals[terminal].option_geometry

         return function (text, title, colors, wait, admit_linebreak_inside_of_a_word)
            title = title or method.default_title
            local text, width, height = geometry_beautifier(
               cfg, text, utf8_char_pattern, false, admit_linebreak_inside_of_a_word, exact_geometry_is_unknown)
            local fg, bg = get_color_values(colors, terminals[terminal].only_8_colors)
            if fg and not terminals[terminal].option_colors then
               text = "\27["..fg[1]..";"..bg[2].."m\27[J"..text
            end
            os_execute(
               ((is_cygwin or is_macosx) and "DISPLAY=:0 " or "")
               ..terminal.." "
               ..(terminals[terminal].options_misc or "").." "
               ..(fg
                  and terminals[terminal].option_colors and terminals[terminal].option_colors:format(fg[4], bg[4]).." "
                  or "")
               ..(width
                  and (terminals[terminal].option_geometry or ""):format(width, height).." "
                  or "")
               ..terminals[terminal].option_title.." "..q(title).." "
               ..(terminals[terminal].option_command
                  and
                     terminals[terminal].option_command.." "..
                     (terminals[terminal].command_requires_quoting and q or nop)(
                        method.shell.." -c "..q("echo "..q(text)..";"..method.wait_a_key)
                     )..">/dev/null 2>&1"
                  or
                     terminals[terminal].option_text.." "..q((terminals[terminal].text_preprocessor or nop)(text))
               )
               ..(wait and "" or " &")
            )
         end

      end

   end

   if is_macosx then

      ----------------------------------------------------------------------------------------------------
      -- Invocation of Terminal.app on MacOSX
      ----------------------------------------------------------------------------------------------------

      local function q_as(text)  -- quoting under AppleScript
         return '"'..text:gsub('[\\"]', "\\%0")..'"'
      end

      return function (text, title, colors, wait, admit_linebreak_inside_of_a_word)
         title = title or "Press any key"
         local text, width, height =
            geometry_beautifier(cfg, text, utf8_char_pattern, false, admit_linebreak_inside_of_a_word)
         local fg, bg = get_color_values(colors, nil, true)
         local r, g, b = bg[4]:match"(%x%x)(%x%x)(%x%x)"
         local rgb = "{"..tonumber(r..r, 16)..","..tonumber(g..g, 16)..","..tonumber(b..b, 16).."}"
         os_execute(  -- "shell command" nested into 'AppleScript' nested into "shell command"
            "osascript -e "..q(
               'set w to 1\n'                                   -- 1 second (increase it when running Mac OS X as VM guest)
            .. 'if app "Terminal" is running then set w to 0\n' -- 0 seconds
            .. 'do shell script "open -a Terminal ."\n'
            .. 'delay w\n' -- Terminal.app may take about a second to start, this delay happens only once
            .. 'tell app "Terminal"\n'
            ..    'tell window 1\n'
            ..       (width and string.format(
                     'set number of columns to %d\n'
            ..       'set number of rows to %d\n', width, height) or '')
            ..       'set normal text color to '..rgb..'\n'
            ..       'set background color to '..rgb..'\n'
            ..       'set custom title to '..q_as(title)..'\n'
            ..       'do script '..q_as(
                        "echo $'\\ec\\e['"..q(fg[1].."m"..text)..";read -rsn 1;echo $'\\e[H\\e[J"
            ..          (wait and display_CLOSE_THIS_WINDOW_message and "\n"
            ..          "  PLEASE CLOSE THIS WINDOW TO CONTINUE\n\n" -- this will be displayed only once
            ..          "The following profile setting may be useful:\n"
            ..          "Terminal -> Preferences -> Settings -> Shell\n"
            ..          "When the shell exits: Close the window" or "").."\\e[0m';exit"
                     )..' in it\n'
            ..       (wait and
                     'set w to its id\n'
            ..     'end\n'
            ..     'repeat while id of every window contains w\n'
            ..        'delay 0.1\n' or '')
            ..     'end\n'
            .. 'end\n'
            )..">/dev/null 2>&1"
         )
         display_CLOSE_THIS_WINDOW_message = not wait and display_CLOSE_THIS_WINDOW_message
      end

   end

   if is_cygwin then

      ----------------------------------------------------------------------------------------------------
      -- Invocation of CMD.EXE on CYGWIN
      ----------------------------------------------------------------------------------------------------

      return function (text, title, colors, wait, admit_linebreak_inside_of_a_word)
         local text, width, height =
            geometry_beautifier(cfg, text, utf8_char_pattern, true, admit_linebreak_inside_of_a_word)
         local fg, bg = get_color_values(colors)
         local lines = {}
         local function add_line(prefix, line)
            table.insert(lines, prefix..line:gsub(".", {
               ["("]="^(", [")"]="^)", ["&"]="^&",  ["|"]="^|", ["^"]="^^",
               [">"]="^>", ["<"]="^<", ["%"]="%^<", ['"']="%^>", ["'"]="'\\''"
            }))
         end
         title = (title or "Press any key"):sub(1,200):match"%C+" or ""
         if title:find'["%%]' and not title:find"/[%s,;=]*%?" then
            add_line("title ", title)
            title = ""
         end
         for line in (text.."\n"):gmatch"(.-)\n" do
            add_line("echo(", line)
         end
         os_execute(
            'cmd /d/c \'for %\\ in (_)do @'
            ..'start %~x"'..title:gsub("[\"']", "'\\''"):gsub("%%", " %% ")..'%~x" '
            ..(wait and "/wait " or "")
            ..'cmd /d/c%~x"'
            ..(width and "mode "..width..","..height.."&" or "")
            ..(fg and "color "..bg[3]..fg[3].."&" or "")
            ..'for /f %~x"tokens=1-3delims=_" %^< in (%~x"%_""")do @('..table.concat(lines, "&")..')&pause>nul:%~x"\''
         )
      end

   end

   error(
      "Terminal emulator auto-detection failed.\n"..
      '"alert" is not aware of the terminal emulator your are using.\n'..
      'Please add your terminal emulator to the "terminals" table.', 3)

end  -- end of function "create_function_alert()"

local function result(x)
   -- argument may be nil, a string or a function returning a string
   -- retuned value is nil or a string
   if _type(x) == "function" then return x() else return x end
end

local function create_new_instance_of_function_alert(old_config, config_update)  -- factory of lazy wrapper for alert()
   local cfg = {}
   for key in pairs(initial_config) do
      if config_update[key] ~= nil then
         cfg[key] = config_update[key]
      elseif old_config[key] ~= NIL then
         cfg[key] = old_config[key]
      end
   end
   local alert
   return
      function(...)
         local arg1, cfg_update = ...
         if arg1 == nil and _type(cfg_update) == "table" then  -- special form of invocation (user wants to create a function)
            -- create new instance of function with modified configuration
            return create_new_instance_of_function_alert(cfg, cfg_update)
         else                                           -- usual form of invocation (user wants to create a window with text)
            -- create alert window
            alert = alert or create_function_alert(cfg)   -- here alert() is actually gets created (deferred/"lazy" creation)
            local text, title, colors, wait, admit_linebreak_inside_of_a_word = ...
            if _type(text) == "table" then  -- handle invocation with named arguments
               text, title, colors, wait, admit_linebreak_inside_of_a_word =
                  text.text, text.title, text.colors, text.wait, text.admit_linebreak_inside_of_a_word
            end
            -- applying default argument values if needed
            if wait == nil then
               wait = cfg.default_arg_wait
            end
            if admit_linebreak_inside_of_a_word == nil then
               admit_linebreak_inside_of_a_word = cfg.default_arg_admit_linebreak_inside_of_a_word
            end
            -- default arguments for text/title/colors are allowed to be nils, strings or functions returning a string
            text   = text   or result(cfg.default_arg_text)
            title  = title  or result(cfg.default_arg_title)
            colors = colors or result(cfg.default_arg_colors)
            -- nothing will be returned, the keyword "return" is here just for tail call
            return alert(text, title, colors, wait, admit_linebreak_inside_of_a_word)
         end
      end
end

local alert =  create_new_instance_of_function_alert(initial_config, {})

function split(t)
	table.sort(t,function(a,b)
		return a < b
	end)
	local num = #t
	local t1, t2 = {},{}
	if (num/2)%1 ~= 0 then
		for i=1,math.floor(num/2) do
			t1[i]=t[i]
		end
		for i=math.ceil(num/2+1),#t do
			t2[i-math.ceil(num/2)]=t[i]
		end
	else
		for i=1,num/2 do
			t1[i] = t[i]
		end
		for i=num/2+1,#t do
			t2[i-num/2] = t[i]
		end
	end
	return t1, t2
end
function dupe(t)
	local newT = {}
	for i,v in pairs(t) do
		if not table.find(newT,v) then
			table.insert(newT,v)
		end
	end
	return newT
end
function add0(x)
	if x < 10 then return tostring('0'..x) else return x end
end
local math2 = {}
-- Statistics/Chance

function math2.flip(x) -- x is a number from 0-1
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number from 0 to 1") end
	return Random.new():NextNumber() < x
end

function math2.sd(x,PopulationToggle)
	if _type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	if _type(PopulationToggle) ~= 'boolean' and PopulationToggle ~= nil then return warn("Make sure parameter 2 is set to nil or a boolean") end
	if PopulationToggle == nil then PopulationToggle = false end
	local s = 0
	local ss = pcall(function()
		for i,v in pairs(x) do 
			s = s+v 
		end
	end)
	if not s then return warn("Make sure all values in the table are numbers") end 
	local avg = s/#x
	local t = 0
	for i,v in pairs(x) do t = t+((v - avg)^2) end
	if not PopulationToggle then
		return math.sqrt(t/(#x-1))
	else
		return math.sqrt(t/(#x))
	end
end



function math2.min(x) 
	if _type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	local s = pcall(function()
		table.sort(x,function(a,b)
			return a < b
		end)
	end)
	if not s then return warn("Make sure all values in the table are numbers") end
	return x[1]
end

function math2.median(x) 
	if _type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	local s = pcall(function()
		table.sort(x,function(a,b)
			return a < b
		end)
	end)
	if not s then return warn("Make sure all values in the table are numbers") end
	local index = #x/2+.5
	local median
	if index%1 ~= 0 then
		median = (x[index-.5]+x[index+.5])/2
	else
		median = x[index]
	end
	return median
end

function math2.q1(x)
	if _type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	local s = pcall(function()
		table.sort(x,function(a,b)
			return a < b
		end)
	end)
	if not s then return warn("Make sure all values in the table are numbers") end
	local t,_ = split(x)
	return math2.median(t)
end



function math2.q3(x)
	if _type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	local s = pcall(function()
		table.sort(x,function(a,b)
			return a < b
		end)
	end)
	if not s then return warn("Make sure all values in the table are numbers") end
	local _,t = split(x)
	
	return math2.median(t)
end
function math2.max(x) 
	if _type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	local s = pcall(function()
		table.sort(x,function(a,b)
			return a > b
		end)
	end)
	if not s then return warn("Make sure all values in the table are numbers") end
	return x[1]
end

function math2.iqr(x)
	if _type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	local s = pcall(function()
		table.sort(x,function(a,b)
			return a < b
		end)
	end)
	if not s then return warn("Make sure all values in the table are numbers") end
	return math2.q3(x)-math2.q1(x)
end

function math2.range(x)
	if _type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	local s = pcall(function()
		table.sort(x,function(a,b)
			return a < b
		end)
	end)
	if not s then return warn("Make sure all values in the table are numbers") end
	return math2.max(x)-math2.min(x)
end

function math2.mode(x)
	if _type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	local mostFrequent = {}
	local s = pcall(function()
		for i,v in pairs(x) do
			if mostFrequent[tostring(v)] ~= nil then
				mostFrequent[tostring(v)] = mostFrequent[tostring(v)]+1
			else
				mostFrequent[tostring(v)] = 1
			end
		end
	end)
	if not s then return warn("Make sure all values in the table are numbers") end
	table.sort(mostFrequent,function(a,b)
		return a > b
	end)
	local greatest = {{nil},0}
	for i,v in pairs(mostFrequent) do
		if v > greatest[2] then
			greatest = {{i},v}
		end
		if v == greatest[2] then
			table.insert(greatest[1],i)
		end
	end
	return dupe(greatest[1])
end

function math2.mad(x)
	if _type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	local avg = 0
	local s = pcall(function()
		for i,v in pairs(x) do
			avg = avg+(v/#x)
		end
	end)
	
	if not s then return warn("Make sure all values in the table are numbers") end
	local s = 0
	for i=1,#x do
		s = s+math.abs(x[i]-avg)
	end
	return s/#x
end

function math2.avg(x)
	if _type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	local avg = 0
	
	local s = pcall(function()
		for i,v in pairs(x) do
			avg = avg+(v/#x)
		end
	end)
	if not s then return warn("Make sure all values in the table are numbers") end
	return avg
end

function math2.zscore(x,PopulationToggle)
	if PopulationToggle == nil then PopulationToggle = false end
	if _type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	if _type(PopulationToggle) ~= 'boolean' and PopulationToggle ~= nil then return warn("Make sure parameter 2 is set to nil or a boolean") end
	
	local newt = {}
	local sd = math2.sd(x,PopulationToggle)
	local mean = math2.avg(x)
	for i,v in pairs(x) do
		newt[tostring(v)] = (v-mean)/sd
	end
	return newt
end

-- Miscellaneous

function math2.gcd(a,b)
	if _type(a) ~= 'number' and _type(b) ~= 'number' then return warn("Make sure parameter 1 and 2 are both numbers") end 
	if _type(a) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if _type(b) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	a = math.min(a,b)
	b = math.max(a,b)
	local q = math.floor(b/a)
	local r = b-(a*q)
	if r == 0 then return a end 
	return math2.gcd(r,a)
end

function math2.lcm(a,b)
	if _type(a) ~= 'number' and _type(b) ~= 'number' then return warn("Make sure parameter 1 and 2 are both numbers") end 
	if _type(a) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if _type(b) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	return math.abs(a*b)/math2.gcd(a,b)
end

function math2.floor(x,NearestDecimal)
	if NearestDecimal == nil then NearestDecimal = 0 end
	if _type(x) ~= 'number' and _type(NearestDecimal) ~= 'number' then return warn("Make sure parameter 1 and 2 are both numbers") end 
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if _type(NearestDecimal) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	return math.floor(x*10^NearestDecimal)/10^NearestDecimal
end

function math2.round(x,NearestDecimal)
	if NearestDecimal == nil then NearestDecimal = 0 end
	if _type(x) ~= 'number' and _type(NearestDecimal) ~= 'number' then return warn("Make sure parameter 1 and 2 are both numbers") end 
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if _type(NearestDecimal) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	return math.round(x*10^NearestDecimal)/10^NearestDecimal
end

function math2.ceil(x,NearestDecimal)
	if NearestDecimal == nil then NearestDecimal = 0 end
	if _type(x) ~= 'number' and _type(NearestDecimal) ~= 'number' then return warn("Make sure parameter 1 and 2 are both numbers") end 
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if _type(NearestDecimal) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	return math.ceil(x*10^NearestDecimal)/10^NearestDecimal
end

function math2.factors(x)
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	local t = {}
	for i=1,x^.5 do
		if x%i == 0 then
			table.insert(t,i)
			table.insert(t,x/i)
		end
	end
	table.sort(t,function(a,b)
		return a < b
	end)
	return dupe(t)
end

function math2.iteration(Input,Iterations,Func)

	if _type(Index) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if _type(Iterations) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	if Iterations%1 ~= 0 then return warn("Make sure parameter 2 is an integer") end 
	if _type(Func) ~= 'function' then return warn("Make sure parameter 3 is a function") end 

	local new = Input
	for i=1,Iterations do
		new = Func(new)
	end
	return math.round(new*10e11)/10e11
end

function math2.nthroot(x,Index)

	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if _type(Index) ~= 'number' then return warn("Make sure parameter 2 is a number") end 

	return x^(1/Index)
end

function math2.fibonacci(x)
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if x%1 ~= 0 then return warn("Make sure parameter 1 is an integer") end 
	return math.round((((1+math.sqrt(5))/2)^x-((1-math.sqrt(5))/2)^x)/math.sqrt(5))
end

function math2.lucas(x)
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if x%1 ~= 0 then return warn("Make sure parameter 1 is an integer") end 
	return math.round((((1+math.sqrt(5))/2)^x-((1-math.sqrt(5))/2)^x)/math.sqrt(5)+(((1+math.sqrt(5))/2)^(x-2)-((1-math.sqrt(5))/2)^(x-2))/math.sqrt(5))
end


-- Useless

function math2.digitadd(x)
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if x%1 ~= 0 then return warn("Make sure parameter 1 is an integer") end 
	
	local t = string.split(x,'')
	local s = 0
	for i,v in pairs(t) do
		s = s+v
	end
	return s
end

function math2.digitmul(x)
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if x%1 ~= 0 then return warn("Make sure parameter 1 is an integer") end 
	local t = string.split(x,'')
	local s = 0
	for i,v in pairs(t) do
		s = s*v
	end
	return s
end

function math2.digitrev(x)
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if x%1 ~= 0 then return warn("Make sure parameter 1 is an integer") end 
	local strin = string.split(tostring(x),'')
	local newt = {}
	for i,v in pairs(strin) do
		newt[#strin-i+1] = v
	end
	return tonumber(table.concat(newt,''))
end

-- Formatting

function math2.toComma(x)
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	local neg = false
	if x < 0 then x = math.abs(x) neg = true end
	local nums = string.split(x,'')
	local num = ''
	local digits = math.floor(math.log10(x))+1
	for i,v in pairs(nums) do
		if (digits-i)%3 == 0 and digits-i ~= 0 then
			num = num..v..','
		else
			num = num..v
		end
	end
	if neg then return '-'..num end 
	return num
end

function math2.fromComma(x)
	if _type(x) ~= 'string' then return warn("Make sure parameter 1 is a string") end 
	local a = string.gsub(x,',','')
	return a
end

function math2.toKMBT(x,NearestDecimal)
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if x < 1000 and x > -1000 then return x end
	local neg = false
	if  x < 0 then
		neg = true
		x = math.abs(x)
	end
	if NearestDecimal == nil then NearestDecimal = 15 end 
	local list = {'','K','M','B','T','Qa','Qi','Sx','Sp','Oc','No','Dc','Udc','Ddc','Tdc'}
	local digits = math.floor(math.log10(x))+1
	local suffix = list[math.floor((digits-1)/3)+1]
	if neg then return '-'..math.floor((x/(10^(3*math.floor((digits-1)/3))))*10^NearestDecimal)/10^NearestDecimal .. suffix end
	return math.floor((x/(10^(3*math.floor((digits-1)/3))))*10^NearestDecimal)/10^NearestDecimal .. suffix
end

function math2.fromKMBT(x)
	if _type(x) ~= 'string' then return warn("Make sure parameter 1 is a string") end 
	if tonumber(x) then return x end
	local list = {'','K','M','B','T','Qa','Qi','Sx','Sp','Oc','No','Dc','Udc','Ddc','Tdc'}
	local splits = string.split(x,'')
	local letter = splits[string.find(x,'%a')]
	local factor = 10^((table.find(list,letter)-1)*3)
	if neg then return tonumber('-'..string.split(x,letter)[1]*factor) end
	return string.split(x,letter)[1]*factor
end

function math2.toScientific(x,Base)
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if _type(Base) ~= 'number' and Base ~= nil then return warn("Make sure parameter 2 is a number or nil") end 
	local neg = false
	if x < 0 then neg = true x = math.abs(x) end
	if Base == nil then Base = 10 end
	local power = math.floor(math.log(x,Base))
	local constant = x/Base^power
	if neg then return -constant..' * ' ..Base..'^'.. power end
	return constant..' * ' ..Base..'^'.. power
end

function math2.fromScientific(x)
	if _type(x) ~= 'string' then return warn("Make sure parameter 1 is a string") end 
	local constant = tonumber(string.split(x,'*')[1])
	local base = tonumber(string.split(string.split(x,'*')[2],'^')[1])
	local power = tonumber(string.split(string.split(x,'*')[2],'^')[2])
	return constant*base^power
end
function math2.toNumeral(x)
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	local numberMap = {
		{1000, 'M'},
		{900, 'CM'},
		{500, 'D'},
		{400, 'CD'},
		{100, 'C'},
		{90, 'XC'},
		{50, 'L'},
		{40, 'XL'},
		{10, 'X'},
		{9, 'IX'},
		{5, 'V'},
		{4, 'IV'},
		{1, 'I'}

	}
		local roman = ""
		while x > 0 do
			for index,v in pairs(numberMap)do 
				local romanChar = v[2]
				local int = v[1]
				while x >= int do
					roman = roman..romanChar
					x = x-int
				end
			end
		end
		return roman
end

function math2.fromNumeral(x)
	if _type(x) ~= 'string' then return warn("Make sure parameter 1 is a string") end 
	local decimal = 0
	local num = 1
	local numeralLength = string.len(x)
	local numberMap = {
		['M'] = 1000,
		['D'] = 500,
		['C'] = 100,
		['L'] = 50,
		['X'] = 10,
		['V'] = 5,
		['I'] = 1
	}
	for char in string.gmatch(tostring(x),'.') do
		local ifString = false
		for i, v in pairs(numberMap) do
			if char == i then ifString = true end
		end
		if ifString == false then return warn("Check if you're only using characters (M,D,C,L,X,V,I)") end
	end
	while num < numeralLength do
		local Z1 = numberMap[string.sub(x, num, num)]
		local Z2 = numberMap[string.sub(x, num + 1, num + 1)]
		if Z1 < Z2 then
			decimal = decimal + (Z2 - Z1)
			num = num + 2
		else
			decimal = decimal + Z1
			num = num + 1
		end
	end
	if num <= numeralLength then decimal = decimal+numberMap[string.sub(x, num, num)] end
	return decimal
end

function math2.toPercent(x,NearestDecimal)
	if NearestDecimal == nil then NearestDecimal = 15 end
	if _type(x) ~= 'number' and _type(NearestDecimal) ~= 'number' then return warn("Make sure parameter 1 and 2 are both numbers") end 
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if _type(NearestDecimal) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	return math.round(x*100*10^NearestDecimal)/10^NearestDecimal
end

function math2.fromPercent(x)
	if _type(x) ~= 'string' then return warn("Make sure parameter 1 is a string") end 
	local n
	local s = pcall(function()
		n = string.split(x,'%')[1]
	end)
	if not s then return warn('Make sure parameter 1 is in the form "N%"') end
	return n/100
end

function math2.toFraction(x,MixedToggle)
	if MixedToggle == nil then MixedToggle = false end
	if _type(x) ~= 'number' and _type(MixedToggle) ~= 'boolean' then return warn("Make sure parameter 1 is a number and parameter 2 is a boolean") end 
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if _type(MixedToggle) ~= 'boolean' then return warn("Make sure parameter 2 is a boolean") end 
	local whole,number = math.modf(x)
	local a,b,c,d,e,f = 0,1,1,1,nil,nil
	local exact = false
	for i=1,20000 do
		e = a+c
		f = b+d
		if e/f < number then
			a=e
			b=f
		elseif e/f > number then
			c=e
			d=f
		else
			break
		end
	end
	exact = e/f == number
	if MixedToggle then
		return whole.. ' '..e..'/'..f,exact
	else
		return e+(f*whole)..'/'..f,exact
	end
end

function math2.fromFraction(x)
	if _type(x) ~= 'string' then return warn("Make sure parameter 1 is a string") end 
	local mixed = false
	local whole
	local s = pcall(function()
		whole = string.split(x,' ')[1]
		mixed = whole ~= x
		if not mixed then whole = 0 end
	end)
	if not s then whole = 0 end
	local num,denom
	local s = pcall(function()
		num,denom = string.split(x,'/')[1],string.split(x,'/')[2]
		if mixed then num = string.split(string.split(x,'/')[1],' ')[2] end
	end)
	if not s then return warn('Make sure parameter 1 is a string in the form of "A B/C" or A/B') end 
	print(whole,num,denom)
	return whole + num/denom
end

function math2.toTime(x,AMPMToggle)
	if AMPMToggle == nil then AMPMToggle = false end
	if _type(x) ~= 'number' and _type(AMPMToggle) ~= 'boolean' then return warn("Make sure parameter 1 is a number from 0-24 and parameter 2 is a boolean") end 
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number from 0-24") end 
	if _type(AMPMToggle) ~= 'boolean' then return warn("Make sure parameter 2 is a boolean") end 
	local hour = math.floor(x)
	local leftover = x-hour
	local minute = math.floor(leftover*60)
	local second = math.round((leftover*60-minute)*60)
	if not AMPMToggle then
		return add0(hour)..':'..add0(minute)..':'..add0(second)
	else
		if hour >= 13 then
			return add0(hour-12)..':'..add0(minute)..':'..add0(second).. ' PM'
		elseif hour == 0 then
			return 12 ..':'..add0(minute)..':'..add0(second).. ' AM'
		else
			
			return add0(hour)..':'..add0(minute)..':'..add0(second).. ' AM'
		end
	end
end

math2.perlin = perlin -- add perlin:noise(), etc.
function math2.fromTime(x)
	if _type(x) ~= 'string' then return warn("Make sure parameter 1 is a string") end 
	local am = string.find(x,'AM')
	local pm = string.find(x,'PM')
	local twoletter
	local ampm = false
	if am ~= nil then
		ampm = true
		twoletter = 'AM'
	elseif pm ~= nil then
		ampm = true
		twoletter = 'PM'
	end
	local hours, minutes, seconds = string.split(x,':')[1],string.split(x,':')[2],string.split(string.split(x,':')[3],' ')[1]
	
	
	if twoletter then
		if twoletter == 'AM' then
			if tonumber(hours) == 12 then
				return hours-12 + minutes/60 + seconds/3600
			end
			return hours + minutes/60 + seconds/3600
		else
			tonumber(hours)
			if tonumber(hours) < 12 then
				return hours+12 + minutes/60 + seconds/3600
			else
				return hours + minutes/60 + seconds/3600
			end
		end
	else
		return hours + minutes/60 + seconds/3600
	end
end

function math2.toBase(x,Base,CurrentBase)--Number,BaseToConvert,CurrentBase

	if _type(Base) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if _type(CurrentBase) ~= 'number' then return warn("Make sure parameter 1 is a number") end 

	x = string.upper(x)
	local digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local function baseToDecimal(n1,b1)
		local nums = string.split(tostring(n1),'')
		for i,v in pairs(nums) do
			if tonumber(v) == nil then
				local digits2 = string.split(digits,'')
				print( table.find(digits2,v)-1)
				nums[i] = table.find(digits2,v)-1
			else
				local digits2 = string.split(digits,'')
				print( table.find(digits2,v)-1)
				nums[i] = table.find(digits2,v)-1
			end
		end
		local sum = 0
		for i,v in pairs(nums) do
			sum = sum + (v*(b1^(#nums-i)))
		end
		return sum
	end
	if CurrentBase ~= 10 then
		x = baseToDecimal(x,CurrentBase)
	end
	x = math.floor(x)
	if not Base or Base == 10 then return tostring(x) end
	
	local t = {}
	local sign = ""
	if x < 0 then
		sign = "-"
		x = -x
	end
	repeat
		local d = (x % Base) + 1
		x = math.floor(x / Base)
		table.insert(t, 1, digits:sub(d,d))
	until x == 0
	return sign .. table.concat(t,"")
end

function math2.toFahrenheit(x)
	return 9*x/5 + 32
end


function math2.toCelsius(x)
	return 5*(x-32)/9
end

-- Algebra

function math2.vertex(a,b,c)
	if _type(a) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if _type(b) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	if _type(c) ~= 'number' then return warn("Make sure parameter 3 is a number") end 
	return -b/(2*a),-b^2/(4*a)+c
end

function math2.solver(f) -- can solve any function equal to 0
	if _type(f) ~= 'function' then return warn("Make sure parameter 1 is a function with 1 parameter") end 
	local t = {}
	local d = function(p,f1)
		return(f1(p+1e-5)-f1(p))/1e-5
	end
	for i=-20,20,.1 do
		table.insert(t,i)
	end
	for ii=1,1e3 do
		local y1,m
		for i,a in pairs(t) do
			if ii == 1e3 then
					
				if string.lower(tostring(math.round((a-(f(a)/d(a,f)))*1e14)/1e14)) == 'nan' then  
					t[table.find(t,a)] = math.huge
				else
					t[table.find(t,a)]=math.round((a-(f(a)/d(a,f)))*1e14)/1e14
				end

			else
				
				if string.lower(tostring(math.round((a-(f(a)/d(a,f)))*1e14)/1e14)) == 'nan' then  
					t[table.find(t,a)] = math.huge
				else
					t[table.find(t,a)]=a-(f(a)/d(a,f))
				end
			end


		end
	end
	local hash = {}
	local n = {}
	for _,v in ipairs(t) do
		if (not hash[v]) then
			if string.lower(v) ~= 'inf' then
				n[#n+1] = v
			end
			
			local s = pcall(function()
				hash[v] = true
			end)
		end
	end
	table.sort(n)
	return n
end

-- Calculus

function math2.derivative(x,Function)
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if _type(Function) ~= 'function' then return warn("Make sure parameter 2 is a function") end 
	return (Function(x+1e-12)-Function(x))/1e-12
end

function math2.integral(Lower,Upper,Function)
	if _type(Lower) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if _type(Upper) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	if _type(Function) ~= 'function' then return warn("Make sure parameter 3 is a function") end 
	local s = 0
	local n = false
	if Upper < 0 then
		n = true
		Upper=math.abs(Upper)
	end
	for i=Lower,Upper,1e-5 do
		s = s+ (Function(i)*1e-5)
	end
	if n then return -s else return s end
end

function math2.limit(x,Function)
	if _type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if _type(Function) ~= 'function' then return warn("Make sure parameter 2 is a function") end 
	return math.floor(Function(x+1e-13)*10^12)/10^12
end

function math2.summation(Start,Finish,Function)
	if Function == nil then
		Function = function(x)
			return x
		end
	end
	if _type(Start) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if _type(Finish) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	if _type(Function) ~= 'function' then return warn("Make sure parameter 3 is a function") end 
	local sum = 0
	for i=Start,Finish do
		sum = sum+Function(i)
	end
	return sum
end

function math2.product(Start,Finish,Function)
	if _type(Start) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if _type(Finish) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	if _type(Function) ~= 'function' then return warn("Make sure parameter 3 is a function") end 
	local sum = 0
	for i=Start,Finish do
		sum = sum*Function(i)
	end
	return sum
end

--Consants
math2.e = 2.718281828459045235360287471352662497757247093699959574966967627724076630353547594571382178525166427427466391932003059921817413596629043572900334295260595630738132328627943490763233829880753195251019011573834187930702154089149934884167509244761460668082264800168477411853742345442437107539077744992069551702761838606261331384583000752044933826560297606737113200709328709127443747047230696977209310
math2.phi = (1 + 5^.5)/2

--Useless Ones
math2.pi = 3.14159265358979323846264338327950288419716939937510582097494459230781640628620899862803482534211706798214808651328230664709384460955058223172535940812848111745028410270193852110555 
math2.tau = 3.14159265358979323846264338327950288419716939937510582097494459230781640628620899862803482534211706798214808651328230664709384460955058223172535940812848111745028410270193852110555*2 


function wrap(f, ...)
	local args = { ... }

	return function(...)
		local __args = { ... }
		for i, value in ipairs(args) do
			table.insert(__args, i, value)
		end

		return f(unpack(__args))
	end
end

function wait(seconds)
	local start = os.time()
	repeat until os.time() > start + seconds
end

local function run(case, cases)
	local breakIt = false
	local default 

	local function stop()
		breakIt = true
	end

	for _, it in ipairs(cases) do
		if breakIt then 
			return 
		elseif it.sentence_type == "case" and it.condition == case then
			it.case(stop)
		end

		default = it.case
	end

	if default then
		default()
	end
end

local function return_it(sentence_type, condition, case)
	return {
		sentence_type = sentence_type,
		condition = condition,
		case = case
	}
end

local function switch(value)
	return wrap(run, value)
end

local function default(case)
	return return_it("default", 0, case)
end

local function case(condition)
	assert(condition ~= nil, "You must provide a condition")
	return wrap(return_it, "case", condition)
end

local function getFunctions()
	return switch, case, default
end
local function mutex()
	local MutexModule = { }
	local MutexObject = { Name = "Mutex" }

	MutexObject.__index = MutexObject

	function MutexObject:Lock()
		self._Locked = true
		self._Thread = coroutine.running()

		if self.Callback then 
			self.Callback() 
		end
	end

	function MutexObject:Unlock()
		if self._Thread then
			assert(self._Thread == coroutine.running(), "Thread Exception: Attempted to call Mutex.Unlock")
		end

		self._Thread = nil
		self._Locked = false
	end

	function MutexObject:Timeout(Int)
		self._Locked = true
		self._Timeout = {
			T = os.time(), Int = Int
		}

		if self.Callback then 
			self.Callback(true, Int) 
		end
	end

	function MutexObject:IsLocked()
		if self._Timeout then
			if os.time() - self._Timeout.T >= self._Timeout.Int then
				self._Timeout = false
				self._Locked = false

				return false
			end
		end

		return self._Locked
	end

	function MutexModule.new(Callback)
		local Mutex = setmetatable({ Callback = Callback, _Locked = false }, MutexObject)

		return Mutex
	end

	return MutexModule
end
local HooksModule = { }
local HookFunction = { }

HookFunction.__index = HookFunction
HookFunction.__call = function(Hook, ...)
	return Hook:Invoke(...)
end

-- // HookFunction Functions
function HookFunction:Prefix(Callback)
	assert(_type(Callback) == "function", "Expected Argument #1 function")

	self._PrefixCallback = Callback
end

function HookFunction:Postfix(Callback)
	assert(_type(Callback) == "function", "Expected Argument #1 function")

	self._PostfixCallback = Callback
end

function HookFunction:Patch(Callback)
	assert(_type(Callback) == "function", "Expected Argument #1 function")

	self.Callback = Callback
end

function HookFunction:Invoke(...)
	if not self.Callback then return end

	if self._PrefixCallback then
		local Continue, Exception = self._PrefixCallback(...)

		if not Continue then return Exception end
	end

	if self._PostfixCallback then
		return self._PostfixCallback(
			self.Callback(...)
		)
	end

	return self.Callback(...)
end

-- // HooksModule Functions
function HooksModule.new(Callback)
	local Hook = setmetatable({ Callback = Callback }, HookFunction)

	return Hook
end

local PromiseModule = { }
local PromiseObject = { Name = "Promise" }

PromiseObject.__index = PromiseObject
PromiseObject.__call = function(self, ...)
	if self.Rejected or self.Resolved then 
		return unpack(self.Result) 
	end

	self.Args = { ... }

	local Thread = coroutine.create(self._Function)
	local Success, Result = coroutine.resume(Thread, self, ...)

	if not Success then
		self:Reject(Result)
	end

	return self
end

-- // PromiseObject Functions
function PromiseObject:Get()
	if self.Rejected or self.Resolved then 
		return unpack(self.Result) 
	end
end

function PromiseObject:Finally(Callback)
	self._FinallyCallback = Callback

	if self.Rejected or self.Resolved then 
		self._Cancel = true

		Callback(self, unpack(self.Result))
	end

	return self
end

function PromiseObject:Catch(Callback)
	self._CatchCallback = Callback

	if self.Rejected then 
		Callback(self, unpack(self.Result))
	end

	return self
end

function PromiseObject:Then(Callback)
	table.insert(self._Stack, Callback)

	if self.Rejected or self.Resolved then 
		Callback(self, unpack(self.Result))
	end

	return self
end

function PromiseObject:Cancel()
	self._Cancel = true
end

function PromiseObject:Retry()
	self.Rejected = nil
	self.Resolved = nil
	self._Cancel = nil

	return (self.Args and self(unpack(self.Args))) or self()
end

function PromiseObject:Await()
	if self.Rejected or self.Resolved then 
		return self
	else
		table.insert(self._Await, coroutine.running())

		return coroutine.yield()
	end
end

function PromiseObject:Resolve(...)
	if self.Rejected or self.Resolved then 
		return
	end

	self.Resolved = true
	self.Result = { ... }

	for _, Thread in ipairs(self._Await) do
		coroutine.resume(Thread, self, ...)
	end

	for _, Callback in ipairs(self._Stack) do
		Callback(self, ...)

		if self._Cancel then
			self._Cancel = nil

			break
		end
	end

	if self._FinallyCallback then
		self._FinallyCallback(self, ...)
	end

	self._Await = { }
end

function PromiseObject:Reject(...)
	if self.Rejected or self.Resolved then 
		return
	end

	self.Rejected = true
	self.Result = { ... }

	for _, Thread in ipairs(self._Await) do
		coroutine.resume(Thread, self, ...)
	end

	if self._CatchCallback then
		self._CatchCallback(self, ...)
	else
		print(string.format("Unhandled Promise Rejection: [ %s ]", table.concat(self.Result, ", ")))
	end
end

-- // PromiseModule Functions
function PromiseModule.new(Function)
	return setmetatable({ _Function = Function, _Stack = { }, _Await = { } }, PromiseObject)
end

function PromiseModule.Wrap(Function, ...)
	return PromiseModule.new(function(Promise, ...)
		print(...)
		local Result = { pcall(Function, ...) }

		return (table.remove(Result, 1) and Promise:Resolve(unpack(Result))) or Promise:Reject(unpack(Result))
	end, ...)
end

function PromiseModule.Settle(Promises)
	for _, Promise in ipairs(Promises) do
		Promise:Await()
	end
end

function PromiseModule.AwaitSuccess(Promise)
	repeat Promise:Await() until Promise.Resolved

	return Promise:Get()
end

local SignalModule = { Simple = { } }
local SignalObject = { Name = "Mutex" }
local ConnectionObject = { Name = "Connection" }

SignalObject.__index = SignalObject
ConnectionObject.__index = ConnectionObject

-- // ConnectionObject Functions
function ConnectionObject:Reconnect()
	if self.Connected then return end

	self.Connected = true
	self._Connect()
end

function ConnectionObject:Disconnect()
	if not self.Connected then return end

	self.Connected = false
	self._Disconnect()
end

-- // SignalObject Functions
function SignalObject:Wait()
	local Coroutine = coroutine.running()

	table.insert(self._Yield, Coroutine)
	return coroutine.yield()
end

function SignalObject:Connect(Callback)
	local Connection = SignalModule.newConnection(function()
		table.insert(self._Tasks, Callback)
	end, function()
		for Index, TaskCallback in ipairs(self._Tasks) do
			if TaskCallback == Callback then
				return table.remove(self._Tasks, Index)
			end
		end
	end)

	Connection:Reconnect()
	return Connection
end

function SignalObject:Fire(...)
	for _, TaskCallback in ipairs(self._Tasks) do
		local Callback = TaskCallback

		if self.UseCoroutines then
			Callback = coroutine.wrap(Callback)
		end

		Callback(...)
	end

	for _, YieldCoroutine in ipairs(self._Yield) do
		coroutine.resume(YieldCoroutine, ...)
	end

	self._Yield = { }
end

-- // SignalModule Functions
function SignalModule.newConnection(ConnectCallback, disconnectCallback)
	return setmetatable({ 
		_Connect = ConnectCallback, 
		_Disconnect = disconnectCallback, 
		Connected = false
	}, ConnectionObject)
end

function SignalModule.new()
	local self = setmetatable({ 
		_Tasks = { }, _Yield = { },
		UseCoroutines = true
	}, SignalObject)

	return self
end

local JanitorModule = { }
local JanitorObject = { Name = "Janitor" }

local _type = typeof or type

JanitorObject.__index = JanitorObject

-- // JanitorObject Functions
function JanitorObject:Give(DynamicObject)
	table.insert(self._Trash, DynamicObject)
end

function JanitorObject:Remove(DynamicObject)
	for Index, LocalDynamicObject in ipairs(self._Trash) do
		if LocalDynamicObject == DynamicObject then
			return table.remove(self._Trash, Index)
		end
	end
end

function JanitorObject:Deconstructor(Type, Callback)
	self._Deconstructors[Type] = Callback
end

function JanitorObject:Clean()
	for _, DynamicTrashObject in ipairs(self._Trash) do
		local DynamicTrashType = _type(DynamicTrashObject)

		if self._Deconstructors[DynamicTrashType] then
			self._Deconstructors[DynamicTrashType](DynamicTrashObject)
		end
	end
end

-- // JanitorModule Functions
function JanitorModule.new()
	local self = setmetatable({ 
		_Deconstructors = { },
		_Trash = { }
	}, JanitorObject)

	self:Deconstructor("function", function(Object)
		return Object() 
	end)

	return self
end



local args = {}
args.__index = args
args._cmds = {}
args._i = 1

local valid_arg_types = {'string', 'number', 'boolean'}

local function str_to_bool(s)
	if _type(s) ~= 'string' then
		return nil
	end
	if s == 'false' then
		return false
	elseif s == 'true' then
		return true
	else
		return nil
	end
end

local function str_to_int(s)
	local number = tonumber(s)
	if number == nil then
		return nil
	end

	return math.floor(number)
end

local function tbl_contains_value(t, val)
	for _, v in pairs(t) do
		if v == val then
			return true
		end
	end
	return false
end

local function tbl_count(t)
	local i = 0
	for _k, _v in pairs(t) do
		i = i + 1
	end
	return i
end

function args:add_command(cmd_name, type_info, flags, nargs, required, help, default)
	assert(_type(cmd_name) == 'string')
	assert(_type(type_info) == 'string')
	assert(tbl_contains_value(valid_arg_types, type_info), 'invalid argument type')
	assert(_type(nargs) == 'string' or _type(nargs) == 'number')
	assert(flags ~= nil and _type(flags) == 'table', 'flags must be a valid table')
	assert(_type(required) == 'boolean')
	assert(_type(help) == 'string')
	local cmd = {
		name = cmd_name,
		type_info = type_info,
		flags = flags,
		nargs = nargs,
		required = required,
		help = help,
		default = default
	}
	assert(self._cmds[self._i] == nil)
	self._cmds[self._i] = cmd
	self._i = self._i + 1
end

local function cmd_type_mismatch_error(input, cmd)
	error(
		string.format(
			'expected value: %d to be of type %q for command %q',
			input,
			cmd.type_info,
			cmd.name
		)
	)
end

local function get_arg_converter_fn(type_info_str)
	if type_info_str == 'number' then
		return tonumber
	elseif type_info_str == 'integer' then
		return str_to_int
	elseif type_info_str == 'string' then
		return function(x) return x end
	elseif type_info_str == 'boolean' then
		return str_to_bool
	else
		return function(x) return nil end
	end
end

local function collect_cmd_args(cmd_flags, i, inputs, matching_cmd, cmds)
	local min_required_nargs = 0
	local max_nargs = 256
	-- check matching_cmd.nargs
	if _type(matching_cmd.nargs) == 'string' then
		if matching_cmd.nargs == '+' then
			min_required_nargs = 1
		elseif matching_cmd.nargs == '*' then
			min_required_nargs = 0
		else
			error(string.format('invalid nargs field: %q provided for %q', matching_cmd.nargs, matching_cmd.name))
		end
	elseif _type(matching_cmd.nargs) == 'number' then
		assert(
			matching_cmd.nargs > -1,
			string.format('invalid nargs value provided for command: %q. nargs must be a whole number', matching_cmd.name)
		)
		min_required_nargs = matching_cmd.nargs
		max_nargs = matching_cmd.nargs
	end
	local converter_fn = get_arg_converter_fn(matching_cmd.type_info)
	local cmd_args = {}
	local num_args = 0
	-- process up until the next command is identified
	local num_inputs = tbl_count(inputs)
	while num_args < max_nargs and i < num_inputs and cmd_flags[inputs[i]] == nil and inputs[i] ~= nil do
		local value = converter_fn(inputs[i])
		if not value then cmd_type_mismatch_error(inputs[i], matching_cmd) end
		local next = num_args + 1
		cmd_args[next] = value
		num_args = next
		i = i + 1
	end

	if max_nargs == 0 then
		cmds[matching_cmd.name] = true
		return i
	end

	assert(min_required_nargs <= num_args and num_args <= max_nargs, string.format('invalid number of arguments provided for command: %q', matching_cmd.name))
	if num_args > 0 then
		cmds[matching_cmd.name] = cmd_args
	else
		if _type(matching_cmd.default) ~= matching_cmd.type_info then
			error(
				string.format(
					'default argument %q type does not match the specified type: %q',
					tostring(matching_cmd.default),
					matching_cmd.type_info
				)
			)
		end
		cmds[matching_cmd.name] = { matching_cmd.default }
	end

	-- return the previous idx so that the next cmd_flag can be properly processed
	return i - 1
end

function args:parse(inputs)
	assert(_type(inputs) == 'table')
	-- build a lookup table
	-- flag -> argument_idx
	local cmd_flags = {}
	for i, c in ipairs(self._cmds) do
		for _, f in pairs(c.flags) do
			cmd_flags[f] = i
		end
	end

	local cmds = {}
	local i = 1
	local num_inputs = tbl_count(inputs) + 1
	while i < num_inputs do
		local matching_cmd_idx = cmd_flags[inputs[i]]
		if matching_cmd_idx then
			i = collect_cmd_args(cmd_flags, i+1, inputs, self._cmds[matching_cmd_idx], cmds)
		end
		i = i + 1
	end
	for _, cmd in pairs(self._cmds) do
		if cmd.required then
			assert(cmds[cmd.name] ~= nil, string.format('missing required command %q', cmd.name))
		end
	end

	return cmds
end

local array = {}


local err_idx_out_bounds = 'index out of bounds'
local err_idx_invalid = 'index invalid, must be an int'


function array.__index(t, k)
--	print('indexing table with key', k)
	if _type(k) == 'number' then
		assert(math.floor(k) == k, err_idx_invalid)
		assert(0 < k and k <= t._len, err_idx_out_bounds)
		return rawget(t, k)
	else
		return array[k]
	end
end


function array.__newindex(t, k, v)
--	print('new index table with key, value', k, v)
	assert(false, '__newindex not supported, use insert* functions')
end


function array:length()
	return self._len
end


function array.new(t)
	local _t = t or {}
	local a = { _len = #_t }
	for i=1, a._len do
		rawset(a, i, t[i])
	end
	setmetatable(a, array)
	return a
end


function array:insert(e)
	self._len = self._len + 1
	rawset(self, self._len, e)
end


function array:insert_at(e, i)
	assert(1 <= i and i <= self._len, err_idx_out_bounds)
	for j = self._len, i, -1 do
		rawset(self, j+1, rawget(self, j))
	end
	rawset(self, i, e)
	self._len = self._len + 1
end


function array:insert_range_at(arr, idx)
	assert(getmetatable(arr) == array)
	assert(1 <= idx and idx <= self._len, err_idx_out_bounds)
	for j = idx, self._len do
		local new_idx = j + arr._len
		rawset(self, new_idx, rawget(self, j))
	end

	for j = 1, arr._len do
		local new_idx = idx + j - 1
		rawset(self, new_idx, rawget(arr, j))
	end
	self._len = self._len + arr._len
end


function array:index_of(e, start_idx, end_idx)
	local s_idx = start_idx or 1
	local e_idx = end_idx or self._len
	assert(1 <= s_idx and s_idx <= e_idx, err_idx_out_bounds)
	assert(s_idx <= e_idx and e_idx <= self._len, err_idx_out_bounds)

	for j = s_idx, e_idx do
		if rawget(self, j) == e then
			return j
		end
	end
	return -1
end


function array:contains(e)
	local idx = self:index_of(e, 1, self._len)
	return idx ~= -1
end


function array:last_index_of(e, start_idx, end_idx)
	local s_idx = start_idx or 1
	local e_idx = end_idx or self._len
	assert(1 <= s_idx and s_idx <= e_idx, err_idx_out_bounds)
	assert(s_idx <= e_idx and e_idx <= self._len, err_idx_out_bounds)

	for j = e_idx, s_idx, -1 do
		if rawget(self, j) == e then
			return j
		end
	end
	return -1
end


function array:clone()
	local a = array.new()
	for j = 1, self._len do
		rawset(a, j, rawget(self, j))
	end
	a._len = self._len
	return a
end


function array:remove_at(i)
	assert(1 <= i and i <= self._len, err_idx_out_bounds)
	for j = i, self._len do
		rawset(self, j, rawget(self, j+1))
	end
	self._len = self._len - 1
end


function array:remove(e)
	local found_idx = self:index_of(e)
	assert(found_idx ~= -1, 'element not found')

	for j = found_idx, self._len do
		rawset(self, j, rawget(self, j+1))
	end
	self._len = self._len - 1
end


function array:remove_range_at(start_idx, remove_count)
	if remove_count == 0 then
		return
	end
	local s_idx = start_idx
	local e_idx = s_idx + remove_count - 1
	assert(1 <= s_idx and s_idx <= e_idx, err_idx_out_bounds)
	assert(s_idx <= e_idx and e_idx <= self._len, err_idx_out_bounds)
	
	for i = s_idx, self._len do
		rawset(self, i, rawget(self, i + remove_count))
	end

	self._len = self._len - remove_count
end


function array:clear()
	for j = 1, self._len do
		rawset(self, j, nil)
	end
	self._len = 0
end


function array:reverse()
	local length = self._len
	local half_len = length / 2
	for j = 1, half_len do
		local swap_idx = length + 1 - j
		local tmp = rawget(self, j)
		rawset(self, j, rawget(self, swap_idx))
		rawset(self, swap_idx, tmp)
	end
end




local colors = {

	redHSV = {0, 1, 1},
	greenHSV = {120, 1, 1},
	blueHSV = {240, 1, 1},
	purpleHSV = {300, 1, 1},

	HSVtoRGB = function(c)
		 local H, S, V = table.unpack(c)
		 
		 local C = V * S
		 local X = C * ( 1 - math.abs( ( H / 60 )  % 2 - 1 ) )
		 m = V - C
		 
		 local rP, gP, bP
		 if 0 <= H and H < 60 then
			  rP, gP, bP = C, X, 0
		 elseif 60 <= H and H < 120 then
			  rP, gP, bP = X, C, 0
		 elseif 120 <= H and H < 180 then
			  rP, gP, bP = 0, C, X
		 elseif 180 <= H and H < 240 then
			  rP, gP, bP = 0, X, C
		 elseif 240 <= H and H < 300 then
			  rP, gP, bP = X, 0, C
		 elseif 300 <= H and H < 360 then
			  rP, gP, bP = C, 0, X
		 end
		 local r, g, b
		 r = (rP + m)
		 g = (gP + m)
		 b = (bP + m)
		 
		 return r, g, b
	end,
	
	RGBtoHSV = function(c)
		 local R, G, B = table.unpack(c)
		 
		 local H, S, V = 0, 0, 0
		 
		 local M, m = math.max(R, G, B), math.min(R, G, B)
		 if M == R then
			  H = 60 * (G - B)/(M - m)
		 elseif M == G then
			  H = 60 * (2 + (B - R)/(M - m) )
		 elseif M == B then
			  H = 60 * (4 + (R - G)/(M - m) )
		 end
		 H = H % 360
		 
		 if not M == 0 then
			  S = (M - m)/M
		 end
		 
		 V = M
		 
		 return H, S, V
	end,

	lerp = function(a, b, t)
		 local c = {}
		 for i = 1, #a do
			  table.insert(c, a[i] * t + b[i] * (1 - t))
		 end
		 return c
	end,

}

import = function() end
alert = alert
typed = type

	-- switch terms
switch = switch
case = case
default = default
					
	-- pro tools
wait = wait
read = io.read
arguments = args
array = array
class = middleclass

	-- a libraries
amath = math2
atable = Table
astring = String
tween = flux
	-- libraries
Color3 = colors
Mutex = mutex
Hook = HooksModule
Promise = PromiseModule
Signal = SignalModule
Janitor = JanitorModule
		
function import(keyword)
	local isWeb = keyword:split(1,1) == "@"
	if isWeb then warn("Importing from the web is not supported with your Voxel version") return else error("Unable to parse URL") return end
		
	local value = x or error(keyword.." was not found.")
	if not value then return end
	
	return value
end


-- @coolpro200021 ---
