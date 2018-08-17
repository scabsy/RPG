local composer = require( "composer" ) 
local scene = composer.newScene() 
composer.removeHidden()

-- include Corona's "physics" library 
-- local physics = require "physics" 
-- physics.start() 
-- physics.setGravity(0,0) 
-- physics.setDrawMode("hybrid") 

local CMap = require("CreateMap") 
local ExtFunc = require("ExtFuncs") 

-- local perspective = require("perspective") 
-- local camera = perspective.createView() 

-- local Shadows=require("2dshadows.shadows") 
-------------------------------------------- 

--***************VARIABLES***************-- 
local screenW, screenH, halfW,halfH = display.actualContentWidth, display.actualContentHeight, display.contentCenterX,display.contentCenterY 
local paused = true

local gridSize = 90 
--player 
local player	
local playerSpriteSheet=graphics.newImageSheet("playerSS.png",{width=800,height=900,numFrames=4}) 
local playerSequenceData={{name="up",start=1,count=1},{name="down",start=2,count=1},{name="left",start=3,count=1},{name="right",start=4,count=1}} 

function CreatePlayer()
	local playerSpeed = gridSize 
	local playerSize = 90 
	player=display.newSprite(playerSpriteSheet,playerSequenceData) 
	player.grid={} 
	player:scale(.1,.1) 
	player.moving = false 
	player.oldTile="1" 
	player.direction={0,-1} 
	-- player.speed=
	return player
end

local playerLightSpriteSheet=graphics.newImageSheet("lightFilter.png",{width=1920,height=1080,numFrames=2}) 
local playerLightSequenceData={{name="light",start=1,count=1},{name="nolight",start=2,count=1}} 
local playerLight=display.newSprite(playerLightSpriteSheet,playerLightSequenceData) 
playerLight:scale(1.5,1.5) 
playerLight.alpha=0 
playerLight:setSequence("nolight") 

local maxDark=0.98 
local lightOnDark=0.65 
local lightChange = 0.01 

--environment 
local levelData = {}
local map={} 
local actions={} 
local toNight=true 
-- local dayNightTimer=timer.performWithDelay(1000,dayNight,-1) 
-- timer.pause(dayNightTimer)

--HUD 
local btnSize = 150 
local btnAlpha = 0.2 
local btnPressed = nil 
local moveTimer 
----movement 
local leftDir={-1,0} 
local rightDir={1,0} 
local upDir={0,-1} 
local downDir={0,1} 
local newGrid={} 
local btnU=display.newRect(300,screenH-400,btnSize,btnSize) 
btnU.dir = upDir 
btnU.frame="up" 
local btnD=display.newRect(300,screenH-100,btnSize,btnSize) 
btnD.dir = downDir 
btnD.frame="down" 
local btnL=display.newRect(150,screenH-250,btnSize,btnSize) 
btnL.dir = leftDir 
btnL.frame="left" 
local btnR=display.newRect(450,screenH-250,btnSize,btnSize) 
btnR.dir = rightDir 
btnR.frame="right" 

btnU.alpha=btnAlpha 
btnD.alpha=btnAlpha 
btnL.alpha=btnAlpha 
btnR.alpha=btnAlpha 
----interaction 
local btnA=display.newRect(screenW-300,screenH-250,btnSize,btnSize) 
btnA.alpha=btnAlpha 

----speech 
local speechBubble=display.newRect(halfW,screenH-250,800,300) 
speechBubble.alpha=0.8 
speechBubble.isVisible=false 
local speechText=display.newText({text="",x=speechBubble.x,y=speechBubble.y,width=speechBubble.width-40,height=speechBubble.height-40,align="center"}) 
speechText.isVisible=false 
speechText:setFillColor(0) 
local speechArr={} 

