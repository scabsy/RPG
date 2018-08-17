local t={}
t.map={}
t.base={}
t.tile={}
t.addTile={}
t.tileText={}
t.actions={}
-- t.player={}

local gridSize = 90 

function readMap(mapTxt)
   local line 
   local lchar 
   local i,j=1,1 
   -- local map={}
   local mapPath=system.pathForFile(mapTxt,system.ResourceDirectory) 
   local file,errString=io.open(mapPath,"r") 
   if not file then 
      -- Error occurred; output the cause 
      print( "File error: " .. errString ) 
   else 
      -- Read data from file 
      line = file:read( "*l" ) 
      while line~=nil do 
         lchar=string.sub(line,j,j) 
         t.map[i]={} 
         while j<=string.len(line) do 
            t.map[i][j]=lchar 
            j=j+1 
            lchar=string.sub(line,j,j) 
         end 
         j=1 
         i=i+1 
         line = file:read( "*l" ) 
      end 
      io.close( file ) 
   end 
   file = nil 
end 

function createMapBase() 
	for i=1,#t.map[1] do 
		t.base[i]={}
		for j=1,#t.map do 
			local tileImage 
			local layer 
			if t.map[j][i]=="a" then 
				tileImage="water.png" 
				layer=2 
			elseif t.map[j][i]=="*" then 

			else 
				-- if t.map[j][i]=="A" then 
					-- t.player[1]=i 
					-- t.player[2]=j 
				-- end 
				tileImage="grass.png" 
				layer=2 
			end 
			if tileImage~=nil then
				t.base[i][j]=display.newImageRect(tileImage,gridSize*1,gridSize*1) 
				t.base[i][j].x,t.base[i][j].y=i*gridSize*1,j*gridSize*1 
				t.base[i][j].layer=layer
				-- scene:insert(t.tile[i][j]) 
			else 
				t.base[i][j]=nil
			end
		end 
	end 
end 

