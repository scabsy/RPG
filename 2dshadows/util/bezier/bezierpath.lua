-------------------------------------------------
-- bezierpath.lua
-- A function to draw a Bézier path
-- In this case a path means several Bézier segments connected to a path
--
-- @module BezierPath
-- @author René Aye
-- @license MIT
-- @copyright DevilSquid, René Aye 2016
-------------------------------------------------
if devilsquid == nil then
    devilsquid = {}
    if devilsquid.requirepath == nil then devilsquid.requirepath = "devilsquid." end
    if devilsquid.filepath == nil then devilsquid.filepath = "devilsquid/" end
end



BezierPath = {}

local Bezier        = require( devilsquid.requirepath .. "util.bezier.bezier" )
local ControlPoint  = require( devilsquid.requirepath .. "util.bezier.controlpoint" )
local log           = require( devilsquid.requirepath .. "util.log" )
local helper        = require( devilsquid.requirepath .. "util.helper" ) 






-------------------------------------------------
-- Create and draws a cubic Bézier path
--
-- @param options a table with options for the Bézier curve
--
--  - `parent`:             (**GroupObject**) the parent object (default: nil)
--  - `x`:                  (**number**) the x position of the path (default: 0)
--  - `y`:                  (**number**) the y position of the path (default: 0)
--  - `density`:            (**number**) the density of the plot (default: 100)
--  - `strokeWidth`:        (**number**) the stroke width (default: 2)
--  - `controlPoints`:      (**array**) an array with a continuous list of control point coordinates like 
-- the list from the bezierpatheditor export function
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
function BezierPath:new( options )
	log:p(2, "BezierPath::new()")

    -- get the options
    local optParent         = options.parent or nil
    local optX              = options.x or 0
    local optY              = options.y or 0
    local optDensity        = options.density or 100
    local optStrokeWidth    = options.strokeWidth or 2
    local optControlPoints  = options.controlPoints


    local bezierPath = display.newGroup( )

    bezierPath.x                = 0
    bezierPath.y                = 0
    bezierPath.type             = "bezierpath"

    bezierPath.controlPoints    = {}
    bezierPath.plot             = {}
    bezierPath.lines            = {}

    bezierPath.density          = optDensity or 50
    bezierPath.strokeWidth      = optStrokeWidth or 1


    -- create control points
    for i=1,#optControlPoints, 4 do
        local P0 = {}
        P0.x = optControlPoints[i]
        P0.y = optControlPoints[i+1]

        P0.handle = {}
        P0.handle.x = optControlPoints[i+2]
        P0.handle.y = optControlPoints[i+3]
        table.insert(bezierPath.controlPoints, P0)

        log:p(2, "added control point", P0.x, P0.y, P0.handle.x, P0.handle.y)
    end



    function bezierPath:DrawLines()
        local density = self.density

        log:p(2, "bezierPath:Draw", #self.controlPoints, density)
        self:ClearLines()

        local newLine = display.newLine( self, self.controlPoints[1].x, self.controlPoints[1].y, self.controlPoints[1].x, self.controlPoints[1].y )
        newLine.strokeWidth = self.strokeWidth
        table.insert( self.lines, newLine )

        for i = 1, #self.controlPoints, 2 do
            local p0 = {}
            local p1 = {}
            local p2 = {}
            local p3 = {}

            p0.x = self.controlPoints[i].x
            p0.y = self.controlPoints[i].y

            p1.x = self.controlPoints[i].handle.x
            p1.y = self.controlPoints[i].handle.y

            p2.x = self.controlPoints[i+1].handle.x
            p2.y = self.controlPoints[i+1].handle.y

            p3.x = self.controlPoints[i+1].x
            p3.y = self.controlPoints[i+1].y


            for j = 1, density do
                local t = j / density
                local pos = Bezier:CalculatePoint(t, p0, p1, p2, p3)
                newLine:append(pos.x, pos.y)
            end
        end
    end
  

    ---------------------------------------------------------------------
    -- Clear the lines of the Bézier path
    --
    function bezierPath:ClearLines()
        for i=1,#self.lines do
            display.remove ( self.lines[i] )
            self.lines[i] = nil  -- set reference to nil!
        end
    end



    ---------------------------------------------------------------------
    -- Draw a plot of the whole Bézier path
    --
    function bezierPath:DrawPlot()
        local density = self.density

        log:p(2, "bezierPath:Draw", #self.controlPoints, density)
    	self:ClearPlot()

        for i = 1, #self.controlPoints, 2 do
            local p0 = {}
            local p1 = {}
            local p2 = {}
            local p3 = {}

            p0.x = self.controlPoints[i].x
            p0.y = self.controlPoints[i].y

            p1.x = self.controlPoints[i].handle.x
            p1.y = self.controlPoints[i].handle.y

            p2.x = self.controlPoints[i+1].handle.x
            p2.y = self.controlPoints[i+1].handle.y

            p3.x = self.controlPoints[i+1].x
            p3.y = self.controlPoints[i+1].y

            --print(i, p0.x, p0.y, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y )

            for j = 1, density do
                local t = j / density
                local pos = Bezier:CalculatePoint(t, p0, p1, p2, p3)
                local circle = display.newCircle( self, pos.x, pos.y, self.strokeWidth )
                table.insert( self.plot, circle )
            end
        end
    end


    function bezierPath:CalculatePoint( t )
        log:p(2, "bezierPath:CalculatePoint", t)
        local t = t
        if t > 1.0 then t = 1.0 end
        if t < 0.0 then t = 0.0 end

        -- count how many segments the path have
        local segmentsTotal = #self.controlPoints / 2

        -- we need to map the t value (0 to 1) to the whole path
        -- example:
        -- a path with four segments would have four times a t value from 0 to 1
        -- so a t value of 1 would be mapped to 4
        -- a t value 0.5 would be mapped to 2.0 which means start at segment 3
        --
        -- segments 3 first controlpoint is number 5
        

        -- map the t value to get the segment
        local segment = math.floor(t * segmentsTotal) + 1
        if segment > segmentsTotal then segment = segmentsTotal end

        -- caclulate the starting control point
        local startControlPoint = segment * 2 - 1

        -- the number after the comma is the t value for the exact position on the segment
        t = t * segmentsTotal + 1
        t = t - segment

        local p0 = {}
        local p1 = {}
        local p2 = {}
        local p3 = {}

        p0.x = self.controlPoints[startControlPoint].x
        p0.y = self.controlPoints[startControlPoint].y

        p1.x = self.controlPoints[startControlPoint].handle.x
        p1.y = self.controlPoints[startControlPoint].handle.y

        p2.x = self.controlPoints[startControlPoint+1].handle.x
        p2.y = self.controlPoints[startControlPoint+1].handle.y

        p3.x = self.controlPoints[startControlPoint+1].x
        p3.y = self.controlPoints[startControlPoint+1].y

        local pos = Bezier:CalculatePoint(t, p0, p1, p2, p3)

        return pos.x, pos.y

    end


    ---------------------------------------------------------------------
    -- Clear the plot of the Bézier path
    --
    function bezierPath:ClearPlot()
    	for i=1,#self.plot do
    		display.remove ( self.plot[i] )
			self.plot[i] = nil  -- set reference to nil!
    	end
    end


    ---------------------------------------------------------------------
    -- Deletes the Bézier Path
    --
    function bezierPath:Remove()

        -- remove control points
        for i=1,#self.controlPoints do
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


        self:removeSelf()
        self = nil
    end



    -- ########################################################## ## ### # ### ## #
    -- ## INITIAL CODE EXECUTION ################################# # ## # ## #
    -- ############################################################## ## # 

    --bezierPath:DrawPlot()
    bezierPath:DrawLines()


    return bezierPath
end
return BezierPath