--***************FUNCTIONS***************-- 
--------KEYBOARD INTERACTION-------------
function onKeyEvent(e)
	if e.keyName=="a" then
		if e.phase == "down" then
		  btnPressed = btnL 
		  Runtime:addEventListener("enterFrame",move) 
		else
		  btnPressed = nil 
		  Runtime:removeEventListener("enterFrame",move) 
		end
	end
	if e.keyName=="d" then
		if e.phase == "down" then
		  btnPressed = btnR 
		  Runtime:addEventListener("enterFrame",move) 
		else
		  btnPressed = nil 
		  Runtime:removeEventListener("enterFrame",move) 
		end
	end
	if e.keyName=="w" then
		if e.phase == "down" then
		  btnPressed = btnU
		  Runtime:addEventListener("enterFrame",move) 
		else
		  btnPressed = nil 
		  Runtime:removeEventListener("enterFrame",move) 
		end
	end
	if e.keyName=="s" then
		if e.phase == "down" then
		  btnPressed = btnD 
		  Runtime:addEventListener("enterFrame",move) 
		else
		  btnPressed = nil 
		  Runtime:removeEventListener("enterFrame",move) 
		end
	end
end
--------END KEYBOARD INTERACTION-------------
function moveBtnAction(e) 
   if e.phase=="began" then 
      btnPressed = e.target 
      Runtime:addEventListener("enterFrame",move) 
   elseif e.phase=="moved" then 
   elseif e.phase=="ended" then 
      btnPressed = nil 
      Runtime:removeEventListener("enterFrame",move) 
   end 
end 

function move() 
   if player.moving == false then 
      player.newGrid={player.grid[1] + btnPressed.dir[1],player.grid[2] + btnPressed.dir[2]} 
      player.direction={btnPressed.dir[1],btnPressed.dir[2]} 
      player:setSequence(spriteDir(player.direction)) 
      if ExtFunc.contains(map[player.newGrid[2]][player.newGrid[1]])==false then 
         local currGrid={player.grid[1],player.grid[2]} 
         map[currGrid[2]][currGrid[1]]=player.oldTile 
         player.oldTile=map[player.newGrid[2]][player.newGrid[1]] 
         map[player.newGrid[2]][player.newGrid[1]]="A" 
         player.grid[1]=player.newGrid[1] 
         player.grid[2]=player.newGrid[2] 
         player.moving=true 
         MovePlayer(player) 
         map[currGrid[2]][currGrid[1]]=player.oldTile 
      end 
   end 
end 

function MovePlayer(character) 
   transition.to(character,{time=300,x=character.grid[1]*90,y=character.grid[2]*90,onComplete=function() character.moving = false end}) 
end 

function interact(e) 
	if e.phase=="ended" then 
		local interactionX=player.grid[1] + player.direction[1] 
		local interactionY=player.grid[2] + player.direction[2] 
		if actions[interactionX][interactionY]~=nil then 
			if actions[interactionX][interactionY][1][1]=="speech" then 
				displaySpeech(actions[interactionX][interactionY][1][2]) 
			elseif actions[interactionX][interactionY][1][1]=="enter" then	
				------***********************place lvl name in mapOrigin************************
				------***********************place lvl name in mapOrigin************************
				------***********************place lvl name in mapOrigin************************
				------***********************place lvl name in mapOrigin************************
				local missionParams={effect="fade",time=200,params={mapOrigin="lvl_home_house2",mapToLoad=actions[interactionX][interactionY][1][2],gridX=actions[interactionX][interactionY][1][3],gridY=actions[interactionX][interactionY][1][4]}}
				composer.gotoScene( "lvl_transition",missionParams)
				-- displaySpeech("This is where you would enter the building. The scene will change to the inside.") 
			end 
		end 
	end 
end 

function dayNight() 
   if toNight then 
      playerLight.alpha=playerLight.alpha+lightChange 
      if playerLight.alpha>lightOnDark then 
         playerLight:setSequence("light") 
      end 
      if playerLight.alpha>=maxDark then 
         toNight=false 
      end 
   else 
      playerLight.alpha=playerLight.alpha-lightChange 
      if playerLight.alpha<lightOnDark then 
         playerLight:setSequence("nolight") 
      end 
      if playerLight.alpha<=0 then 
         toNight=true 
      end 
   end 
end 

function clearSpeech() 
   speechBubble.isVisible=false 
   speechText.isVisible=false 
   speechArr={} 
   btnA:removeEventListener("touch",cycleText) 
   AddRemoveMovement("add") 
end 

