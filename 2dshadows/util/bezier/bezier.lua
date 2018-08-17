-------------------------------------------------
-- bezier.lua
-- A function to caclulate a point on a Bezier curve
--
-- @module Bezier
-- @author René Aye
-- @license MIT
-- @copyright DevilSquid, René Aye 2016
-------------------------------------------------
if devilsquid == nil then
    devilsquid = {}
    if devilsquid.requirepath == nil then devilsquid.requirepath = "devilsquid." end
    if devilsquid.filepath == nil then devilsquid.filepath = "devilsquid/" end
end






Bezier = {}

local Vector2D = require( devilsquid.requirepath .. "util.vector2d" )



-------------------------------------------------
-- Caclulate a point on a cubic Bézier curve
--
-- @number  t   0.0 is the starting point and 1.0 would be the end point
-- @number p0   First point of Curve, a table with fields .x and .y, a Vector2D table is also possible
-- @number p1   Second point of Curve, a table with fields .x and .y, a Vector2D table is also possible
-- @number p2   Third point of Curve, a table with fields .x and .y, a Vector2D table is also possible
-- @number p3   Fourth point of Curve, a table with fields .x and .y, a Vector2D table is also possible
-- @return      a Vector2D table with the caclulated points
--
-- @see Vector2D
-------------------------------------------------
function Bezier:CalculatePoint( t, P0, P1, P2, P3 )
    local tt = t*t
    local ttt = t*t*t

    local part1 = (-P0.x + 3*P1.x - 3*P2.x + P3.x) * ttt
    local part2 = (3*P0.x - 6*P1.x + 3*P2.x) * tt
    local part3 = (-3*P0.x + 3*P1.x) * t
    local part4 = P0.x

    local resultX = part1 + part2 + part3 + part4

    part1 = (-P0.y + 3*P1.y - 3*P2.y + P3.y) * ttt
    part2 = (3*P0.y - 6*P1.y + 3*P2.y) * tt
    part3 = (-3*P0.y + 3*P1.y) * t
    part4 = P0.y

    local resultY = part1 + part2 + part3 + part4

    local result = {x=resultX, y=resultY}

    return result
end


-------------------------------------------------
function Bezier:CalculateTangent( t, P0, P1, P2, P3 )

    local t1    = 1 - t
    local t1t1  = t1*t1     -- (1 - t)^2
    local tt    = t*t       -- t^2
    local ttt   = t*t*t

--[[
    -3 * P0 * (1 - t)^2 + 
    P1 * (3 * (1 - t)^2 - 6 * (1 - t) * t) + 
    P2 * (6 * (1 - t) * t - 3 * t^2) +
    3 * P3 * t^2
]]--

    local part1 = -3 * P0.x * t1t1
    local part2 = P1.x * (3 * t1t1 - 6 * t1 * t)
    local part3 = P2.x * (6 * t1 * t - 3 * tt)
    local part4 = 3 * P3.x * tt   


    local resultX = part1 + part2 + part3 + part4

    part1 = -3 * P0.y * t1t1
    part2 = P1.y * (3 * t1t1 - 6 * t1 * t)
    part3 = P2.y * (6 * t1 * t - 3 * tt)
    part4 = 3 * P3.y * tt  

    local resultY = part1 + part2 + part3 + part4

    local result = {x=resultX, y=resultY}

    return result
end

return Bezier