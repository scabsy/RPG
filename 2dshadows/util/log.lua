-------------------------------------------------
--
-- Log.lua
--
-- Creates a logging class 
--
-------------------------------------------------

local Log = {}

Log.level = 1

-----------------------------------------------------------------------------
-- Log:p( loglevel, ... )
-----------------------------------------------------------------------------
function Log:p( loglevel, ... )
		if loglevel == 0 then return end
		if loglevel > 0 and loglevel <= self.level then
				local txt = ""

				for i=1,#arg do
						txt = txt .. tostring( arg[i] ) .. " "
				end

				print(txt)
		end
end


-----------------------------------------------------------------------------
-- Log:q( loglevel, title, ... )
-----------------------------------------------------------------------------
function Log:q( loglevel, title, ... )
		if loglevel == 0 then return end
		if loglevel > 0 and loglevel <= self.level then
				local txt = "\n---------- " .. title .. "----------\n"

				for i=1,#arg do
						txt = txt .. tostring( arg[i] ) .. " "
				end
				txt = txt .. "\n"

				print(txt)
		end
end

-----------------------------------------------------------------------------
-- Log:Print( loglevel, ... )
-- only log:p with a loglevel smaller or equal the current loglevel are printed to console
-----------------------------------------------------------------------------
function Log:SetLogLevel( newloglevel )
		print("Log:SetLogLevel", newloglevel)
		self.level = newloglevel
end



 
return Log