function displaySpeech(speech) 
   local tmpStr=speech 
   local currIndex 
   local startIndex=1 
   local arrIndex=1 
   if #tmpStr<=100 then 
      speechArr[#speechArr+1]=tmpStr 
   else 
      tmpStr=string.reverse(string.sub(speech,startIndex,startIndex+99)) 
      while #tmpStr > 99 do 
         currIndex=string.find(tmpStr,"%.") 
         currIndex=100-currIndex+2 
         speechArr[#speechArr+1]=string.sub(string.reverse(tmpStr),1,currIndex) 
         startIndex=startIndex+currIndex 
         if startIndex+99>#speech then 
            tmpStr=string.reverse(string.sub(speech,startIndex)) 
         else 
            tmpStr=string.reverse(string.sub(speech,startIndex,startIndex+99)) 
         end 
      end 
      speechArr[#speechArr+1]=string.sub(speech,startIndex) 
   end 
   speechText.text=speechArr[arrIndex] 
   AddRemoveMovement("remove") 
   speechBubble.isVisible=true 
   speechText.isVisible=true 
   function cycleText(e) 
      if e.phase=="ended" then 
         if arrIndex<#speechArr then 
            arrIndex=arrIndex+1 
            speechText.text=speechArr[arrIndex] 
         else 
            clearSpeech() 
         end 
      end 
   end 
   btnA:addEventListener("touch",cycleText) 
end 

function AddRemoveMovement(addRemove) 
	if addRemove=="add" then 
		paused = false
		btnU:addEventListener("touch",moveBtnAction) 
		btnD:addEventListener("touch",moveBtnAction) 
		btnL:addEventListener("touch",moveBtnAction) 
		btnR:addEventListener("touch",moveBtnAction) 
		btnA:addEventListener("touch",interact) 
	elseif addRemove=="remove" then
		paused = true
		btnU:removeEventListener("touch",moveBtnAction) 
		btnD:removeEventListener("touch",moveBtnAction) 
		btnL:removeEventListener("touch",moveBtnAction) 
		btnR:removeEventListener("touch",moveBtnAction) 
		btnA:removeEventListener("touch",interact) 
	end 
end 

function spriteDir(dir) 
   if dir[1]==-1 and dir[2]==0 then 
      return "left" 
   elseif dir[1]==1 and dir[2]==0 then 
      return "right" 
   elseif dir[1]==0 and dir[2]==-1 then 
      return "up" 
   elseif dir[1]==0 and dir[2]==1 then 
      return "down" 
   end 
end 

function GetNewGrid(character) 
	if paused~=true then
		if character.moving == false and character.charPath then 
			character.newGrid={character.grid[1] + character.charPath[character.currentPathAct][1],character.grid[2] + character.charPath[character.currentPathAct][2]} 
			character.direction={character.charPath[character.currentPathAct][1],character.charPath[character.currentPathAct][2]} 
			character:setSequence(spriteDir(character.direction)) 
			if ExtFunc.contains(map[character.newGrid[2]][character.newGrid[1]])==false then 
				local currGrid={character.grid[1],character.grid[2]} 
				map[currGrid[2]][currGrid[1]]=character.oldTile 
				character.oldTile=map[character.newGrid[2]][character.newGrid[1]] 
				map[character.newGrid[2]][character.newGrid[1]]=character.identifier 
				if character.actions then 
					actions[currGrid[1]][currGrid[2]]=character.oldAction 
					character.oldAction=actions[character.newGrid[1]][character.newGrid[2]] 
					actions[character.newGrid[1]][character.newGrid[2]]=character.actions 
				end 
				character.grid[1]=character.newGrid[1] 
				character.grid[2]=character.newGrid[2] 
				character.moving=true 
				MovePlayer(character) 
				map[currGrid[2]][currGrid[1]]=character.oldTile 
				if character.actions then 
					actions[currGrid[1]][currGrid[2]]=character.oldActions 
				end 
				if character.currentPathAct<#character.charPath then 
					character.currentPathAct=character.currentPathAct+1 
				else 
					if character.pathRepeat then 
						character.currentPathAct=1 
					else 
						character.charPath=nil 
					end 
				end 
			end 
		end 
	end
end 

--Create new NPC 
--x,y - grid location on the map 
--path - array of single element movements using leftDir,downDir,rightDir,upDir as the keywords 
--speed - time in ms that the NPC will pause in between each movement 
--repeatPath - boolean determining if NPC will repeat movement in path once all elements have completed 
--npcActions - array of actions in the format {{type,data},{type,data}} 
local NPCTimers={}
function CreateNPC(x,y,path,speed,repeatPath,npcActions) 
   local npc=display.newSprite(playerSpriteSheet,playerSequenceData) 
   if npcActions then 
      npc.actions=npcActions 
   else 
      npc.actions=nil 
   end 
   npc.identifier="N" 
   npc.grid={x,y} 
   npc.newGrid={} 
   npc.moving=false 
   npc:scale(.1,.1) 
   if path then 
      npc.charPath=path 
      npc.currentPathAct=1 
   else 
      npc.charPath=nil 
      npc.currentPathAct=0 
   end 
   npc.pathRepeat=repeatPath 
   npc.oldTile=map[x][y] 
   npc.oldAction=actions[y][x] 
   map[x][y]=npc.identifier 
   actions[y][x]=npc.actions 
   -- group:insert(npc) 
   MovePlayer(npc) 
   NPCTimers[#NPCTimers+1]=timer.performWithDelay(speed,function() GetNewGrid(npc) end,-1) 
   return npc 
end 

function PrepareToTransition()
	for i=1,#NPCTimers do
		timer.cancel(NPCTimers[i])
	end
	-- timer.cancel(dayNightTimer)
	
	Runtime:removeEventListener("enterFrame",followPlayer)
	Runtime:removeEventListener("key",onKeyEvent)
	map={}
	CMap.map={}
	CMap.base={}
	CMap.tile={}
	CMap.addTile={}
	CMap.actions={}
	AddRemoveMovement("remove") 
end

function scene:create( event ) 
	local params=event.params
	local scene=self.view
	----------*********************place source txt file in createMap*******------------
	----------*********************place source txt file in createMap*******------------
	----------*********************place source txt file in createMap*******------------
	----------*********************place source txt file in createMap*******------------
	CMap.createMap("lvl_home_house2.txt") 
	map=CMap.map
	actions=CMap.actions
	moveTimer = timer.performWithDelay(50,move,-1) 
	timer.pause(moveTimer) 
	player=CreatePlayer()
	
	player.grid[1],player.grid[2]=params.gridX,params.gridY

	MovePlayer(player) 
	playerLight.x, playerLight.y=halfW,halfH 
	player:setFillColor(0.9,0.2,0.5) 
	print(#map[1],#map)
	for i=1,#map[1] do
		for j=1,#map do		
			if CMap.base[i][j]~= nil then
				scene:insert(CMap.base[i][j])
			end
			if CMap.tile[i][j]~= nil then
				scene:insert(CMap.tile[i][j])
			end
			if CMap.addTile[i][j]~= nil and CMap.addTile[i][j].layer==2 then
				scene:insert(CMap.addTile[i][j])
			end
		end
	end
	
	scene:insert(player)
	AddRemoveMovement("add")
	
	--------------------**************LEVEL SPECIFIC ADDITIONS*******************--------------------
	actions[3][5]={{"enter","lvl_home",33,25}}
	--------------------**************END LEVEL SPECIFIC ADDITIONS****************--------------------

	for i=1,#map[1] do
		for j=1,#map do
			if CMap.addTile[i][j]~=nil and CMap.addTile[i][j].layer==1  then
				scene:insert(CMap.addTile[i][j])
			end
		end
	end 
	function followPlayer()
		scene.x=-player.x+screenW*.5
		scene.y=-player.y+screenH*.5
	end
end 


function scene:show( event ) 
   local sceneGroup = self.view 
   local phase = event.phase 
   if phase == "will" then 
		Runtime:addEventListener("enterFrame",followPlayer) 
		Runtime:addEventListener("key",onKeyEvent)
   elseif phase == "did" then 
   end 
end 

function scene:hide( event ) 
	local sceneGroup = self.view 
	local phase = event.phase 
	if event.phase == "will" then 
		PrepareToTransition()
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
