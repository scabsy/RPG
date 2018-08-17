local math_sqrt = math.sqrt

local Collision = {}


-----------------------------------------------------------------------------
-- HasCollidedRect( obj1, obj2 )
-- Check if the rectangle boundaries of two objects do overlap
-----------------------------------------------------------------------------
function Collision:HasCollidedRect( obj1, obj2 )
    if ( obj1 == nil ) then  --make sure the first object exists
        return false
    end
    if ( obj2 == nil ) then  --make sure the other object exists
        return false
    end

    local left = obj1.contentBounds.xMin <= obj2.contentBounds.xMin and obj1.contentBounds.xMax >= obj2.contentBounds.xMin
    local right = obj1.contentBounds.xMin >= obj2.contentBounds.xMin and obj1.contentBounds.xMin <= obj2.contentBounds.xMax
    local up = obj1.contentBounds.yMin <= obj2.contentBounds.yMin and obj1.contentBounds.yMax >= obj2.contentBounds.yMin
    local down = obj1.contentBounds.yMin >= obj2.contentBounds.yMin and obj1.contentBounds.yMin <= obj2.contentBounds.yMax

    return (left or right) and (up or down)
end


-----------------------------------------------------------------------------
-- HasCollidedCircle( objA, objB, paddingA, paddingB )
-- Check if the circle boundaries of two objects do overlap
-- objA, objB           - the two dispplay objects to check
-- paddingA, paddingB   - optional padding to make the collision radius smaller or bigger (positive is bigger)
-----------------------------------------------------------------------------
function Collision:HasCollidedCircle( objA, objB, paddingA, paddingB )
    local paddingA = paddingA or 0
    local paddingB = paddingB or 0

    if ( objA == nil or objB == nil ) then  -- make sure the objects exists
        return false
    end

   local dx = objA.x - objB.x
   local dy = objA.y - objB.y

   local distance = math_sqrt( dx*dx + dy*dy )
   local objectSize = ((objB.contentWidth + paddingB) * 0.5) + ((objA.contentWidth + paddingA) * 0.5)

   if ( distance < objectSize ) then
      return true
   end

   return false
end


-----------------------------------------------------------------------------
-- HasCollidedPointInRect( px, py, obj )
-- Check if the rectangle boundaries of two objects do overlap
-----------------------------------------------------------------------------
function Collision:HasCollidedPointInRect( px, py, obj )
    if ( obj == nil ) then  --make sure the first object exists
        return false
    end

    local horizontal = px >= obj.contentBounds.xMin and px <= obj.contentBounds.xMax
    local vertical = py >= obj.contentBounds.yMin and py <= obj.contentBounds.yMax

    return horizontal and vertical
end


-----------------------------------------------------------------------------
-- GetNearbyObjects( pCenter, pObjects, pRange )
-- returns a table of objects that are in the range of the pCenter objects
-- pCenter  - the object in the center
-- pObjects - the objects that are to be checked if they are in range
-- range    - the range of the zone around the pCenter objects = width/height of a rectangle around pCenter
-----------------------------------------------------------------------------
function Collision:GetNearbyObjects( pCenter, pObjects, pRange, pDebug )
    if ( pCenter == nil ) or (pObjects == nil) then  --make sure the objects exists
        return false
    end
    
    local pDebug = pDebug or false

    if pDebug == true then
        local rect = display.newRect( pCenter.x, pCenter.y, pRange*2, pRange*2 )
        rect:setFillColor( 0,0,0,0 )
        rect:setStrokeColor( 1,0,0 )
        rect.strokeWidth = 1
    end

    local left      = pCenter.x - pRange
    local right     = pCenter.x + pRange
    local top       = pCenter.y - pRange
    local bottom    = pCenter.y + pRange

    local result = {}

    for i=1,#pObjects do
        if pObjects[i] ~= nil then
            if pObjects[i].x >= left and pObjects[i].x <= right then
                if pObjects[i].y >= top and pObjects[i].y <= bottom then
                    result[#result+1] = pObjects[i]
                end
            end
        end
    end

    return result
end

return Collision
