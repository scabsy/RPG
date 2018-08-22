local widget = require( "widget" )
local composer = require( "composer" ) 
local scene = composer.newScene()
composer.removeHidden()


local screenW, screenH, halfW,halfH = display.actualContentWidth, display.actualContentHeight, display.contentCenterX,display.contentCenterY 

local actions={"attack","heal","run"}
local healthBarsG={}
local healthBarsR={}
local enemyCount=0
local deadNPCs=0

local charMaxHealth=100
local playerSpriteSheet=graphics.newImageSheet("images/playerSS.png",{width=800,height=900,numFrames=4}) 
local playerSequenceData={{name="up",start=1,count=1},{name="down",start=2,count=1},{name="left",start=3,count=1},{name="right",start=4,count=1}} 
local player=display.newSprite(playerSpriteSheet,playerSequenceData) 
player.x,player.y=screenW/4,screenH/2
player.health=charMaxHealth
player.actions={}
player.ready=false
healthBarsR[player]=display.newRect(player.x,player.y-player.height/2,250,80)
healthBarsR[player]:setFillColor(1,0,0)
healthBarsG[player]=display.newRect(player.x,player.y-player.height/2,250,80)
healthBarsG[player]:setFillColor(0,1,0)

function UpdateHealthBar(character)	
	healthBarsG[character].width=(character.health/charMaxHealth)*healthBarsR[character].width
	healthBarsG[character].x=character.x-(healthBarsR[character].width-healthBarsG[character].width)/2
end



local menuView = widget.newScrollView(
    {
        x = screenW/2,
        y = screenH/2,
        width = 300,
        height = 500,
		isLocked=true
    }
)
-- menuView.isVisible=false

local actionSelectTxt=display.newText("NPC ",24,25)
actionSelectTxt:setFillColor(0,0,0)
actionSelectTxt.x,actionSelectTxt.y=menuView.width/2,menuView.height/2-210
menuView:insert(actionSelectTxt)

