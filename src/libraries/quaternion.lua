--A simple (unfinished) quaternion library


local labels = {"re", "i", "j", "k"}
local function quatIterator(a, b)
     local i = 0
     return    function()
                    i = i+1
                    local l = labels[i]
                    if l then
                         return l, a[ l ], b[ l ]
                    end
                    return
               end
end

local quaternion = {}
local quaternionMt

quaternion.new = function(re, i, j, k)
     local newQ = {re = re or 0, i = i or 0, j = j or 0, k = k or 0}
     setmetatable( newQ, quaternionMt )
     return newQ
end

quaternionMt = {
     __metatable = "Quaternion",
     __index = {
          conjugate = function(self)
               return quaternion.new( self.re, -self.i, -self.j, -self.k )
          end,
          magnitude = function(self)
               return math.sqrt( self.re^2 + self.i^2 + self.j^2 + self.k^2 )
          end,
          norm = magnitude,
          normalize = function(self)
               local m = self:magnitude()
               return quaternion.new( self.re/m, self.i/m, self.j/m, self.k/m )
          end,
          inverse = function(self)
               return self:conjugate() * (1/self:magnitude()^2)
          end,
          vector = function(self)
               return quaternion.new( 0, self.i, self.j, self.k )
          end,
          imag = vector,
     },
     __tostring = function(a)
          return a.re..((a.i>=0 and "+"..a.i) or a.i).."i"..((a.j>=0 and "+"..a.j) or a.j).."j"..((a.k>=0 and "+"..a.k) or a.k).."k"
     end,
     __add = function(a, b)
          local newQ = {}
          for l, acomp, bcomp in quatIterator(a, b) do
               newQ[l] = acomp + bcomp
          end
          setmetatable(newQ, quaternionMt)
          return newQ
     end,
     __unm = function(a)
          return quaternion.new( -a.re, -a.i, -a.j, -a.k )
     end,
     __sub = function(a, b)
          local newQ = {}
          for l, acomp, bcomp in quatIterator(a, b) do
               newQ[l] = acomp - bcomp
          end
          setmetatable(newQ, quaternionMt)
          return newQ
     end,
     __mul = function(a, b)
          -- i^2 = j^2 = k^2 = ijk = -1
          -- ij = -ji etc.
          if type(a) == "number" then
               a = quaternion.new(a, 0, 0 ,0)
          elseif type(b) == "number" then
               b = quaternion.new(b, 0, 0, 0)
          end
          return quaternion.new( 
               a.re * b.re - a.i * b.i  - a.j * b.j  - a.k * b.k , --real
               a.re * b.i  + a.i * b.re + a.j * b.k  - a.k * b.j , --i
               a.re * b.j  - a.i * b.k  + a.j * b.re + a.k * b.i , --j
               a.re * b.k  + a.i * b.j  - a.j * b.i  + a.k * b.re  --k
          )
     end
}


return quaternion