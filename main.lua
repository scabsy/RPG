-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- hide the status bar
display.setStatusBar( display.HiddenStatusBar )

-- include the Corona "composer" module
local composer = require "composer"

-- load menu screen
-- local missionParams={effect="fade",time=200,params={mapToLoad="lvl_home",gridX=18,gridY=6}}
local missionParams={effect="fade",time=200,params={mapToLoad="lvl_home",gridX=23,gridY=32}}
-- composer.gotoScene( "lvl_home",missionParams )
composer.gotoScene( "lvl_home",missionParams)
-- composer.gotoScene("jarrad")