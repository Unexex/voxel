--A simple complex number library

local math = require("math")

local complex = {}
complex.new = function() end

local complexMT = {
     __metatable = "Complex",
     __index = {
          magnitude = function(self)
               return math.sqrt( self.re^2 + self.im^2 )
          end,
          argument = function(self)
               return math.atan2( self.im, self.re )
          end,
          conjugate = function(self)
               return complex.new( self.re, -self.im )
          end,
     },
     __tostring = function(a)
          return a.re..((a.im>=0 and "+"..a.im) or a.im).."i"
     end,
     __add = function(a, b)
          if type(a) == "number" then
               a = complex.new(a, 0)
          elseif type(b) == "number" then
               b = complex.new(b, 0)
          end
          return complex.new( a.re + b.re, a.im + b.im )
     end,
     __sub = function(a, b)
          if type(a) == "number" then
               a = complex.new(a, 0)
          elseif type(b) == "number" then
               b = complex.new(b, 0)
          end
          return complex.new( a.re - b.re, a.im - b.im )
     end,
     __unm = function(a)
          return complex.new( -a.re, -a.im )
     end,
     __mul = function(a, b)
          if type(a) == "number" then
               a = complex.new(a, 0)
          elseif type(b) == "number" then
               b = complex.new(b, 0)
          end
          return complex.new( a.re*b.re - a.im*b.im, a.re*b.im + a.im*b.re )
     end,
     __div = function(a, b)
          if type(a) == "number" then
               a = complex.new(a, 0)
          elseif type(b) == "number" then
               b = complex.new(b, 0)
          end
          return (a * b:conjugate()) * (1 / (b:magnitude())^2 )
     end
}

function complex.new(real, imaginary)
     newComplex = {re = real, im = imaginary}
     --all the functionality of these comes from the metatable
     setmetatable(newComplex, complexMT)
     return newComplex
end

function complex.exp(z)
     local x, y = z.re, z.im
     return complex.new( math.exp( x ) * math.cos( y ), math.exp( x ) * math.sin( y ) )
end

function complex.cos(z)
     local x, y = z.re, z.im
     return complex.new( math.cos( x ) * math.cosh( y ), -math.sin( x ) * math.sinh( y ) )
end

function complex.sin(z)
     local x, y = z.re, z.im
     return complex.new( math.sin( x ) * math.cosh( y ), math.cos( x ) * math.sinh( y ) )
end

function complex.tan(z)
     --refactor later
     local x, y = z.re, z.im
     return complex.sin(z) / complex.cos(z)
end

function complex.sinh(z)
     local x, y = z.re, z.im
     return complex.new( (math.exp( x ) * math.cos(x) - math.exp( -x ) * math.cos(y))/2, (math.exp( x ) * math.sin(x) + math.exp( -x ) * math.sin(y)) / 2 )
end

function complex.cosh(z)
     local x, y = z.re, z.im
     return complex.new( (math.exp( x ) * math.cos(x) + math.exp( -x ) * math.cos(y))/2, (math.exp( x ) * math.sin(x) - math.exp( -x ) * math.sin(y)) / 2 )
end


return complex