-----------------------------------------------------------------------------------------
--
-- controlpoint.lua
--
-- Control points for the bezier path editor
--
-- @module ControlPoint
-- @author René Aye
-- @license MIT
-- @copyright DevilSquid, René Aye - 2016
-------------------------------------------------
if devilsquid == nil then
    devilsquid = {}
    if devilsquid.requirepath == nil then devilsquid.requirepath = "devilsquid." end
    if devilsquid.filepath == nil then devilsquid.filepath = "devilsquid/" end
end





local ControlPoint = {}

local Object        = require( devilsquid.requirepath .. "util.object" )
local Handle        = require( devilsquid.requirepath .. "util.bezier.handle" )

local log           = require( devilsquid.requirepath .. "util.log" )
local helper        = require( devilsquid.requirepath .. "util.helper" ) 




-------------------------------------------------
-- Create and draws a control point for a Bézier curve
--
-- A control point consists of the point itself (its position) an a curve handle
-- The Beziér curve goes through the control point. The curve can go through the curve handle, but it must not.
-- The curve handle controls the curviness.
--
-- @param optParent the parent object
-- @number[opt=0] optX x position of the control point
-- @number[opt=0] optY y position of the control point
-- @number[opt=0] optHandleX x position of the curve handle
-- @number[opt=0] optHandleY y position of the curve handle
-- @param optColor the color of the control point visualization in r,g,b,a values (*default* {0,0,1,1} = blue color)
-- @return GroupObject
--
-- @see BezierPathEditor
-- @see Handle
--
-------------------------------------------------
function ControlPoint:new( optParent, optX, optY, optHandleX, optHandleY, optColor  )

    log:p(2, "ControlPoint::new()", optParent.type, optX, optY, optHandleX, optHandleY)

    local cp                = Object:new( optX, optY )
    cp.type                 = "controlpoint"
    cp.superObject          = optParent

    cp.rect                 = display.newRect( cp, 0, 0, 10, 10 )

    local color = optColor or {0,0,1,1}
    cp.rect:setStrokeColor( unpack(color) )
    cp.rect:setFillColor( 1,1,1,0.1 )
    cp.rect.strokeWidth     = 1

    cp.handle               = Handle:new( cp, optHandleX - optX, optHandleY - optY)
    cp:insert( cp.handle )

    cp.linkedControlPoint   = nil

    cp.line                 = display.newLine( 0,0,0,0 )




    -- ------------------------------------------------
    -- Links a control point to to a different control point
    -- Needed for the inner control points for a path which have to be at the same position
    -- Linked control points gets automatically repositioned when one of the two linked 
    -- control points has moved
    --
    function cp:LinkToOtherControlPoint( otherControlPoint )
        self.linkedControlPoint = otherControlPoint
    end


    -- ------------------------------------------------
    -- Draws a line from handle to its parent control point
    --
    function cp:DrawLineToHandle()
        self.line:removeSelf( )
        self.line = nil

        local hx = self.handle.x
        local hy = self.handle.y

        self.line = display.newLine( self, 0,0, hx,hy )
        self.line.alpha = 0.25
    end


    -- ------------------------------------------------
    -- HasMoved()
    --
    cp.superHasMoved = cp.HasMoved
    function cp:HasMoved( event )
        self:superHasMoved( event )

        -- update linked cp position if exists
        if self.linkedControlPoint then
            self.linkedControlPoint.x = self.x
            self.linkedControlPoint.y = self.y
        end

        -- redraw the bezier path
        self.superObject:DrawPlot()
    end


    -- ------------------------------------------------
    -- Deletes the control point
    --
    function cp:Remove()
        self.superObject = nil

        self.rect:removeSelf()
        self.rect = nil

        self.handle:Remove()
        self.handle = nil

        self.linkedControlPoint = nil

        self.line:removeSelf()
        self.line = nil

        self:removeSelf()
        self = nil
    end


    -- ########################################################## ## ### # ### ## #
    -- ## INITIAL CODE EXECUTION ################################# # ## # ## #
    -- ############################################################## ## # 

    cp:DrawLineToHandle()



    return cp
end
return ControlPoint