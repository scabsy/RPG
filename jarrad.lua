---------------------------------------------------------------------------------
--
-- scene.lua
--
---------------------------------------------------------------------------------

local sceneName = ...

local composer = require( "composer" )
local physics = require("physics");
physics.start();
physics.setGravity(0,0);
-- Load scene with same root filename as this file
local scene = composer.newScene( sceneName )

---------------------------------------------------------------------------------

local nextSceneButton
local optMenu;
local rcB;
local bcB;
local gcB;
local blank;
local go;
local selected;
local options;
local text;
local textBkg;
local ghostX;
local ghostY;

local marbles = {};
local targ1;
local targ2;
local targ3;

local ghost=display.newCircle(0,0,0);
ghost.exists = false;

function getMenu(self, event)
    if event.phase == "began" then
        optMenu.x = display.contentWidth/2;
        rcB.x, rcB.y = optMenu.x - (optMenu.contentWidth * 0.375), optMenu.y;
        bcB.x, bcB.y = optMenu.x - (optMenu.contentWidth * 0.125), optMenu.y;
        gcB.x, gcB.y = optMenu.x + (optMenu.contentWidth * 0.125), optMenu.y;
        blank.x, blank.y = optMenu.x + (optMenu.contentWidth * 0.375), optMenu.y;
        cancel.x, cancel.y = optMenu.x + 125, optMenu.y + (optMenu.contentHeight - 50);
    end
end

function execute(self, event)
   if event.phase == "began" then
        if event.target == rcB then
            selected = 1;
        elseif event.target == bcB then
            selected = 2;
        elseif event.target == gcB then
            selected = 3;
        elseif event.target == blank then
            selected = 4;
        end
            print("GOOD");
            
        if selected == 1 then
            options:setFillColor(1,0,0);
        elseif selected == 2 then
            options:setFillColor(0,0,1);
        elseif selected == 3 then
            options:setFillColor(0,1,0);
        elseif selected == 4 then
            options:setFillColor(1,1,1);
        end
        
            optMenu.x = 650;
            rcB.x, rcB.y = optMenu.x - (optMenu.contentWidth * 0.375), optMenu.y;
            bcB.x, bcB.y = optMenu.x - (optMenu.contentWidth * 0.125), optMenu.y;
            gcB.x, gcB.y = optMenu.x + (optMenu.contentWidth * 0.125), optMenu.y;
            blank.x, blank.y = optMenu.x + (optMenu.contentWidth * 0.375), optMenu.y;
            cancel.x, cancel.y = optMenu.x + 125, optMenu.y + (optMenu.contentHeight - 50);
    end
end


-- Player has x, y. Monsters is a table of monsters, again with x, y as members.
function getClosestTo(ghost, marbles)
	if #marbles == 0 then
		return
	end

	local function sqrDist(a, b)
		local dx = a.x - b.x
		local dy = a.y - b.y
		return math.sqrt(dx * dx + dy * dy)
	end

	local theOne = 0
	local theDist=10000000

	for i=1,#marbles do --consider changing to pairs function\
		if marbles[i].alive then
			local dist = sqrDist(ghost, marbles[i])
			print(dist)

			if dist < theDist then
				theDist = dist
				theOne = i
			end
		end
	end
	-- if theOne==nil then
		-- print("csd")
		-- theOne=0
	-- end
		-- print(theOne)
	return theOne
end


local cycle = 0;
local vari=10
function move()
    local closest = getClosestTo(ghost, marbles);
        print(closest)
    if ghost.exists == true then
        if ghost.canMove == true then

            if closest>0 then
                
				--transition.moveTo(ghostSpawn, {x=display.contentWidth/2, y=display.contentHeight/2,time =1})
				speed = 250;
				
				
				
				deltaX = marbles[closest].x - ghost.x
				deltaY = marbles[closest].y - ghost.y
				
				angle = math.rad(math.atan2( deltaY, deltaX ) * 180 / math.pi)
				ghost:setLinearVelocity( math.cos( angle  ) * speed, math.sin( angle ) * speed )
				if ghost.x >= marbles[closest].x-vari and ghost.x <= marbles[closest].x+vari and ghost.y >= marbles[closest].y-vari and ghost.y <= marbles[closest].y+vari then
					marbles[closest].alive=false
				end
					
			else
                ghost:setLinearVelocity(0,0)
            end
        end
   
    end
end

