-------------------------------------------------
-- transitionmanager.lua
-- A management system for transitions
--
-- @module TransitionManager
-- @author René Aye
-- @license MIT
-- @copyright DevilSquid, René Aye 2016
-------------------------------------------------
if devilsquid == nil then
    devilsquid = {}
    if devilsquid.requirepath == nil then devilsquid.requirepath = "devilsquid." end
    if devilsquid.filepath == nil then devilsquid.filepath = "devilsquid/" end
end




local system_getTimer   		= system.getTimer
local timer_performWithDelay 	= timer.performWithDelay




local TransitionManager = {}



function TransitionManager:new()
	local manager = display.newGroup()
	
	manager.transitions = {} 		-- table of transitions
	manager.tm = nil 				-- update timer


	--------------------------------------------------------
	-- adds a new transition to the manager
	--
	function manager:Add( target, params )

		local paramTime = params.time or 500


		local newTransition = {}
		newTransition.time 			= paramTime
		newTransition.timeStart 	= system_getTimer()
		newTransition.state 		= "isrunning"
		newTransition.transition 	= transition.to( target, params )

		table.insert( self.transitions, newTransition )

		return newTransition.transition
	end


	--------------------------------------------------------
	-- count the number of transitions
	--
	function manager:Count()
		return #self.transitions
	end


	--------------------------------------------------------
	-- returns the state of a single transition
	--
	function manager:GetState( trans )
		for i=1,#self.transitions do
			local t = self.transitions[i]

			if t.transition == trans then
				return "state: " .. t.state
			end
		end

		return "transition not found"
	end


	--------------------------------------------------------
	-- delets the transition manager
	--
	function manager:Delete()
		
		timer.cancel( manager.tm )
		manager.tm = nil

		-- delete all transitions
		for i=1,#self.transitions do
			local t = self.transitions[i]

			transition.cancel( t.transition )
			t.transition = nil
			t = nil
			self.transitions[i] = nil
		end
		self.transitions = nil

	end


	--------------------------------------------------------
	-- Delete ended transitionObjects
	--
	function manager:GarbageTransitions()

		-- iterate each transisiton and check if it ended
		for i=1,#self.transitions do
			local t = self.transitions[i]

			if t ~= nil then
				-- if it is ended then cancel it and remove it from transitions table
				if t.state == "ended" then
					transition.cancel( t.transition )
					t.transition = nil
					t = nil
					self.transitions[i] = nil
				end
			end

		end
	end


	--------------------------------------------------------
	-- updates the states of all transitions
	--
	function manager:UpdateStates()
		-- get current time
		local currentTime = system_getTimer()

		for i=1,#self.transitions do
			local t = self.transitions[i]
			if t ~= nil then
				-- check if length of trabsition is over (pluas a little buffer time of 15 millisecs)
				if currentTime > (t.timeStart + t.time + 15)  then
					t.state = "ended"
				end
			end
		end
	end


	--------------------------------------------------------
	-- update the system
	--
	function manager:Update()
		self:UpdateStates()
	end


    -- ##########################################################################
    -- manager:timer( event )
    -- ##########################################################################
    function manager:timer( event )
        self:Update( event )
    end
    manager.tm = timer_performWithDelay( 1, manager, 0 )

	return manager
end
 
return TransitionManager