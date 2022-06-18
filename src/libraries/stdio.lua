--[[
	stdio.lua, automatically gets added to the script.
]]
-------------------------------------------------------------------------
-- Functions
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
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number from 0 to 1") end
	return Random.new():NextNumber() < x
end

function math2.sd(x,PopulationToggle)
	if type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	if type(PopulationToggle) ~= 'boolean' and PopulationToggle ~= nil then return warn("Make sure parameter 2 is set to nil or a boolean") end
	if PopulationToggle == nil then PopulationToggle = false end
	local s = 0
	local ss = pcall(function()
		for i,v in pairs(x) do s += v end
	end)
	if not s then return warn("Make sure all values in the table are numbers") end 
	local avg = s/#x
	local t = 0
	for i,v in pairs(x) do t += (v - avg)^2 end
	if not PopulationToggle then
		return math.sqrt(t/(#x-1))
	else
		return math.sqrt(t/(#x))
	end
end



function math2.min(x) 
	if type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	local s = pcall(function()
		table.sort(x,function(a,b)
			return a < b
		end)
	end)
	if not s then return warn("Make sure all values in the table are numbers") end
	return x[1]
end

function math2.median(x) 
	if type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
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
	if type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
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
	if type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
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
	if type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	local s = pcall(function()
		table.sort(x,function(a,b)
			return a > b
		end)
	end)
	if not s then return warn("Make sure all values in the table are numbers") end
	return x[1]
end

function math2.iqr(x)
	if type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	local s = pcall(function()
		table.sort(x,function(a,b)
			return a < b
		end)
	end)
	if not s then return warn("Make sure all values in the table are numbers") end
	return math2.q3(x)-math2.q1(x)
end

function math2.range(x)
	if type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	local s = pcall(function()
		table.sort(x,function(a,b)
			return a < b
		end)
	end)
	if not s then return warn("Make sure all values in the table are numbers") end
	return math2.max(x)-math2.min(x)
end

function math2.mode(x)
	if type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	local mostFrequent = {}
	local s = pcall(function()
		for i,v in pairs(x) do
			if mostFrequent[tostring(v)] ~= nil then
				mostFrequent[tostring(v)] += 1
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
	if type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	local avg = 0
	local s = pcall(function()
		for i,v in pairs(x) do
			avg += v/#x
		end
	end)
	
	if not s then return warn("Make sure all values in the table are numbers") end
	local s = 0
	for i=1,#x do
		s += math.abs(x[i]-avg)
	end
	return s/#x
end

function math2.avg(x)
	if type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	local avg = 0
	
	local s = pcall(function()
		for i,v in pairs(x) do
			avg += v/#x
		end
	end)
	if not s then return warn("Make sure all values in the table are numbers") end
	return avg
end

function math2.zscore(x,PopulationToggle)
	if PopulationToggle == nil then PopulationToggle = false end
	if type(x) ~= 'table' then return warn("Make sure parameter 1 is a table") end
	if type(PopulationToggle) ~= 'boolean' and PopulationToggle ~= nil then return warn("Make sure parameter 2 is set to nil or a boolean") end
	
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
	if type(a) ~= 'number' and type(b) ~= 'number' then return warn("Make sure parameter 1 and 2 are both numbers") end 
	if type(a) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if type(b) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	a = math.min(a,b)
	b = math.max(a,b)
	local q = math.floor(b/a)
	local r = b-(a*q)
	if r == 0 then return a end 
	return math2.gcd(r,a)
end

function math2.lcm(a,b)
	if type(a) ~= 'number' and type(b) ~= 'number' then return warn("Make sure parameter 1 and 2 are both numbers") end 
	if type(a) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if type(b) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	return math.abs(a*b)/math2.gcd(a,b)
end

function math2.floor(x,NearestDecimal)
	if NearestDecimal == nil then NearestDecimal = 0 end
	if type(x) ~= 'number' and type(NearestDecimal) ~= 'number' then return warn("Make sure parameter 1 and 2 are both numbers") end 
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if type(NearestDecimal) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	return math.floor(x*10^NearestDecimal)/10^NearestDecimal
end

function math2.round(x,NearestDecimal)
	if NearestDecimal == nil then NearestDecimal = 0 end
	if type(x) ~= 'number' and type(NearestDecimal) ~= 'number' then return warn("Make sure parameter 1 and 2 are both numbers") end 
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if type(NearestDecimal) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	return math.round(x*10^NearestDecimal)/10^NearestDecimal
end

function math2.ceil(x,NearestDecimal)
	if NearestDecimal == nil then NearestDecimal = 0 end
	if type(x) ~= 'number' and type(NearestDecimal) ~= 'number' then return warn("Make sure parameter 1 and 2 are both numbers") end 
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if type(NearestDecimal) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	return math.ceil(x*10^NearestDecimal)/10^NearestDecimal
end

function math2.factors(x)
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
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

	if type(Index) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if type(Iterations) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	if Iterations%1 ~= 0 then return warn("Make sure parameter 2 is an integer") end 
	if type(Func) ~= 'function' then return warn("Make sure parameter 3 is a function") end 

	local new = Input
	for i=1,Iterations do
		new = Func(new)
	end
	return math.round(new*10e11)/10e11
end

function math2.nthroot(x,Index)

	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if type(Index) ~= 'number' then return warn("Make sure parameter 2 is a number") end 

	return x^(1/Index)
end

function math2.fibonacci(x)
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if x%1 ~= 0 then return warn("Make sure parameter 1 is an integer") end 
	return math.round((((1+math.sqrt(5))/2)^x-((1-math.sqrt(5))/2)^x)/math.sqrt(5))
end

function math2.lucas(x)
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if x%1 ~= 0 then return warn("Make sure parameter 1 is an integer") end 
	return math.round((((1+math.sqrt(5))/2)^x-((1-math.sqrt(5))/2)^x)/math.sqrt(5)+(((1+math.sqrt(5))/2)^(x-2)-((1-math.sqrt(5))/2)^(x-2))/math.sqrt(5))
end


-- Useless

function math2.digitadd(x)
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if x%1 ~= 0 then return warn("Make sure parameter 1 is an integer") end 
	
	local t = string.split(x,'')
	local s = 0
	for i,v in pairs(t) do
		s += v
	end
	return s
end

function math2.digitmul(x)
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if x%1 ~= 0 then return warn("Make sure parameter 1 is an integer") end 
	local t = string.split(x,'')
	local s = 0
	for i,v in pairs(t) do
		s *= v
	end
	return s
end

function math2.digitrev(x)
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
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
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	local neg = false
	if x < 0 then x = math.abs(x) neg = true end
	local nums = string.split(x,'')
	local num = ''
	local digits = math.floor(math.log10(x))+1
	for i,v in pairs(nums) do
		if (digits-i)%3 == 0 and digits-i ~= 0 then
			num ..= v..','
		else
			num ..= v
		end
	end
	if neg then return '-'..num end 
	return num
end

function math2.fromComma(x)
	if type(x) ~= 'string' then return warn("Make sure parameter 1 is a string") end 
	local a = string.gsub(x,',','')
	return a
end

function math2.toKMBT(x,NearestDecimal)
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
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
	if type(x) ~= 'string' then return warn("Make sure parameter 1 is a string") end 
	if tonumber(x) then return x end
	local list = {'','K','M','B','T','Qa','Qi','Sx','Sp','Oc','No','Dc','Udc','Ddc','Tdc'}
	local splits = string.split(x,'')
	local letter = splits[string.find(x,'%a')]
	local factor = 10^((table.find(list,letter)-1)*3)
	if neg then return tonumber('-'..string.split(x,letter)[1]*factor) end
	return string.split(x,letter)[1]*factor
end

function math2.toScientific(x,Base)
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if type(Base) ~= 'number' and Base ~= nil then return warn("Make sure parameter 2 is a number or nil") end 
	local neg = false
	if x < 0 then neg = true x = math.abs(x) end
	if Base == nil then Base = 10 end
	local power = math.floor(math.log(x,Base))
	local constant = x/Base^power
	if neg then return -constant..' * ' ..Base..'^'.. power end
	return constant..' * ' ..Base..'^'.. power
end

function math2.fromScientific(x)
	if type(x) ~= 'string' then return warn("Make sure parameter 1 is a string") end 
	local constant = tonumber(string.split(x,'*')[1])
	local base = tonumber(string.split(string.split(x,'*')[2],'^')[1])
	local power = tonumber(string.split(string.split(x,'*')[2],'^')[2])
	return constant*base^power
end
function math2.toNumeral(x)
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
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
					x -= int
				end
			end
		end
		return roman
end

function math2.fromNumeral(x)
	if type(x) ~= 'string' then return warn("Make sure parameter 1 is a string") end 
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
			decimal += (Z2 - Z1)
			num += 2
		else
			decimal += Z1
			num += 1
		end
	end
	if num <= numeralLength then decimal += numberMap[string.sub(x, num, num)] end
	return decimal
end

function math2.toPercent(x,NearestDecimal)
	if NearestDecimal == nil then NearestDecimal = 15 end
	if type(x) ~= 'number' and type(NearestDecimal) ~= 'number' then return warn("Make sure parameter 1 and 2 are both numbers") end 
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if type(NearestDecimal) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	return math.round(x*100*10^NearestDecimal)/10^NearestDecimal
end

function math2.fromPercent(x)
	if type(x) ~= 'string' then return warn("Make sure parameter 1 is a string") end 
	local n
	local s = pcall(function()
		n = string.split(x,'%')[1]
	end)
	if not s then return warn('Make sure parameter 1 is in the form "N%"') end
	return n/100
end

function math2.toFraction(x,MixedToggle)
	if MixedToggle == nil then MixedToggle = false end
	if type(x) ~= 'number' and type(MixedToggle) ~= 'boolean' then return warn("Make sure parameter 1 is a number and parameter 2 is a boolean") end 
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if type(MixedToggle) ~= 'boolean' then return warn("Make sure parameter 2 is a boolean") end 
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
	if type(x) ~= 'string' then return warn("Make sure parameter 1 is a string") end 
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
	if type(x) ~= 'number' and type(AMPMToggle) ~= 'boolean' then return warn("Make sure parameter 1 is a number from 0-24 and parameter 2 is a boolean") end 
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number from 0-24") end 
	if type(AMPMToggle) ~= 'boolean' then return warn("Make sure parameter 2 is a boolean") end 
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

function math2.fromTime(x)
	if type(x) ~= 'string' then return warn("Make sure parameter 1 is a string") end 
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

	if type(Base) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if type(CurrentBase) ~= 'number' then return warn("Make sure parameter 1 is a number") end 

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
			sum += (v*(b1^(#nums-i)))
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
	if type(a) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if type(b) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	if type(c) ~= 'number' then return warn("Make sure parameter 3 is a number") end 
	return -b/(2*a),-b^2/(4*a)+c
end

function math2.solver(f) -- can solve any function equal to 0
	if type(f) ~= 'function' then return warn("Make sure parameter 1 is a function with 1 parameter") end 
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
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if type(Function) ~= 'function' then return warn("Make sure parameter 2 is a function") end 
	return (Function(x+1e-12)-Function(x))/1e-12
end

function math2.integral(Lower,Upper,Function)
	if type(Lower) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if type(Upper) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	if type(Function) ~= 'function' then return warn("Make sure parameter 3 is a function") end 
	local s = 0
	local n = false
	if Upper < 0 then
		n = true
		Upper=math.abs(Upper)
	end
	for i=Lower,Upper,1e-5 do
		s += Function(i)*1e-5
	end
	if n then return -s else return s end
end

function math2.limit(x,Function)
	if type(x) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if type(Function) ~= 'function' then return warn("Make sure parameter 2 is a function") end 
	return math.floor(Function(x+1e-13)*10^12)/10^12
end

function math2.summation(Start,Finish,Function)
	if Function == nil then
		Function = function(x)
			return x
		end
	end
	if type(Start) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if type(Finish) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	if type(Function) ~= 'function' then return warn("Make sure parameter 3 is a function") end 
	local sum = 0
	for i=Start,Finish do
		sum += Function(i)
	end
	return sum
end

function math2.product(Start,Finish,Function)
	if type(Start) ~= 'number' then return warn("Make sure parameter 1 is a number") end 
	if type(Finish) ~= 'number' then return warn("Make sure parameter 2 is a number") end 
	if type(Function) ~= 'function' then return warn("Make sure parameter 3 is a function") end 
	local sum = 0
	for i=Start,Finish do
		sum *= Function(i)
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
	arguments = args,
	array = array,
	admath = math2,

	-- libraries
	mutex = mutex,
	hook = HooksModule,
	promise = PromiseModule,
	signal = SignalModule,
	janitor = JanitorModule,
	librarian = {},
}

function dbs.librarian:AddHighliter(name, content)
	if dbs[name] then error("Attempt to modify an existing Highliter.") return end
	dbs[name] = content
end
function dbs.librarian:GetHighliters()
	local dsxs = {}
	for i, v in ipairs(dbs) do
		dsxs[#dsxs+1] = i
	end
	return dsxs
end			
return dbs





-- @coolpro200021 ---