Runtime:addEventListener("enterFrame", move);

function scene:create( event )
    local sceneGroup = self.view

    -- Called when the scene's view does not exist
    -- 
    -- INSERT code here to initialize the scene
    -- e.g. add display objects to 'sceneGroup', add touch listeners, etc
end

function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase

    if phase == "will" then
        -- Called when the scene is still off screen and is about to move on screen
        
        options = display.newRect(50,50,50,50);
        options.touch = getMenu;
        options:addEventListener("touch", options);
        
        optMenu = display.newRect(display.contentWidth/2,200,200,50);
        optMenu.x = 650;
        optMenu:setFillColor(255,180,0);
        
        rcB = display.newCircle(optMenu.x - (optMenu.contentWidth * 0.375), optMenu.y + (optMenu.contentHeight * 0.25), 12);
        rcB.touch = execute;
        rcB:setFillColor(1,0,0);
        rcB.strokeWidth = 1;
        rcB:setStrokeColor(0,0,0);
        rcB:addEventListener("touch", rcB);
        
        bcB = display.newCircle(optMenu.x - (optMenu.contentWidth * 0.125), optMenu.y + (optMenu.contentHeight * 0.25), 12);
        bcB.touch = execute;
        bcB:setFillColor(0,0,1);
        bcB.strokeWidth = 1;
        bcB:setStrokeColor(0,0,0);
        bcB:addEventListener("touch", bcB);
        
        gcB = display.newCircle(optMenu.x + (optMenu.contentWidth * 0.125), optMenu.y + (optMenu.contentHeight * 0.25), 12);
        gcB.touch = execute;
        gcB:setFillColor(0,1,0);
        gcB.strokeWidth = 1;
        gcB:setStrokeColor(0,0,0);
        gcB:addEventListener("touch", gcB);
        
        blank = display.newCircle(optMenu.x + (optMenu.contentWidth * 0.375), optMenu.y + (optMenu.contentHeight * 0.25), 12);
        blank.touch = execute;
        blank:setFillColor(1,1,1);
        blank.strokeWidth = 1;
        blank:setStrokeColor(0,0,0);
        blank:addEventListener("touch", blank)
        
        cancel = display.newRect(optMenu.x + 125, optMenu.y + (optMenu.contentHeight - 50), 50,50);
        cancel.touch = execute;
        cancel:addEventListener("touch", goB);
        
        targ1 = display.newRect(display.contentWidth * 0.9, display.contentHeight * 0.25, 25, 25);
        -- targ1.alive = false;
        targ1.alive = true;
        marbles[1] = targ1;
        targ2 = display.newRect(display.contentWidth * 0.9, display.contentHeight * 0.50, 25, 25);
        -- targ2.alive = false;
        targ2.alive = true;
        marbles[2] = targ2;
        targ3 = display.newRect(display.contentWidth * 0.9, display.contentHeight * 0.75, 25, 25);
        -- targ3.alive = false;
        targ3.alive = true;
        marbles[3] = targ3;

        -- print(marbles[2].alive);
        
        ghost = display.newCircle(0,0, 18);
        physics.addBody(ghost, "dynamic");
        ghost.exists = true;
        ghost.canMove = true;
        angle = math.random(0,360);
        ghost.x = 150 + (50 * math.cos(math.rad(angle)));
        ghost.y = display.contentHeight/2 + (50 * math.sin(math.rad(angle)));
       
        
    elseif phase == "did" then
        -- Called when the scene is now on screen
        -- 
        -- INSERT code here to make the scene come alive
        -- e.g. start timers, begin animation, play audio, etc
        
        -- we obtain the object by id from the scene's object hierarchy

        
    end 
end

function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase

    if event.phase == "will" then
        -- Called when the scene is on screen and is about to move off screen
        --
        -- INSERT code here to pause the scene
        -- e.g. stop timers, stop animation, unload sounds, etc.)
    elseif phase == "did" then
        -- Called when the scene is now off screen
		if nextSceneButton then
			nextSceneButton:removeEventListener( "touch", nextSceneButton )
		end
    end 
end


function scene:destroy( event )
    local sceneGroup = self.view

    -- Called prior to the removal of scene's "view" (sceneGroup)
    -- 
    -- INSERT code here to cleanup the scene
    -- e.g. remove display objects, remove touch listeners, save state, etc
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

---------------------------------------------------------------------------------

return scene