local math = require("math")

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

return colors