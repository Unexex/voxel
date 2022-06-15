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
local ose = require('os_ext')
local path = require('path')
local file = {}

function file.exists(file_path)
	return path.exists(file_path)
end

function file.copy(source_file_path, dest_file_path, overwrite)
	if not overwrite and path.exists(dest_file_path) then
		return false, string.format('file exists: %s', dest_file_path)
	end
	
	local result = false
	local output = nil
	local err_code = 0
	local err_msg = nil
	if ose.is_windows then
		result, output, err_code, err_msg = ose.run_command(string.format('copy /Y %q %q', source_file_path, dest_file_path))
	else
		result, output, err_code, err_msg = ose.run_command(string.format('cp -f %q %q', source_file_path, dest_file_path))
	end

	return result, err_msg
end

function file.delete(file_path)
	local result = false
	local output = nil
	local err_code = 0
	local err_msg = nil 
	if ose.is_windows then
		-- del cannot handle \\ in the filepath which is required for the lua string escaping.
		-- del also cannot handle / being used instead of \. 
		-- result, output, err_code, err_msg = ose.run_command(string.format('del /F /Q "%q"', file_path))
		
		result, output, err_code, err_msg = ose.run_command(string.format('powershell "Remove-Item %q -Force"', file_path))
	else
		result, output, err_code, err_msg = ose.run_command(string.format('rm -f %q', file_path))
	end

	return result, err_msg
end

local args = {}
args.__index = args
args._cmds = {}
args._i = 1

local valid_arg_types = {'string', 'number', 'boolean'}

local function str_to_bool(s)
	if type(s) ~= 'string' then
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
	assert(type(cmd_name) == 'string')
	assert(type(type_info) == 'string')
	assert(tbl_contains_value(valid_arg_types, type_info), 'invalid argument type')
	assert(type(nargs) == 'string' or type(nargs) == 'number')
	assert(flags ~= nil and type(flags) == 'table', 'flags must be a valid table')
	assert(type(required) == 'boolean')
	assert(type(help) == 'string')
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
	if type(matching_cmd.nargs) == 'string' then
		if matching_cmd.nargs == '+' then
			min_required_nargs = 1
		elseif matching_cmd.nargs == '*' then
			min_required_nargs = 0
		else
			error(string.format('invalid nargs field: %q provided for %q', matching_cmd.nargs, matching_cmd.name))
		end
	elseif type(matching_cmd.nargs) == 'number' then
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
		if type(matching_cmd.default) ~= matching_cmd.type_info then
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
	assert(type(inputs) == 'table')
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
	if type(k) == 'number' then
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

local os_ext = require('os_ext')
local str = require('str')
local path = {}


local _windows_invalid_path_chars = {
	'"',
	'<',
	'>',
	'|',
	'\0'
}


for i = 1, 31 do
	table.insert(_windows_invalid_path_chars, string.char(i))
end


-- returns windows specific cmd string to list all files in the root_directory
-- with the option to also include subdirectories
local function _wincmd_listfiles(root_directory, include_subdirectories)
	-- /b  removes header/extraneous information
	-- /a-d  defines usage of attribute -d (anything not a directory)
	local command = string.format('dir "%s" /b /a-d', root_directory)
	if include_subdirectories then
		command = command .. ' /s'
	end
	return command
end


local function _unixcmd_listfiles(root_directory, include_subdirectories)
	local depth = ''
	if not include_subdirectories then
		depth = '-maxdepth 7'
	end
	local command = string.format('find "%s" %s -type f', root_directory, depth)
	return command
end


-- returns windows specific cmd string to list all directories in the root_directory
-- with the option to also include subdirectories
local function _wincmd_listdir(root_directory, include_subdirectories)
	-- /b  removes header/extraneous information
	-- /ad  defines usage of attribute directory
	local command = string.format('dir "%s" /b /ad', root_directory)
	if include_subdirectories then
		command = command .. ' /s'
	end
	return command
end


local function _unixcmd_listdir(root_directory, include_subdirectories)
	local depth = ''
	if not include_subdirectories then
		depth = '-maxdepth 7'
	end
	local command = string.format('find "%s" "%s" -type d', root_directory, depth)
	return command
