-------------------------------------------------
-- bezierpatheditor.lua
-- A simple bezier path editor to create bezier paths that can be exported and imported again
--
-- @module BezierPathEditor
-- @author René Aye
-- @license MIT
-- @copyright DevilSquid, René Aye 2016
-------------------------------------------------
if devilsquid == nil then
    devilsquid = {}
    if devilsquid.requirepath == nil then devilsquid.requirepath = "devilsquid." end
    if devilsquid.filepath == nil then devilsquid.filepath = "devilsquid/" end
end





BezierPathEditor = {}

local Bezier        = require( devilsquid.requirepath .. "util.bezier.bezier" )
local ControlPoint  = require( devilsquid.requirepath .. "util.bezier.controlpoint" )
local log           = require( devilsquid.requirepath .. "util.log" )
require( devilsquid.requirepath .. "util.mathlib" ) 


local _W          = math.floor( display.actualContentWidth + 0.5 )
local _H          = math.floor( display.actualContentHeight + 0.5 )
local _W2         = _W * 0.5
local _H2         = _H * 0.5
local _W4         = _W2 * 0.5
local _H4         = _H2 * 0.5

-------------------------------------------------
-- Create and draws a cubic Bézier path with simple editor and import/export functionality.
--
-- - use **space key** to create a new control point at mouse position
-- - use **e key** to export to console
-- - use **r key** to show/hide grid
-- - use **numpad+** to increase grid size
-- - use **numpad-** to decrease grid size
--
-- @param options a table with options for the Bézier curve
--
--  - `parent`:             (**GroupObject**) the parent object (*default*: nil)
--  - `x`:                  (**number**) the x position of the path (*default*: 0)
--  - `y`:                  (**number**) the y position of the path (*default*: 0)
--  - `density`:            (**number**) the density of the plot (*default*: 100)
--  - `strokeWidth`:        (**number**) the stroke width (*default*: 2)
--  - `controlPoints`:      (**array**) an array with a continuous list of control point coordinates like 
-- the list from the bezierpatheditor export function. Use this to continue editing a curve. Otherwise leave 
-- empty if you want to create a new curve from scratch.
--
-- @return bezier path group object
--
-- @usage 
--  local BezierPath = require( "devilsquid.util.bezier.bezierpath" )
--
--  local bezierPath = BezierPath:new({ 
--    density=200, 
--    strokeWidth=2, 
--    controlPoints={88,1027,138,1077,392,950,442,1000,392,950,442,1000,260,908,310,958} 
--    })
-------------------------------------------------
function BezierPathEditor:new( options )
    log:p(1, "BezierPathEditor:new()")

    local options = options or {}

    local optParent         = options.parent or nil
    local optX              = options.x or 0
    local optY              = options.y or 0
    local optDensity        = options.Density or 100
    local optStrokeWidth    = options.strokeWidth or 2
    local optControlPoints  = options.controlPoints
  

    local bpe = display.newGroup( )
    bpe.type  = "bezierpatheditor"

    bpe.controlPoints   = {}                  -- table with all control points of the bezier curve
    bpe.plot            = {}                  -- table for the circles to draw the bezier curves
    bpe.raster          = {}                  -- table for all the lines for a raster

    -- process options
    if optParent then optParent:insert( bpe ) end
    bpe.x               = optX
    bpe.y               = optY

    bpe.density         = optDensity or 50
    bpe.strokeWidth     = optStrokeWidth or 1
    bpe.rasterSize      = 10

    bpe.showRaster      = false

    bpe.mouseX          = 0
    bpe.mouseY          = 0



    ---------------------------------------------------------------------
    -- Add a control point to the bezier path
    --
    -- A control point consist of a starting point where the curve is going through
    -- and a curve point which controls the curvines
    -- To draw a bezier curve we need at last two control points (= 2 starting points + 2 curve points)
    --
    -- This method takes control point lining into account: control points, that are not at the very beginning or very end 
    -- of the whole path needs to be doubled to have more control on the curve. this way we have two curve controllers.
    -- Infact we create two control points, that are linked together, so that they always do have the same position
    --
    -- @number p0x x value of control point
    -- @number p0y y value of control point
    -- @number p1x x value of curve point
    -- @number p1y y value of curve point
    ---------------------------------------------------------------------
    function bpe:AddControlPoint( p0x,p0y, p1x,p1y )
        log:p(1, "bpe:AddControlPoint", p0x,p0y, p1x,p1y )
        local p0x = p0x
        local p0y = p0y
        local p1x = p1x or p0x + 50
        local p1y = p1y or p0y + 50

        -- create a new control point
        local newControlPoint = ControlPoint:new(self, p0x, p0y, p1x, p1y)

        -- if number of control points < 2, then this the first or second handle after creating the bezier path
        -- in this case the last control point does not need to be copied
        if #self.controlPoints < 2 then

            table.insert(self.controlPoints, newControlPoint)

        -- if number of control points is bigger than two than we need to copy the last previous control point as a 
        -- beginning of this new segment
        elseif #self.controlPoints >= 2 then

            -- get the last control point from the list
            local lastControlPoint = self.controlPoints[#self.controlPoints]

            -- create a copy from the last control point
            local copyControlPoint = ControlPoint:new(self, lastControlPoint.x, lastControlPoint.y, lastControlPoint.handle.x+lastControlPoint.x, lastControlPoint.handle.y+lastControlPoint.y)
            
            -- link the copied and the last control point
            -- so that their position is always the same
            copyControlPoint:LinkToOtherControlPoint(lastControlPoint)
            lastControlPoint:LinkToOtherControlPoint(copyControlPoint)

            -- insert the copied and the new control point 
            table.insert(self.controlPoints, copyControlPoint)
            table.insert(self.controlPoints, newControlPoint)
        end

        log:p(2, "ControlPoints total", #self.controlPoints)
    end


    ---------------------------------------------------------------------
    -- Add a control point that is part of a continuous list of control points
    -- like the list that gets exported by the Export function
    --
    -- In this case we do not need to create copies of inner control points, because
    -- the copies are already in the exported list. This function does take care to 
    -- link the inner control points by counting: if the number is bigger than 2 and 
    -- odd means it has to be linked with the previous control point
    --
    -- @number p0x x value of control point
    -- @number p0y y value of control point
    -- @number p1x x value of curve point
    -- @number p1y y value of curve point
    ---------------------------------------------------------------------
    function bpe:AddContinuousControlPoint( p0x,p0y, p1x,p1y )
        log:p(2, "bpe:AddContinuousControlPoint", p0x,p0y, p1x,p1y )
        local p0x = p0x
        local p0y = p0y
        local p1x = p1x or p0x + 50
        local p1y = p1y or p0y + 50

        local newControlPoint

        -- make the very first control point green, else use default color (blue)
        if #self.controlPoints == 0 then
            -- new control point in green
            newControlPoint = ControlPoint:new(self, p0x, p0y, p1x, p1y, {0,1,0,1})
        else
            -- new control point in blue
            newControlPoint = ControlPoint:new(self, p0x, p0y, p1x, p1y)
        end
            
        -- insert new conbtrol point to table
        table.insert(self.controlPoints, newControlPoint)

        -- if numbers of control points is abobe two and the current number of control points
        -- is odd then link this and the previous control point
        if #self.controlPoints > 2 and math.isOdd(#self.controlPoints) then
            local prevControlPoint = self.controlPoints[#self.controlPoints-1]

            -- link the control points together
            newControlPoint:LinkToOtherControlPoint(prevControlPoint)
            prevControlPoint:LinkToOtherControlPoint(newControlPoint)
        end
    end


    ---------------------------------------------------------------------
    -- Draws a plot of the whole Bézier path
    --
    function bpe:DrawPlot()
        if #self.controlPoints < 2 then return end

        local density = self.density

        log:p(2, "bpe:Draw", #self.controlPoints, density)
    	self:ClearPlot()

        for i = 1, #self.controlPoints, 2 do
            local p0 = {}
            local p1 = {}
            local p2 = {}
            local p3 = {}

            p0.x = self.controlPoints[i].x
            p0.y = self.controlPoints[i].y
            p3.x = self.controlPoints[i+1].x
            p3.y = self.controlPoints[i+1].y


            p1.x = p0.x + self.controlPoints[i].handle.x
            p1.y = p0.y + self.controlPoints[i].handle.y
            p2.x = p3.x + self.controlPoints[i+1].handle.x
            p2.y = p3.y + self.controlPoints[i+1].handle.y

            --print(i, p0.x, p0.y, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y )

            for j = 1, density do
                local t = j / density
                local pos = Bezier:CalculatePoint(t, p0, p1, p2, p3)
                local glow = display.newCircle( bpe, pos.x, pos.y, self.strokeWidth )
                table.insert( self.plot, glow )
            end
        end

    end


    ---------------------------------------------------------------------
    -- Clears the plot of the Bézier path
    --
    function bpe:ClearPlot()
    	for i=1,#self.plot do
    		display.remove ( self.plot[i] )
			self.plot[i] = nil  --set reference to nil!
    	end
    end


    ---------------------------------------------------------------------
    -- Draws a raster to help constructing shapes as a visible guide
    --
    -- @usage
    -- Press r on keyboard to show/hide the raster
    -- Press numpad+ on keyboard to increase raster size
    -- Press numpad- on keyboard to decrease raster size
    --
    function bpe:DrawRaster()
        self:ClearRaster()

        local W          = math.floor( display.actualContentWidth + 0.5 )
        local H          = math.floor( display.actualContentHeight + 0.5 )
        local W2         = _W * 0.5
        local H2         = _H * 0.5
        local W4         = _W2 * 0.5
        local H4         = _H2 * 0.5

        -- vertical lines
        local maxLines = H / self.rasterSize
        for i = 1, maxLines do
            local ly = i * self.rasterSize
            local line = display.newLine( 0, ly, W, ly )
            line:setStrokeColor( 1,1,1,0.2 )
            line.setStrokeWidth = 1
            table.insert( self.raster, line)
        end

        -- horizontal lines
        maxLines = W / self.rasterSize
        for i = 1, maxLines do
            local lx = i * self.rasterSize
            local line = display.newLine( lx, 0, lx, H )
            line:setStrokeColor( 1,1,1,0.2 )
            line.setStrokeWidth = 1
            table.insert( self.raster, line)
        end
    end


    ---------------------------------------------------------------------
    -- Clears the raster
    --
    function bpe:ClearRaster()
        for i=1,#self.raster do
            display.remove ( self.raster[i] )
            self.raster[i] = nil  --set reference to nil!
        end
    end


    ---------------------------------------------------------------------
    -- Exports the current control points to copy and paste them elsewhere
    --
    -- @return nothing
    --
    -- @usage
    -- Press e on keyboard to print a list of control point coordinates to console.
    -- Copy and paste the list into the appropritat command i.e.
    -- BezierPathEditor:new({ controlPoints={0,0,100,100, ... } })
    --
    function bpe:Export()
        local result = ""

        for i = 1, #self.controlPoints do
            result = result .. self.controlPoints[i].x ..","
            result = result .. self.controlPoints[i].y ..","
            result = result .. self.controlPoints[i].handle.x + self.controlPoints[i].x ..","
            result = result .. self.controlPoints[i].handle.y + self.controlPoints[i].y ..","
        end
        result = string.sub( result, 1, string.len(result)-1)

        print("\n--EXPORT START-----------------------------------")
        print( result )
        print("\n--EXAMPLE USE-----------------------------------")
        print("local path = BezierPathEditor:new({ controlPoints={" .. result .. "} })")
        print("\n--EXPORT END-------------------------------------\n\n")
    end


    ---------------------------------------------------------------------
    -- Deletes the Editor
    --
    function bpe:Remove()

        -- remove control points
        for i=1,#self.controlPoints do
            self.controlPoints[i]:Remove()
            self.controlPoints[i] = nil
        end
        
        -- clear remove points table
        for i=1,#self.controlPoints do
            table.remove( self.controlPoints )
        end
        self.controlPoints = nil

        -- remove the plots
        for i=1,#self.plot do
            self.plot[i]:removeSelf()
            self.plot[i] = nil
        end

        -- clear plots table
        for i=1,#self.plot do
            table.remove( self.plot )
        end
        self.plot = nil


        -- remove the raster lines
        self:ClearRaster()

        -- clear raster table
        for i=1,#self.raster do
            table.remove( self.raster )
        end
        self.raster = nil

        self:removeSelf()
        self = nil
    end


    ---------------------------------------------------------------------
    -- Deletes the Editor
    --
    function bpe:Delete()
        self:Remove()
    end



    -- ------------------------------------------------------------------------------
    -- Some hotkeys
    --
    -- - space adds a new control point at mouse cursor position
    -- - e exports all control points coordinates to console
    -- - r displays a helping raster
    -- - numpad+ increases raster size
    -- - numpad- decreases raster size
    --
    function bpe:key( event )
        -- Print which key was pressed down/up
        --local message = "Key '" .. event.keyName .. "' was pressed " .. event.phase
        --print( message )

        if ( event.keyName == "space" ) and event.phase == "down" then
            self:AddControlPoint( self.mouseX, self.mouseY  )
            self:DrawPlot()
        end

        if ( event.keyName == "e" ) and event.phase == "down" then
            self:Export()
        end

        if ( event.keyName == "r" ) and event.phase == "down" then
            if self.showRaster == true then
                self.showRaster = false
                self:ClearRaster()
            else
                self.showRaster = true
                self:DrawRaster()
            end
        end

        if ( event.keyName == "numPad+" ) and event.phase == "down" then
            self.rasterSize = self.rasterSize + 1
            if self.showRaster == true then 
                self:DrawRaster()
            end
        end

        if ( event.keyName == "numPad-" ) and event.phase == "down" then
            self.rasterSize = self.rasterSize - 1
            if self.showRaster == true then 
                self:DrawRaster()
            end        end

        -- If the "back" key was pressed on Android or Windows Phone, prevent it from backing out of the app
        if ( event.keyName == "back" ) then
            local platformName = system.getInfo( "platformName" )
            if ( platformName == "Android" ) or ( platformName == "WinPhone" ) then
                return true
            end
        end

        -- IMPORTANT! Return false to indicate that this app is NOT overriding the received key
        -- This lets the operating system execute its default handling of the key
        return false
    end

    -- Add the key event listener
    Runtime:addEventListener( "key", bpe )



    -- Called when a mouse event has been received.
    -- Used to gather the mouse position
    function bpe:mouse( event )
        self.mouseX = event.x
        self.mouseY = event.y
    end

    -- Add the mouse event listener
    Runtime:addEventListener( "mouse", bpe )



    -- ########################################################## ## ### # ### ## #
    -- ## INITIAL CODE EXECUTION ################################# # ## # ## #
    -- ############################################################## ## # 

    -- create initial bezier control points

    -- if optControlPoints exists then create them
    if optControlPoints then
        for i=1,#optControlPoints, 4 do
            local P0 = {}
            local P1 = {}

            P0.x = optControlPoints[i]
            P0.y = optControlPoints[i+1]

            P1.x = optControlPoints[i+2]
            P1.y = optControlPoints[i+3]

            bpe:AddContinuousControlPoint( P0.x, P0.y, P1.x, P1.y )
        end

    -- if no control point exists then create a first point a center of screen
    else
        local P0 = {}
        local P1 = {}

        P0.x = _W2
        P0.y = _H2

        bpe:AddContinuousControlPoint( P0.x, P0.y )
    end

    -- Draw the curve
    bpe:DrawPlot()

    return bpe
end
return BezierPathEditor