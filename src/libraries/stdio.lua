--[[
	stdio.lua, automatically gets added to the script.
]]
-------------------------------------------------------------------------

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
			continue
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
	assert(type(Callback) == "function", "Expected Argument #1 function")

	self._PrefixCallback = Callback
end

function HookFunction:Postfix(Callback)
	assert(type(Callback) == "function", "Expected Argument #1 function")

	self._PostfixCallback = Callback
end

function HookFunction:Patch(Callback)
	assert(type(Callback) == "function", "Expected Argument #1 function")

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
function import(keyword)
	local isWeb = keyword:split(1,1) == "@"
	if isWeb then warn("Importing from the web is not supported with your Voxel version") return end
	local x
	pcall(function()
		x = require("src/libraries/"..keyword)
	end)
	pcall(function()
		x = require(keyword)
	end)
	return x or error(keyword.." was not found.")
end
local dbs = {
	-- special
	import = import

	-- switch terms
	switch = switch,
	case = case,
	default = default,
					
	-- pro tools
	wait = wait,
	read = io.read,

	-- libraries
	mutex = mutex,
	hook = HooksModule,
	promise = PromiseModule,
	signal = SignalModule,
	janitor = JanitorModule,
	librarian = {},
}

function dbs.Libarian:AddHighliter(name, content)
	if dbs[name] then error("Attempt to modify an existing Highliter.") return end
	dbs[name] = content
end
function dbs.Libarian:GetHighliters()
	local dsxs = {}
	for i, v in ipairs(dbs) do
		dsxs[#dsxs+1] = i
	end
	return dsxs
end			
return dbs





-- @coolpro200021 ---
