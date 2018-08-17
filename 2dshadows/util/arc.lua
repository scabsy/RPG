-------------------------------------------------
-- arc.lua
-- A module to create and draw arcs
--
-- @module Arc
-- @author René Aye
-- @license MIT
-- @copyright DevilSquid, René Aye 2016
-------------------------------------------------
if devilsquid == nil then
    devilsquid = {}
    if devilsquid.requirepath == nil then devilsquid.requirepath = "devilsquid." end
    if devilsquid.filepath == nil then devilsquid.filepath = "devilsquid/" end
end




local Arc = {}

local log = require( devilsquid.requirepath .. "util.log" )


-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------
local RATE = math.pi/180.0

-------------------------------------------------
-- Constructor function of Arc module
--
-- @int startAngle the starting angle of the arc
-- @int endAngle the ending angle of the arc
-- @int radius radius of the circle arc
-- @int strokeWidth the thicknes of the arc in pixels
-- @bool closed if true, draws a closing line between beginning and end of the arc
-- @bool pie if closed and pie is true then draw a wedge
-- @return arc object table
-------------------------------------------------
function Arc:new( startAngle, endAngle, radius, strokeWidth, closed, pie )
	log:p(0, "Arc:new()" )

	local arc       = display.newGroup()
	arc.graphs      = {}
	arc.startAngle  = startAngle or 0
	arc.startAngle2 = startAngle or 0      -- backup of initial startAngle, needed for SetPercent()
	arc.endAngle    = endAngle or 90
	arc.endAngle2   = endAngle or 90       -- backup of initial endAngle, needed for SetPercent()
	arc.radius      = radius or 100
	arc.strokeWidth = strokeWidth or 5
	arc.closed      = closed or false
	arc.pie         = pie or false
	arc.lastPercent = 100
	arc.color       = {1,1,1}

	-------------------------------------------------
	-- PRIVATE FUNCTIONS
	-------------------------------------------------

	-----------------------------------------------------------------------------
	-- Draws the arc
	-- @return nothing
	-----------------------------------------------------------------------------
	function arc:Draw()
		log:p(0,"arc:Draw()")

		-- print( "startAngle", self.startAngle )
		-- print( "endAngle", self.endAngle )
		-- print( "radius", self.radius )
		-- print( "strokeWidth", self.strokeWidth )
		-- print( "closed", self.closed )
		-- print( "pie", self.pie )

		local fx,fy     = 0,0                       -- first x,y
		local lx,ly     = 0,0                       -- last x,y
		local strokeWidth2 = strokeWidth * 0.5

		-- abort if  start and end angle are the same
		if self.startAngle == self.endAngle then return end

		-- swap angles if start angle is bigger tham end angle
		if self.startAngle > self.endAngle then
			local ta = self.endAngle
			self.endAngle = self.startAngle
			self.startAngle = ta
		end

		-- calculate the angle that needs to be drawn and crop to maximum of 360 degree
		local angle = self.endAngle - self.startAngle
		if angle > 360.0 then angle = 360.0 end
		
		-- how many dots should be drawn, the smaller the step the more dots get drawn
		local step = 1.0/(RATE * radius)
		local accumAngle = self.startAngle

		-- if closed then draw a line between from beginnen to end of arc
		if self.closed == true then
			fx = math.cos( math.rad(accumAngle) ) * self.radius
			fy = math.sin( math.rad(accumAngle) ) * self.radius
		end
		
		-- create the dots for the arc
		while accumAngle < (self.startAngle + angle) do                        
			lx = math.cos( math.rad(accumAngle) ) * self.radius
			ly = math.sin( math.rad(accumAngle) ) * self.radius
			
			local c = display.newCircle( self, lx, ly, strokeWidth2 )
			table.insert( self.graphs, c )
			c:setFillColor( self.color[1],self.color[2],self.color[3] )

			accumAngle = accumAngle + step
		end


		if self.closed == true then
			-- draw a wedge
			if self.pie == true then
				local n1 = display.newLine( self, 0, 0, fx, fy )
				n1.strokeWidth = self.strokeWidth
				table.insert( self.graphs, n1 )

				local n2 = display.newLine( self, 0, 0, lx, ly )
				n2.strokeWidth = self.strokeWidth
				table.insert( self.graphs, n2 )

			-- or just draw a line between beginnen and end of arc
			else
				local n1 = display.newLine( self, fx,fy,lx,ly )
				n1.strokeWidth = self.strokeWidth
				table.insert( self.graphs, n1 )
			end
		end
	end

	-----------------------------------------------------------------------------
	-- Removes the arc
	-- @return nothing
	-----------------------------------------------------------------------------
	function arc:Clear()
		for i=1,#self.graphs do
			display.remove( self.graphs[i] )
			self.graphs[i] = nil
		end
	end


	-----------------------------------------------------------------------------
	-- Sets the color of the arc
	-- @param options table with r,g,b values
	-- @return nothing
	-----------------------------------------------------------------------------
	function arc:SetColor( options )
		log:p(0, "arc:SetColor")

		self.color[1] = options.r or 1
		self.color[2] = options.g or 1
		self.color[3] = options.b or 1

		local redraw = options.redraw or false
		if redraw == true then
			self:Clear()
			self:Draw()  
		end
	end

	-----------------------------------------------------------------------------
	-- Changes the angle where the drawing of the arc begins
	-- @param newStartAngle
	-----------------------------------------------------------------------------
	function arc:SetStartAngle( newStartAngle )
		log:p(0,"arc:SetStartAngle(" .. newStartAngle .. ")")
		self.startAngle = newStartAngle

		self:Clear()
		self:Draw()
	end

	-----------------------------------------------------------------------------
	-- arc:SetPercent( percent, clockwise, bothsides )
	-- @param percent draws a percentage of the arc, 50% wpuld be the half arc
	-- @param clockwise if true, then the arc gets less in clockwise direction, otherwise in counterclockwise
	-- @param bothsides if true, ther arc gets less in both direction
	-- @return nothing
	-----------------------------------------------------------------------------
	function arc:SetPercent( percent, clockwise, bothsides )
		if percent == self.lastPercent then
				return
		else
				self.lastPercent = percent
		end

		if self.startAngle == self.endAngle then return end
		if self.startAngle > self.endAngle then
			local ta = self.endAngle
			self.endAngle = self.startAngle
			self.startAngle = ta
		end

		local clockwise = clockwise or false
		local originalAngle = self.endAngle2 - self.startAngle2
		if originalAngle > 360.0 then originalAngle = 360.0 end

		local perc1 = originalAngle/100.0
		local newAngle = perc1 * percent
		local diffAngle = originalAngle - newAngle
		
		if bothsides == false then
			if clockwise == false then
					self.endAngle = self.endAngle2 - diffAngle
			else
					self.startAngle = self.startAngle2 + diffAngle
			end
		end

		if bothsides == true then
			local diffAngle2 = diffAngle * 0.5
			self.endAngle = self.endAngle2 - diffAngle2
			self.startAngle = self.startAngle2 + diffAngle2
		end


		self:Clear()
		self:Draw()
	end




	arc:Draw()

	return arc
end
 
return Arc