-------------------------------------------------
--
-- quadtree.lua
--
-- Quadtree module
--
-------------------------------------------------
if devilsquid == nil then
    devilsquid = {}
    if devilsquid.requirepath == nil then devilsquid.requirepath = "devilsquid." end
    if devilsquid.filepath == nil then devilsquid.filepath = "devilsquid/" end
end




local Quadtree = {}

local Log       = require( devilsquid.requirepath .. "util.log" )
local Helper    = require( devilsquid.requirepath .. "util.helper" )




-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------

-------------------------------------------------
-- CONSTRUCTOR
-- Quadtree:new( pLevel, pRect, pDebug )
-- pLevel   - MUST BE 1
-- pRect    - your devices screen size
-- pDebug   - if you want to see the subnode dance
-------------------------------------------------
function Quadtree:new( pLevel, pRect, pDebug, pMaxObjects, pMaxLevels )
    --Log:p(1, "Quadtree:new()", pLevel, pRect[1], pRect[2], pRect[3], pRect[4] )

    local quadtree                  = display.newGroup()                -- the displayGroup of this Quadtree
    quadtree.type                   = "quadtree"                        -- a string identifier (comes sometimes handy)

    quadtree.maxObjects             = pMaxObjects or 3                  -- how many objects a node can hold before it splits
    quadtree.maxLevels              = pMaxLevels or 6                   -- maximum number of subnode levels

    quadtree.level                  = pLevel                            -- current node level (1 = topmost node)
    quadtree.objects                = {}                                -- tbale for the objects that need to be checked for collision
    quadtree.nodes                  = {}                                -- table for the subnodes
    quadtree.bounds                 = {x=pRect[1], y=pRect[2], width=pRect[3], height=pRect[4]}    -- size of the screen

    quadtree.debug                  = pDebug or false
    if quadtree.debug == true then
        quadtree.image                  = display.newRect( quadtree.bounds.x ,quadtree.bounds.y, quadtree.bounds.width, quadtree.bounds.height )
        quadtree.image.anchorX          = 0
        quadtree.image.anchorY          = 0
        quadtree.image.strokeWidth      = 1
        if quadtree.level == 1 then quadtree.image.strokeWidth = 2 end
        quadtree.image:setStrokeColor( 1,0,0 )
        quadtree.image:setFillColor( 1,0,0,0 )
    end

    quadtree.nodeCounter            = 1

    -------------------------------------------------
    -- PRIVATE FUNCTIONS
    -------------------------------------------------

    function quadtree:CountNodes( )
        quadtree.nodeCounter = 1

        for i=1,#self.nodes do
            quadtree.nodeCounter = quadtree.nodeCounter + self.nodes[i]:CountNodes()
        end

        return quadtree.nodeCounter
    end

    -----------------------------------------------------------------------------
    -- quadtree:Clear()
    -----------------------------------------------------------------------------
    function quadtree:Clear( )

        -- clear objects
        for i=1,#self.objects do
            self.objects[i] = nil
        end

        -- clear bounds
        for i=1,#self.bounds do
            self.bounds[i] = nil
        end

        -- clear objects of each subnode
        for i=1,#self.nodes do
            self.nodes[i]:Clear()
            if self.debug == true then
                self.nodes[i].image:removeSelf( )
                self.nodes[i].image = nil
            end
            self.nodes[i]:removeSelf()
            self.nodes[i] = nil
        end

    end


    -----------------------------------------------------------------------------
    -- quadtree:Split()
    -- splits the node into 4 subnodes
    -----------------------------------------------------------------------------
    function quadtree:Split( )
        --print("quadtree:Split()")

        local subWidth  = self.bounds.width * 0.5
        local subHeight = self.bounds.height * 0.5
        local x         = self.bounds.x
        local y         = self.bounds.y
     
        -- order of the subnodes
        -- ---------
        -- | 2 | 1 |
        -- ---------
        -- | 3 | 4 |
        -- ---------

        self.nodes[1] = Quadtree:new(self.level+1, {x + subWidth, y, subWidth, subHeight}, self.debug, self.maxObjects, self.maxLevels)
        self.nodes[2] = Quadtree:new(self.level+1, {x, y, subWidth, subHeight}, self.debug, self.maxObjects, self.maxLevels)
        self.nodes[3] = Quadtree:new(self.level+1, {x, y + subHeight, subWidth, subHeight}, self.debug, self.maxObjects, self.maxLevels)
        self.nodes[4] = Quadtree:new(self.level+1, {x + subWidth, y + subHeight, subWidth, subHeight}, self.debug, self.maxObjects, self.maxLevels)
    end


    -----------------------------------------------------------------------------
    -- quadtree:GetIndex()
    -- Determine which node the object belongs to. -1 means
    -- object cannot completely fit within a child node and is part
    -- of the parent node
    -----------------------------------------------------------------------------
    function quadtree:GetIndex( pObject )
        --print("quadtree:GetIndex()", pObject, pObject.contentBounds.xMin, pObject.contentBounds.yMin, pObject.contentBounds.xMax, pObject.contentBounds.yMax)

        local index = -1
        local verticalMidpoint = self.bounds.x + (self.bounds.width * 0.5)
        local horizontalMidpoint = self.bounds.y + (self.bounds.height * 0.5)


        local objectX = pObject.contentBounds.xMin
        local objectY = pObject.contentBounds.yMin
        local objectWidth = pObject.contentBounds.xMax - objectX
        local objectHeight = pObject.contentBounds.yMax - objectY

        -- Object can completely fit within the top quadrants
        local topQuadrant = (objectY < horizontalMidpoint and objectY + objectWidth < horizontalMidpoint)
        
        -- Object can completely fit within the bottom quadrants
        local bottomQuadrant = (objectY > horizontalMidpoint)

        -- Object can completely fit within the left quadrants
        if (objectX < verticalMidpoint and objectX + objectWidth < verticalMidpoint) then

            if topQuadrant then
                index = 2
            elseif bottomQuadrant then
                index = 3
            end
        
        -- Object can completely fit within the right quadrants
        elseif objectX > verticalMidpoint then
            if topQuadrant then
                index = 1
            elseif bottomQuadrant then
                index = 4
            end    
        end
     
        print("quadtree object", index, pObject.x, pObject.y, objectX, objectY, objectWidth, objectHeight)

       return index
    end

     
    -----------------------------------------------------------------------------
    -- quadtree:Insert( pObject )
    -- Inserts a display object into quadtree
    -----------------------------------------------------------------------------
    function quadtree:Insert( pObject )
        --print("quadtree:Insert()")

        if self.nodes[1] ~= nil then
            local index = self:GetIndex( pObject )
         
            if index ~= -1 then
                self.nodes[index]:Insert( pObject )
                return
            end
        end

        -- insert pObject to self.objects table
        self.objects[#self.objects+1] = pObject
     
        -- if too many objects in this node then split node
        if ( #self.objects > self.maxObjects and self.level < self.maxLevels ) then

            -- create subnodes
            if self.nodes[1] == nil then 
                self:Split() 
            end
     
            local i = 1
            while i < #self.objects do
                local index = self:GetIndex( self.objects[i] )
                if index ~= -1 then
                    self.nodes[index]:Insert( table.remove(self.objects, i) )
                else
                    i = i + 1
                end
            end
        end
    end

    -----------------------------------------------------------------------------
    -- quadtree:Retrieve()
    -- Return all objects that could collide with the given object
    -----------------------------------------------------------------------------
    function quadtree:Retrieve( returnObjects, pObject )
        --print("quadtree:Retrieve()")

        local index = self:GetIndex( pObject )
        if (index ~= -1 and self.nodes[1] ~= nil) then
            self.nodes[index]:Retrieve( returnObjects, pObject )
        end
     
        -- insert all self.objects to returnObjects table
        for i=1,#self.objects do
            returnObjects[#returnObjects+1] = self.objects[i]
        end
     
        return returnObjects
    end







    return quadtree
end

return Quadtree