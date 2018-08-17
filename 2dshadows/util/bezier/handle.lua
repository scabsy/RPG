-----------------------------------------------------------------------------------------
--
-- handle.lua
--
-- Handles for the Bézier path control points of the BezierPathEditor module
--
-- @module Handle
-- @author René Aye
-- @license MIT
-- @copyright DevilSquid, René Aye - 2016
-------------------------------------------------
if devilsquid == nil then
    devilsquid = {}
    if devilsquid.requirepath == nil then devilsquid.requirepath = "devilsquid." end
    if devilsquid.filepath == nil then devilsquid.filepath = "devilsquid/" end
end






local Handle = {}

local Object        = require( devilsquid.requirepath .. "util.object" )
local log           = require( devilsquid.requirepath .. "util.log" )
local helper        = require( devilsquid.requirepath .. "util.helper" ) 




-------------------------------------------------
-- Create and draws a curve handle for a control point of a Bézier curve
--
-- The curve handle controls the curviness.
--
-- @param optParent the parent object (in general a ControlPoint)
-- @number[opt=0] optX x position of the curve handle
-- @number[opt=0] optY y position of the curve handle
-- @return GroupObject
--
-- @see ControlPoint
-- @see BezierPathEditor
--
-------------------------------------------------
function Handle:new( optParent, optX, optY )

    log:p(2, "Handle::new()", optX, optY)

    local handle        = Object:new( optX, optY )
    handle.type         = "handle"
    handle.superObject  = optParent

    handle.circle       = display.newCircle( handle, 0, 0, 5 )
    handle.circle:setFillColor( 1,0,1,1 )
    handle.line         = display.newLine( handle, 0,0,0,0 )
     

    -- ------------------------------------------------
    -- HasMoved()
    --
    handle.superHasMoved = handle.HasMoved
    function handle:HasMoved( event )
        self:superHasMoved( event )

        self.superObject:DrawLineToHandle()
        self.superObject.superObject:DrawPlot()
    end


    -- ------------------------------------------------
    -- Deletes the handle
    --
    function handle:Remove()
        self.superObject = nil

        self.circle:removeSelf()
        self.circle = nil

        self.line:removeSelf()
        self.line = nil

        self:removeSelf()
        self = nil
    end

    
    return handle
end
 
return Handle