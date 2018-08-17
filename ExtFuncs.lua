local t={}
local composer = require( "composer" ) 
local scene = composer.newScene() 
local nonTraversable={"*","a","c","d","f","g","h","i","j","k","l","n","o","p","q","r","N","A"} 
-- local nonTraversable={} 

t.hitTestObjects = function(obj1, obj2) 
   return obj1.contentBounds.xMin < obj2.contentBounds.xMax 
      and obj1.contentBounds.xMax > obj2.contentBounds.xMin 
      and obj1.contentBounds.yMin < obj2.contentBounds.yMax 
      and obj1.contentBounds.yMax > obj2.contentBounds.yMin 
end 

function Near(obj1,obj2,val)
	if obj1.x > obj2.x + val then
		return false
	end
	if obj1.x < obj2.x - val then
		return false
	end
	if obj1.y > obj2.y+ val then
		return false
	end
	if obj1.y < obj2.y - val then
		return false
	end
	return true
end

t.angleBetweenPoints = function( sX,sY,dX,dY) 
   local xDist, yDist = dX - sX, dY - sY 
   local angleBetween=math.deg(math.atan(yDist/xDist)) 
   if sX<dX then angleBetween=angleBetween + 180 else anlgeBetween=angleBetween-90 end 
   return angleBetween-180 
end 

t.rotateTo = function( point, degrees ) 
   local x, y = point.x, point.y 

   local theta = math.rad(degrees) 

   local pt = { 
         x = x * math.cos(theta) - y * math.sin(theta), 
         y = x * math.sin(theta) + y * math.cos(theta) 
   } 

   return pt 
end 

t.contains = function(val) 
   for i,value in pairs(nonTraversable) do 
      if value==val then 
         return true 
      end 
   end 
   return false 
end 


return t