function playerActions(e)
	local btn = e.target
	if e.phase=="ended" then
		player.actions[#player.actions+1]=e.target.action
		if #player.actions==enemyCount then
			player.ready=true
			menuView.isVisible=false
		end
		print(player.actions[#player.actions])
	end
end

local actionBtns={}
local actionBtnsTxt={}
for i=1,#actions do
	actionBtns[i]=display.newRect(menuView.width/2,menuView.height/2-210+110*i,200,80)
	actionBtns[i]:setFillColor(0,0,0)
	actionBtns[i].action=actions[i]
	actionBtnsTxt[i]=display.newText(actions[i],24,25)	
	actionBtnsTxt[i]:setFillColor(1,1,1)
	actionBtnsTxt[i].x,actionBtnsTxt[i].y=actionBtns[i].x,actionBtns[i].y
	actionBtns[i]:addEventListener("touch",playerActions)
	menuView:insert(actionBtns[i])
	menuView:insert(actionBtnsTxt[i])
end

local npcs={}
function selectActions(npc)
	local nextAction
	local val=math.random(1,6)
	if npc.health<40 then
		if val>2 then
			nextAction=actions[2]
		else
			nextAction=actions[1]
		end
	else
		if val>4 then
			if npc.health<charMaxHealth then
				nextAction=actions[2]
			else				
				nextAction=actions[1]
			end
		else
			nextAction=actions[1]
		end
	end
	return nextAction
end

function GenerateActions()
	-- player.actions={}
	-- menuView.isVisible=true
	for i=1,#npcs do		
		npcs[i].action=selectActions(npcs[i])
		print(npcs[i].action)
		-- player.actions[i]=actions[math.random(1,2)]
	end	
	
	if player.ready then
		timer.performWithDelay(1000,Fight,1)
	else
		timer.performWithDelay(500,GenerateActions,1)
	end
end

local pAct=1
local nAct=1
function Fight()
	if player.actions[pAct] == "attack" then
		attack(player,npcs[pAct])
	elseif player.actions[pAct] == "heal" then
		heal(player)
	elseif player.actions[pAct] == "run" then
		print("Player chose to run. Not yet implemented")
	end
	
	if npcs[nAct].action == "attack" then
		attack(npcs[nAct],player)
	elseif npcs[nAct].action == "heal" then
		heal(npcs[nAct])
	end
	
	if player.health<=0 or deadNPCs>=enemyCount then
		timer.performWithDelay(1000,ReturnToMap,1)
	else		
		if pAct<#player.actions then
			pAct=pAct+1
			nAct=nAct+1
			timer.performWithDelay(1000,Fight,1)
		else			
			pAct=1
			nAct=1
			player.actions={}
			player.ready=false
			menuView.isVisible=true
			GenerateActions()
		end
	end
end

function CreateNPC()
	local npc=display.newSprite(playerSpriteSheet,playerSequenceData) 
	npc.health=charMaxHealth
	npc.powerMult=1
	npc.action=""
	return npc
end

function heal(character)
	local amt=15
	if character~=player then
		amt=amt/enemyCount
	end
	character.health = character.health + amt
	if character.health > charMaxHealth then
		character.health = charMaxHealth
	end
	UpdateHealthBar(character)
end

function attack(self,enemy)
	local oldX=self.x
	local newX=(oldX-enemy.x)/3
	transition.to(self,{x=self.x-newX,time=200})
	local amt=25
	function swing()
		if enemy==player then
			amt=amt/enemyCount
		end
		enemy.health = enemy.health - amt
		if enemy.health < 0 then
			enemy.isVisible=false
			healthBarsG[enemy].isVisible=false
			healthBarsR[enemy].isVisible=false
				deadNPCs = deadNPCs + 1
		end
		UpdateHealthBar(enemy)
		
		transition.to(self,{x=oldX,time=200})
	end
	timer.performWithDelay(300,swing,1)
end

local returnparams = nil
function ReturnToMap()
	composer.gotoScene( "lua.lvl_transition",returnparams)
end

function scene:create( event )
	local params=event.params
    local sceneGroup = self.view
	local menuGroup = self.view
	
	returnparams={effect="fade",time=200,params={mapToLoad=params.mapOrigin,gridX=params.gridX, gridY=params.gridY}}
	local background=display.newRect(screenW/2,screenH/2,screenW,screenH)
	background:setFillColor(0,0,1)
	
	local lvlfloor=display.newImageRect("images/grass.png",screenW,screenH/6)
	lvlfloor.x, lvlfloor.y=screenW/2,screenH-lvlfloor.height*.5
	
	sceneGroup:insert(background)
	sceneGroup:insert(lvlfloor)
	sceneGroup:insert(player)
	
	enemyCount=params.numOfEnemy
	-- enemyCount=3
	for i=1,enemyCount do
		npcs[i]=CreateNPC()
		npcs[i].x,npcs[i].y=screenW/4*2 + i*280,screenH/2
		
		healthBarsR[npcs[i]]=display.newRect(npcs[i].x,npcs[i].y-npcs[i].height/2,250,80)
		healthBarsR[npcs[i]]:setFillColor(1,0,0)
		healthBarsG[npcs[i]]=display.newRect(npcs[i].x,npcs[i].y-npcs[i].height/2,250,80)
		healthBarsG[npcs[i]]:setFillColor(0,1,0)
		sceneGroup:insert(npcs[i])
	end		
	
	for i,value in pairs(healthBarsR) do 
		sceneGroup:insert(value)
	end  
	for i,value in pairs(healthBarsG) do 
		sceneGroup:insert(value)
	end 

	sceneGroup:insert(menuView)
	GenerateActions()
	function HBFollowChar()
		healthBarsG[player].x=player.x-(healthBarsR[player].width-healthBarsG[player].width)/2
		healthBarsR[player].x=player.x
		
		for i=1,enemyCount do
			healthBarsG[npcs[i]].x=npcs[i].x-(healthBarsR[npcs[i]].width-healthBarsG[npcs[i]].width)/2
			healthBarsR[npcs[i]].x=npcs[i].x
		end
	end
end
 
 
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
    elseif ( phase == "did" ) then
	
		Runtime:addEventListener("enterFrame",HBFollowChar)
    end
end
 
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
		Runtime:removeEventListener("enterFrame",HBFollowChar)
    elseif ( phase == "did" ) then
    end
end
 
 
-- destroy()
function scene:destroy( event )
    local sceneGroup = self.view
end
 
 
-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------
 
return scene