local composer = require( "composer" ) 
local scene = composer.newScene() 
composer.removeHidden()

-- include Corona's "physics" library 
-- local physics = require "physics" 
-- physics.start() 
-- physics.setGravity(0,0) 
-- physics.setDrawMode("hybrid") 

local CMap = require("lua.CreateMap") 
local ExtFunc = require("lua.ExtFuncs") 
local perspective = require("lua.perspective")

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
local playerSpriteSheet=graphics.newImageSheet("images/playerSS.png",{width=800,height=900,numFrames=4}) 
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
	player.speed=240
	return player
end

local playerLightSpriteSheet=graphics.newImageSheet("images/lightFilter.png",{width=1920,height=1080,numFrames=2}) 
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
-- local dayNightTimer=timer.performWithDelay(100,dayNight,-1) 
-- timer.pause(dayNightTimer)

--HUD 
local btnSize = 150 
local btnAlpha = 0.0
local btnPressed = nil 
local moveTimer 
----movement 
local leftDir={-1,0} 
local rightDir={1,0} 
local upDir={0,-1} 
local downDir={0,1} 
local stillDir = {0,0} --still need to implement a pause in the path
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
local speechBubble=display.newRoundedRect(halfW,screenH-250,800,300,45) 
speechBubble.alpha=0.8 
speechBubble.isVisible=false 
speechBubble:setStrokeColor( 0, 0, 0, .8)
speechBubble.strokeWidth = 12
local speechText=display.newText({text="",x=speechBubble.x,y=speechBubble.y,width=speechBubble.width-40,height=speechBubble.height-40,align="center",fontSize=50}) 
speechText.isVisible=false 
speechText:setFillColor(0) 
local speechArr={} 

local camera = perspective.createView()

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
	if e.keyName=="e" then
		if e.phase=="down" then
		else
			PerformActions()
		end
	end
end
--------END KEYBOARD INTERACTION-------------
function NumObjectSurroundings(j,i,value) 
   local surrVal=0 
   for l=-1,1 do 
      for k=-1,1 do 
         -- if j+k~=j or i+l~=i then 
            if map[j+k][i+l]==value then 
               surrVal=surrVal+1 
            end 
         -- end 
      end 
   end 
   return surrVal 
end 

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
	else
		-- print(player.x - player.grid[1]*90)
		-- if (player.x - player.grid[1]*90 <= 5 or player.x - player.grid[1]*90 >= -5) and (player.y - player.grid[2]*90 <= 5 or player.y - player.grid[2]*90 >= -5) then
			-- player.moving = false
		-- end
	end 
end 

function MovePlayer(character)	
	transition.to(character,{time=character.speed,x=character.grid[1]*90,y=character.grid[2]*90,onComplete=function() ChangeMoving(character) end}) 
end 

function ChangeMoving(character)
	if character==player then
		character.moving = false
	else
		if character.charPath then			
			character.moving = false
		else		
			character.moving = false
		end
	end
end

function interact(e) 
	if e.phase=="ended" then 
		PerformActions()
	end 
end 

function PerformActions()
	local interactionX=player.grid[1] + player.direction[1] 
	local interactionY=player.grid[2] + player.direction[2] 
	if actions[interactionX][interactionY]~=nil then 
		if actions[interactionX][interactionY][1][1]=="speech" then 
			displaySpeech(actions[interactionX][interactionY][1][2]) 
		elseif actions[interactionX][interactionY][1][1]=="enter" then	
			-- paused=true
			local params={effect="fade",time=200,params={mapOrigin="lvl_home",mapToLoad=actions[interactionX][interactionY][1][2],gridX=actions[interactionX][interactionY][1][3],gridY=actions[interactionX][interactionY][1][4]}}
			composer.gotoScene( "lua.lvl_transition",params)
			-- displaySpeech("This is where you would enter the building. The scene will change to the inside.")

		elseif actions[interactionX][interactionY][1][1]=="fight" then
			local enemyCount=NumObjectSurroundings(player.grid[2],player.grid[1],"N")
			local params={effect="fade",time=300,params={mapOrigin="lua.lvl_home",mapToLoad="lua.fight",numOfEnemy=enemyCount,gridX=player.grid[1],gridY=player.grid[2]}}
			composer.gotoScene( "lua.lvl_transition",params)
		end
		
		if  actions[interactionX][interactionY][1][3] then
			actions[interactionX][interactionY][1][3]()
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
   Runtime:removeEventListener("key",KeyNextText)
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
   speechBubble.x,speechBubble.y = player.x,player.y+300
   speechText.x,speechText.y = player.x,player.y+300
   
   function cycleText() 
	 if arrIndex<#speechArr then 
		arrIndex=arrIndex+1 
		speechText.text=speechArr[arrIndex] 
	 else 
		clearSpeech() 
	 end 
   end 
   
	function KeyNextText(e)
		if e.keyName=="e" then
			if e.phase=="down" then
			else
				cycleText()
			end
		end
	end
	Runtime:addEventListener("key",KeyNextText)
	
	function nextText(e)
		if e.phase=="ended" then 
			cycleText()
		end
	end
	btnA:addEventListener("touch",nextText) 
   
end 

function AddRemoveMovement(addRemove) 
	if addRemove=="add" then 
		paused = false
		btnU:addEventListener("touch",moveBtnAction) 
		btnD:addEventListener("touch",moveBtnAction) 
		btnL:addEventListener("touch",moveBtnAction) 
		btnR:addEventListener("touch",moveBtnAction) 
		btnA:addEventListener("touch",interact)
		Runtime:addEventListener("key",onKeyEvent)
	elseif addRemove=="remove" then
		paused = true
		btnU:removeEventListener("touch",moveBtnAction) 
		btnD:removeEventListener("touch",moveBtnAction) 
		btnL:removeEventListener("touch",moveBtnAction) 
		btnR:removeEventListener("touch",moveBtnAction) 
		btnA:removeEventListener("touch",interact) 
		Runtime:removeEventListener("key",onKeyEvent)
	end 
end 

function UpdateUILoc()
	btnA.x,btnA.y = player.x+750,player.y+300
	btnU.x,btnU.y = player.x-750,player.y+150
	btnD.x,btnD.y = player.x-750,player.y+450
	btnL.x,btnL.y = player.x-900,player.y+300
	btnR.x,btnR.y = player.x-600,player.y+300
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
			
			local continue=false
			if ExtFunc.contains(map[character.newGrid[2]][character.newGrid[1]])==false then
				continue=true
			else
				if character.direction[1]==0 and character.direction[2]==0 then 
					continue=true
				end
			end
			
			
			
			if continue then 
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
   npc.speed=speed
   npc:scale(.1,.1) 
   if path then 
      npc.charPath=path 
      npc.currentPathAct=1 
   else 
      npc.charPath=nil 
      npc.currentPathAct=0 
   end 
   npc.pathRepeat=repeatPath 
   npc.oldTile=map[y][x] 
   npc.oldAction=actions[x][y] 
   map[y][x]=npc.identifier 
   actions[x][y]=npc.actions 
   -- group:insert(npc) 
   MovePlayer(npc) 
   NPCTimers[#NPCTimers+1]=timer.performWithDelay(1,function() GetNewGrid(npc) end,-1) 
   return npc 
end 

function transAway()
	for i=1,#NPCTimers do
		timer.pause(NPCTimers[i])
	end
	
	-- Runtime:removeEventListener("enterFrame",followPlayer)
	-- Runtime:removeEventListener("key",onKeyEvent)
	map={}
	CMap.map={}
	CMap.base={}
	CMap.tile={}
	CMap.addTile={}
	CMap.actions={}
	AddRemoveMovement("remove") 
end

function transTo()
	-- Runtime:addEventListener("enterFrame",followPlayer) 
	-- Runtime:addEventListener("key",onKeyEvent)
end

function scene:create( event ) 
	local params=event.params
	local scene=self.view
	CMap.createMap("lvl_home.txt") 
	map=CMap.map
	actions=CMap.actions
	moveTimer = timer.performWithDelay(1,move,-1) 
	timer.pause(moveTimer) 
	player=CreatePlayer()
	
	player.grid[1],player.grid[2]=params.gridX,params.gridY

	MovePlayer(player) 
	playerLight.x, playerLight.y=halfW,halfH 
	player:setFillColor(0.9,0.2,0.5) 
	
	for i=1,#map[1] do
		for j=1,#map do
			if CMap.base[i][j]~= nil then
				-- scene:insert(CMap.base[i][j])
				camera:add(CMap.base[i][j],5)
			end
			if CMap.tile[i][j]~= nil then
				-- scene:insert(CMap.tile[i][j])
				camera:add(CMap.tile[i][j],2)
			end
			if CMap.addTile[i][j]~= nil and CMap.addTile[i][j].layer==2 then
				-- scene:insert(CMap.addTile[i][j])
				camera:add(CMap.addTile[i][j],2)
			end
			if CMap.tileText[i][j]~= nil then
				-- scene:insert(CMap.tileText[i][j])
			end
		end
	end
	
	-- scene:insert(player)
	camera:add(player,2,true)
	AddRemoveMovement("add")
	
	--------------------**************LEVEL SPECIFIC ADDITIONS*******************--------------------
	-- local speechMsg="Welcome home weary traveller. Things have changed since your last visit, so have a look around. Your family will want to see you so don't take too long." 
	-- displaySpeech(speechMsg) 
	actions[22][21]={{"speech","The oldest tree on the island. 600 years old and still going. Good to see some things don't change."}} 	
	actions[28][34]={{"enter","lua.lvl_home_house1",3,10}}
	actions[29][29]={{"enter","lua.lvl_home_house1",6,3}}
	actions[33][26]={{"enter","lua.lvl_home_house2",3,4}}
	actions[32][13]={{"enter","lua.lvl_home_house2",3,4}}
	
	
	local npc1, npc2, npc3
	
	
	
	
	local npc1Path={rightDir,rightDir,downDir,downDir,downDir,downDir,downDir,downDir,downDir, 
				   leftDir,downDir,downDir,downDir,downDir,leftDir,leftDir,leftDir,leftDir, 
				   leftDir,leftDir,leftDir,leftDir,downDir,leftDir,leftDir,leftDir,leftDir, 
				   leftDir,leftDir,upDir,upDir,upDir,upDir,rightDir,upDir,rightDir,rightDir, 
				   upDir,upDir,leftDir,upDir,upDir,rightDir,upDir,upDir,upDir,upDir,rightDir, 
				   rightDir,rightDir,rightDir,rightDir,downDir,rightDir,rightDir,rightDir, 
				   rightDir,rightDir} 
	local npc1Actions={{"speech","Hello there, William. You may want to get home quickly. Something has happened."}} 
	npc1=CreateNPC(26,17,npc1Path,250,true,npc1Actions) 
	-- local npc1=CreateNPC(26,17,nil,250,false,npc1Actions) 
	-- scene:insert(npc1)
	camera:add(npc1,2)
	local npc2PathA = {rightDir, rightDir, stillDir,stillDir, leftDir, leftDir,stillDir, stillDir}
	local npc2PathB = {rightDir, rightDir,rightDir}
	
	function UpdateNPC2() 
		npc2.charPath=npc2PathB 
		npc2.repeatPath=false 
		npc2.currentPathAct=1
	end
	
	local npc2Actions = {{"speech","Before you go in there, ready yourself. You are not going to like it. There is blood everywhere, all over the walls, the floor. They were massacred, William. It was the Romans.", UpdateNPC2}}

	npc2=CreateNPC(26,35,npc2PathA,250,true,npc2Actions) 
	-- scene:insert(npc2)	
	camera:add(npc2,2)	
	local npc3Actions={{"fight"}}
	npc3=CreateNPC(24,33,nil,900,true,npc3Actions) 
	-- scene:insert(npc3)
	camera:add(npc3,2)
	--------------------**************END LEVEL SPECIFIC ADDITIONS****************--------------------

	for i=1,#map[1] do
		for j=1,#map do
			if CMap.addTile[i][j]~=nil and CMap.addTile[i][j].layer==1  then
				-- camera:insert(CMap.addTile[i][j])
				camera:add(CMap.addTile[i][j],2)
			end
		end
	end 
	-- function followPlayer()
		-- scene.x=-player.x+screenW*.5
		-- scene.y=-player.y+screenH*.5
	-- end
	
	
	camera:add(speechBubble,1)
	camera:add(speechText,1)
	
	camera:add(btnA,1)
	camera:add(btnU,1)
	camera:add(btnD,1)
	camera:add(btnL,1)
	camera:add(btnR,1)
	
	camera.damping=5
	camera:setFocus(player[3])
	camera:track()
	
	Runtime:addEventListener("enterFrame", UpdateUILoc)
end 


function scene:show( event ) 
   local sceneGroup = self.view 
   local phase = event.phase 
   if phase == "will" then 
		transTo()
   elseif phase == "did" then 
   end 
end 

function scene:hide( event ) 
	local sceneGroup = self.view 
	local phase = event.phase 
	if event.phase == "will" then 
		transAway()
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