function createMapAdditions() 
	for i=1,#t.map[1] do 
		t.actions[i]={} 
		t.tile[i]={} 
		t.addTile[i]={} 
		t.tileText[i]={}
		for j=1,#t.map do 
			local tileImage 
			local tileScore 
			local layer 
			local rotation=0 
			local baseN=0
			local xScale,yScale=1,1 
			t.actions[i][j]=nil 
			t.tile[i][j]=nil 
			t.addTile[i][j]=nil 
			t.tileText[i][j]=nil 
			
			if t.map[j][i]=="a" then 
				-- t.actions[i][j]={{"speech","You look at the water, wondering if you will return to it again. Perhaps in some time, after enjoying your life with your family again."}} 
			elseif t.map[j][i]=="c" then--rock and all the orientations 
				t.actions[i][j]={{"speech","I am a rock"}} 
				tileScore=ObjectSurroundings(j,i,"c") 
				if tileScore==255 then--middle 
				   tileImage="rockCenter.png" 
				elseif tileScore==248 or tileScore==253 or tileScore==249 or tileScore==252 then--left side 
				   tileImage="rockSide.png" 
				elseif tileScore==31  or tileScore==63  or tileScore==191 or tileScore==159 then--right side 
				   tileImage="rockSide.png" 
				   rotation=180 
				elseif tileScore==214 or tileScore==247 or tileScore==246 or tileScore==215 then--top side 
				   tileImage="rockSide.png" 
				   rotation=90 
				elseif tileScore==107 or tileScore==239 or tileScore==235 or tileScore==111 then--bottom side 
				   tileImage="rockSide.png" 
				   rotation=270 
				elseif tileScore==208 or tileScore==240 or tileScore==212 then--TL corner 
				   tileImage="rockCorner.png" 
				elseif tileScore==22 or tileScore==23 or tileScore==150 then--TR corner 
				   tileImage="rockCorner.png" 
				   rotation=90 
				elseif tileScore==11 or tileScore==15 or tileScore==43 or tileScore==171 then--BR corner 
				   tileImage="rockCorner.png" 
				   rotation=180 
				elseif tileScore==104 or tileScore==232 or tileScore==105 or tileScore==233 then--BL corner 
				   tileImage="rockCorner.png" 
				   rotation=270 
				elseif tileScore==226 or tileScore==71 or tileScore==198 or tileScore==194 or tileScore==66 or tileScore==98 or tileScore==99 or tileScore==231 or tileScore==199 or tileScore==195 or tileScore==67 then--LR middle 
				   tileImage="rockMiddle.png" 
				   rotation=90 
				elseif tileScore==156 or tileScore==57 or tileScore==61 or tileScore==185 or tileScore==184 or tileScore==29 or tileScore==189 or tileScore==157 or tileScore==188 or tileScore==24 or tileScore==28 or tileScore==25 or tileScore==152 then--UD middle 
				   tileImage="rockMiddle.png" 
				elseif tileScore==16 or tileScore==148 or tileScore==20 or tileScore==144 then--U end 
				   tileImage="rockEnd.png" 
				elseif tileScore==8 or tileScore==40 or tileScore==41 or tileScore==9 then--D end 
				   tileImage="rockEnd.png" 
				   rotation=180 
				elseif tileScore==64 or tileScore==224 or tileScore==96 or tileScore==97 or tileScore==192 or tileScore==229 then--L end 
				   tileImage="rockEnd.png" 
				   rotation=270 
				elseif tileScore==2 or tileScore==6 or tileScore==7 or tileScore==3 then--R end 
				   tileImage="rockEnd.png" 
				   rotation=90 
				elseif tileScore==90 then--center edge 
				   tileImage="rockCenterEdged.png" 
				elseif tileScore==222 then--center edge 1 
				   tileImage="rockCenterEdged1.png" 
				elseif tileScore==95 then--center edge 1 
				   tileImage="rockCenterEdged1.png" 
				   rotation=90 
				elseif tileScore==91 then--center edge 2 
				   tileImage="rockCenterEdged2.png" 
				   rotation=90 
				elseif tileScore==250 then--center edge 1 
				   tileImage="rockCenterEdged1.png" 
				   rotation=270 
				elseif tileScore==123 then--center edge 1 
				   tileImage="rockCenterEdged1.png" 
				   rotation=180 
				elseif tileScore==251 then--center edge 1 
				   tileImage="rockCenterEdgedCorner.png" 
				   rotation=180 
				   -- xScale=-1 
				elseif tileScore==187 or tileScore==59 then 
				   tileImage="rockSide2.png" 
				   rotation=180 
				elseif tileScore==125 then 
				   tileImage="rockSide2.png" 
				   rotation=180 
				   xScale=-1 
				elseif tileScore==94 then--center edge 2 
				   tileImage="rockCenterEdged2.png" 
				elseif tileScore==127 then--center edge corner 
				   tileImage="rockCenterEdgedCorner.png" 
				   rotation=90 
				elseif tileScore==10 or tileScore==42 or tileScore==46 then--UL bend 
				   tileImage="rockBend.png" 
				   rotation=180 
				elseif tileScore==72 or tileScore==73 or tileScore==201 then--UR bend 
				   tileImage="rockBend.png" 
				   rotation=270 
				elseif tileScore==72 or tileScore==80 or tileScore==112 then--DR bend 
				   tileImage="rockBend.png" 
				   -- rotation=90 
				elseif tileScore==72 or tileScore==18 or tileScore==19 then--DL bend 
				   tileImage="rockBend.png" 
				   rotation=90 
				elseif tileScore==216 or tileScore==217 then-- 
				   tileImage="rockSide2.png" 
				elseif tileScore==30 then-- 
				   tileImage="rockSide2.png" 
				   xScale=-1 
				elseif tileScore==82 or  tileScore==115 then-- 
				   tileImage="rockSide3.png" 
				   rotation=90 
				elseif tileScore==206 or  tileScore==74 then-- 
				   tileImage="rockSide3.png" 
				   rotation=270 
				elseif tileScore==210 or tileScore==242 then-- 
				   tileImage="rockSide2.png" 
				   rotation=270 
				   xScale=-1 
				elseif tileScore==75  or tileScore==79  then-- 
				   tileImage="rockSide2.png" 
				   rotation=90 
				   xScale=-1 
				elseif tileScore==254 then-- 
				   tileImage="rockCenterEdgedCorner.png" 
				   rotation=270 
				elseif tileScore==223 then-- 
				   tileImage="rockCenterEdgedCorner.png" 
				elseif tileScore==238 or tileScore==110 then-- 
				   tileImage="rockSide2.png" 
				   rotation=270 
				elseif tileScore==27 or tileScore==155 then-- 
				   tileImage="rockSide2.png" 
				   rotation=180 
				elseif tileScore==120 or tileScore==124 then-- 
				   tileImage="rockSide2.png" 
				   yScale=-1 
				elseif tileScore==186 or tileScore==26 then-- 
				   tileImage="rockSide3.png" 
				   rotation=180 
				elseif tileScore==93 or tileScore==88 then-- 
				   tileImage="rockSide3.png" 
				elseif tileScore==87 then-- 
				   tileImage="rockSide2.png" 
				   rotation=90 
				else 
				   tileImage="rock.png" 
				end 
				layer=2 
			elseif t.map[j][i]=="d" then--trees 
				t.actions[i][j]={{"speech","I am a tree"}} 
				tileImage="treeBase.png" 
				layer=2 
				t.addTile[i][j]=display.newImageRect("treeTop.png",gridSize*1,gridSize*1) 
				t.addTile[i][j].x,t.addTile[i][j].y=i*gridSize*1,(j-1)*gridSize*1 
				t.addTile[i][j].layer=1
				-- t.camera:insert(t.addTile[i][j-1]) 
			elseif t.map[j][i]=="e" then--bridges 
				t.addTile[i][j]=display.newImageRect("bridge.png",gridSize*1,gridSize*1) 
				t.addTile[i][j].x,t.addTile[i][j].y=i*gridSize*1,(j)*gridSize*1 
				if t.map[j][i-1]=="a" and t.map[j][i+1]=="a" then 
				else 
				   rotation=90 
				end 
				t.addTile[i][j].rotation=rotation 
				t.addTile[i][j].layer=2
				-- t.camera:insert(t.addTile[i][j]) 
				tileImage="water.png" 
				if t.map[j][i-1]=="a" and t.map[j][i+1]=="a" then 
				else 
				   rotation=90 
				end 
				layer=2 
				
			-------buildings-------------------
			elseif t.map[j][i]=="f" then--left side window
				tileImage="buildingLeftWindow.png"
				layer=2 
			elseif t.map[j][i]=="g" then--right side window
				tileImage="buildingRightWindow.png"
				layer=2 
			elseif t.map[j][i]=="h" then--left side door
				tileImage="buildingLeftDoor.png"
				-- t.actions[i][j]={{"enter","Entering door."}}
				layer=2 
			elseif t.map[j][i]=="i" then--right side door
				tileImage="buildingRightDoor.png"
				-- t.actions[i][j]={{"enter","Entering door."}}
				layer=2 
			elseif t.map[j][i]=="j" then--centre door door
				tileImage="buildingCentreDoor.png"
				layer=2 
			elseif t.map[j][i]=="k" then--centre door door
				tileImage="buildingCentreWindow.png"
				layer=2 
			elseif t.map[j][i]=="l" then--single building
				tileImage="buildingSingle.png"			
				-- t.actions[i][j]={{"enter","Entering door."}}
				layer=2 
			elseif t.map[j][i]=="m" then--inside floor
				tileImage="insideFloor.png"		
				layer=2 
			elseif t.map[j][i]=="n" then--inside counter
				tileImage="insideCounter.png"		
				baseN=2		
				layer=2 
			elseif t.map[j][i]=="o" then--inside counter left corner
				tileImage="insideCounterL.png"		
				baseN=2		
				layer=2 
			elseif t.map[j][i]=="p" then--inside counter right corner
				tileImage="insideCounterR.png"		
				baseN=2		
				layer=2 
			elseif t.map[j][i]=="q" then--inside counter UD left side
				tileImage="insideCounterUD.png"		
				baseN=2		
				layer=2 
			elseif t.map[j][i]=="r" then--inside counter UD right side
				tileImage="insideCounterUD.png"		
				baseN=2	
				rotation=180
				layer=2 
			elseif t.map[j][i]=="*" then--blank space for inside buildings
				tileImage=nil		
			end 
			
			if tileImage~=nil then 
				if baseN == 1 then --grass
				
				elseif baseN == 2 then --inside floor
					t.base[i][j]:removeSelf()
					t.base[i][j]=nil
					t.base[i][j]=display.newImageRect("insideFloor.png",gridSize*1,gridSize*1) 
					t.base[i][j].x,t.base[i][j].y=i*gridSize*1,j*gridSize*1 
					t.base[i][j].layer=2
				-- elseif baseN == 3 then					
				end
				t.tile[i][j]=display.newImageRect(tileImage,gridSize*1,gridSize*1) 
				t.tile[i][j].x,t.tile[i][j].y=i*gridSize*1,j*gridSize*1 
				t.tile[i][j].rotation=rotation 
				t.tile[i][j]:scale(xScale,yScale) 
				t.tile[i][j].layer=layer	
				if tileScore~=nil then 
					t.tileText[i][j]=display.newText(tileScore,i*gridSize*1,j*gridSize*1) 
					t.tileText[i][j].x,t.tileText[i][j].y=i*gridSize*1,j*gridSize*1 
				end 
			end 
			-- print(baseN)
			
		end 
	end    
end 

function ObjectSurroundings(j,i,value) 
   local multiVal = 1 
   local surrVal=0 
   for l=-1,1 do 
      for k=-1,1 do 
         if j+k~=j or i+l~=i then 
            if t.map[j+k][i+l]==value then 
               surrVal=surrVal+multiVal 
            end 
            multiVal=multiVal*2 
         end 
      end 
   end 
   return surrVal 
end 

t.createMap=function(mapFile) 
	readMap(mapFile)
	createMapBase() 
	createMapAdditions()
end 

return t