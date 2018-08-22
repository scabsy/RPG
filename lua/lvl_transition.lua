local composer = require( "composer" )
local scene = composer.newScene()

local screenW, screenH, halfW = display.contentWidth, display.contentHeight, display.contentWidth*0.5
--------------------------------------------

function scene:create( event )
	local params=event.params
	
	print(params.mapToLoad)
	function onLoad()
		if params.mapToLoad~="lua.fight" then
			local params={effect="fade",time=200,params={mapToLoad=params.mapToLoad,gridX=params.gridX,gridY=params.gridY}}
			composer.gotoScene( params.params.mapToLoad,params )
			return true
		elseif params.mapToLoad=="lua.fight" then
			local params={effect="fade",time=200,params={mapOrigin=params.mapOrigin,mapToLoad=params.mapToLoad,gridX=params.gridX,gridY=params.gridY,numOfEnemy=params.numOfEnemy}}
			print("asdc"..params.params.numOfEnemy)
			composer.gotoScene( params.params.mapToLoad,params )
			return true
		end
	end
end

function scene:show( event )
	local sceneGroup = self.view
	local params=event.params
	local phase = event.phase
	
	if phase == "will" then		
	elseif phase == "did" then		
		onLoad()
	end	
end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase
	local params=event.params
	
	if event.phase == "will" then
	elseif phase == "did" then
	end	
end

function scene:destroy( event )
	local sceneGroup = self.view
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene