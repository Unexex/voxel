--Hello, Im putting this here in case bots reupload this module with a virus in it. Im PerfectlySquared, the original creator of this module. If you find any module that has the same asset under a different creator that is not me.

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


return math2 -- math is hard...