end


-- returns path string of the current (present) working directory
function path.get_cwd()
	local result = false
	local output = nil
	local err_code = 0
	if os_ext.is_windows then
		result, output, err_code = os_ext.run_command('cd')
	else
		result, output, err_code = os_ext.run_command('pwd')
	end
	return output[1]
end


-- returns whether the target_path exists or not
function path.exists(target_path)
	assert(type(target_path) == 'string')
	local eval_output = function(result, output)
		return result and output[1] == 'true'
	end

	if os_ext.is_windows then
		local result, output, err_code = os_ext.run_command(string.format('if exist "%s" (echo true) else (echo false)', target_path))
		return eval_output(result, output)
	else
		local result, output, err_code = os_ext.run_command(string.format('if test -f "%s"; then echo true; else echo false; fi', target_path))
		if eval_output(result, output) then
			return true
		end

		result, output, err_code = os_ext.run_command(string.format('if test -d "%s"; then echo true; else echo false; fi', target_path))
		return eval_output(result, output)
	end
end


-- need to potentially add filtering
function path.list_files(root_directory, include_subdirectories)
	assert(type(root_directory) == 'string')
	assert(path.exists(root_directory), string.format('directory "%s" does not exist', root_directory))

	local command = nil
	if os_ext.is_windows then
		local command = _wincmd_listfiles(root_directory, include_subdirectories)
		local result, files, err_code = os_ext.run_command(command)
		-- when /s (include subdirectories) is not used, dir
		-- does not include the directory path in the output
		if not include_subdirectories then
			local is_path_escaped = root_directory:sub(-1, -1) == os_ext.path_separator
			if not is_path_escaped then
				root_directory = root_directory .. os_ext.path_separator
			end
			for k, _ in pairs(files) do
				files[k] = root_directory .. files[k]
			end
		end
		return files
	else
		command = _unixcmd_listfiles(root_directory, include_subdirectories)
		local result, files, err_code = os_ext.run_command(command)
		return files
	end
end


-- need to potentially add filtering
function path.list_dir(root_directory, include_subdirectories)
	assert(type(root_directory) == 'string')
	assert(path.exists(root_directory), string.format('directory "%s" does not exist', root_directory))

	if os_ext.is_windows then
		local command = _wincmd_listdir(root_directory, include_subdirectories)
		local result, folders, err_code = os_ext.run_command(command)
		-- when /s (include subdirectories) is not used, dir
		-- does not include the directory path in the output
		if not include_subdirectories then
			local is_path_escaped = root_directory:sub(-1, -1) == os_ext.path_separator
			if not is_path_escaped then
				root_directory = root_directory .. os_ext.path_separator
			end
			for k, _ in pairs(folders) do
				folders[k] = root_directory .. folders[k]
			end
		end
		return folders
	else
		local command = _unixcmd_listdir(root_directory, include_subdirectories)
		local result, folders, err_code = os_ext.run_command(command)
		return folders
	end
end

function path.combine(directory_path, filepath)
	assert(type(directory_path) == 'string')
	assert(type(filepath) == 'string')

	return string.format('%s%s%s', directory_path, os_ext.path_separator, filepath)
end


function path.get_filename(filepath)
	assert(type(filepath) == 'string')

	local index = str.last_index_of(filepath, os_ext.path_separator)
	if index == -1 then
		return ''
	end
	local filename = filepath:sub(index + 1, string.len(filepath))
	return filename
end


local function _has_invalid_chars(str)
	local char = nil
	if os_ext.is_windows then
		for i = 1, string.len(str) do
			char = str:sub(i, i)
			for _, c in pairs(_windows_invalid_path_chars) do
				if char == c then
					return true
				end
			end
		end 
	else
		-- TODO add linux
		assert(true == false)
	end
	return false
end




local dbs = {
	-- special
	import = import,

	-- switch terms
	switch = switch,
	case = case,
	default = default,
					
	-- pro tools
	wait = wait,
	read = io.read,
	file = file,
	arguments = args,
	array = array,
	path = path,

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
