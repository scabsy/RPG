-------------------------------------------------
--
-- Camera.lua
--
-- Camera class pan/zoom/rotation of layer
--
-------------------------------------------------
if devilsquid == nil then
    devilsquid = {}
    if devilsquid.requirepath == nil then devilsquid.requirepath = "devilsquid." end
    if devilsquid.filepath == nil then devilsquid.filepath = "devilsquid/" end
end






local Helper        = require( devilsquid.requirepath .. "util.helper" )
local Log           = require( devilsquid.requirepath .. "util.log" )
local CameraLayer   = require( devilsquid.requirepath .. "util.cameralayer" )


local _W          = math.floor( display.actualContentWidth + 0.5 )
local _H          = math.floor( display.actualContentHeight + 0.5 )
local _W2         = _W * 0.5
local _H2         = _H * 0.5
local _W4         = _W2 * 0.5
local _H4         = _H2 * 0.5



-----------------------------------------------------------------------------
-- MapRange( a1, a2, b1, b2, aVal )
-- map the value aVal from range a1,a2 to range b1,b2
-----------------------------------------------------------------------------
function MapRange( a1, a2, b1, b2, aVal )
    return b1 + (aVal-a1)*(b2-b1)/(a2-a1)
end

-----------------------------------------------------------------------------
-- Distance( x1,y1, x2,y2)
-- Calculate distance between two points
-----------------------------------------------------------------------------
function Distance( x1,y1, x2,y2)
   dx = (x2 - x1)
   dy = (y2 - y1)
   return math.sqrt( dx*dx + dy*dy )
end


function LERP1(v1,v2,t)
    local t = t or 1.0
    return v1 + t * (v2-v1)
end

function LERP2(v1,v2,t)
    local t = t or 1.0
    return (1-t) * v1 + t*v2
end

-----------------------------------------------------------------------------
-- CONSTRUCTOR
-----------------------------------------------------------------------------

local Camera = {}

function Camera:new( pLayers )
    local cam = display.newGroup()
    cam.anchorX = 0.5
    cam.anchorY = 0.5

    cam.posX                    = 0
    cam.posY                    = 0
    cam.type                    = "Camera"

    cam.layers                  = {}
    cam.timers                  = {}

    cam.backgroundLayer         = display.newGroup()
    cam.foregroundLayer         = display.newGroup()

    -- creating a background rect object, this can be filled with color easily 
    cam.background              = display.newRect(cam.backgroundLayer, 0, 0, _W, _H )
    cam.background.x            = _W2
    cam.background.y            = _H2
    cam.background:setFillColor( Helper:col( colTurquoise ) )

    cam.isAutoBlur              = true
    cam.isAutoFade              = true
    cam.isAutoScale             = true
    cam.isAutoFadeNear          = true
    cam.focusLayer              = 1
    cam.autoBlurSettings        = {2,40,2,256}              -- values for minSize, maxSize, minSigma, maxSigma
    cam.autoScaleSettings       = {1,0.4,0.4}               -- values for auto scaling Settings
    cam.autoFadeSettings        = {1,0.3,0.3}                -- values for auto fading Settings
                                                            -- 1st: 0-index (the layer index whith no scaling/fading) 
                                                            -- 2nd: minimum factor for layer with z index higher than 0-index
                                                            -- 3rd: minimum factor for layer with z index lower than 0-index


    cam.isTracking              = false                     -- if an object tracking is active
    cam.trackObject             = nil
    cam.trackDamping            = 20
    cam.trackObjectMoveX        = 0
    cam.trackObjectMoveY        = 0
    cam.trackAxisX              = true
    cam.trackAxisY              = true

    cam.debug                   = false
    cam.debugText               = display.newText( {parent=cam.foregroundLayer, text="Debug", x=0, y=0, width=128, font=native.systemFont, fontSize=6} )
    cam.debugText:setFillColor( 1,1,1 )
    cam.debugText.isVisible     = cam.debug
    cam.debugText.anchorX       = 0
    cam.debugText.anchorY       = 0
    cam.debugText.x             = 10
    cam.debugText.y             = 5
    cam.debugLine1              = display.newLine( cam.foregroundLayer, _W2-10, _H2, _W2+10, _H2 )
    cam.debugLine2              = display.newLine( cam.foregroundLayer, _W2, _H2-10, _W2, _H2+10 )
    cam.debugLine1.stroke       = {1,1,1, 0.4}
    cam.debugLine2.stroke       = {1,1,1, 0.4}
    cam.debugLine1.isVisible    = cam.debug
    cam.debugLine2.isVisible    = cam.debug



    -----------------------------------------------------------------------------
    -- cam:AddLayer()
    -- adds a new layer to the camera
    -- the higher the layer index the farther away is the layer from camera
    -----------------------------------------------------------------------------
    function cam:AddLayer()
        local newLayerIndex = #self.layers + 1

        Log:p(1,  "AddLayer " ..  newLayerIndex)

        -- create a new camera layer object
        local newLayer = CameraLayer:new( newLayerIndex )

        -- add cam property to layer
        newLayer.cam = self

        -- insert new layer into layers table
        table.insert( self.layers, newLayer )

        -- add new camera layer to camera object
        self:insert( newLayer )

        -- move new layer to the back
        newLayer:toBack( )

        -- move background layer to the very back
        self.backgroundLayer:toBack()

        return newLayer
    end


    -----------------------------------------------------------------------------
    -- cam:CalculateAutoDOFValues()
    -- recalculates the autoBlur, autoScale and autoFade Values for each layer
    -----------------------------------------------------------------------------
    function cam:CalculateAutoDOFValues()
        Log:p(2, "cam:CalculateAutoDOFValues")

        local cntLayer = self:CountLayer()

        -------------------------------------------------
        -- CALCULATE AUTO SCALE

        -- calculate how many layers have higher z than 0-layer
        local cntHigherDeltaZLayers = cntLayer - self.autoScaleSettings[1]

        -- calculate how many layers have smaller z than 0-layer
        local cntLowerDeltaZLayers = self.autoScaleSettings[1] - 1



        -- calculate how many steps each layer objects gets scaled when z is higher than 0 layer
        local scalePerHigherLayer = (1.0 - self.autoScaleSettings[2]) / cntHigherDeltaZLayers

        -- calculate how many steps each layer objects gets scaled when z is smaller than 0 layer
        local scalePerLowerLayer = (1.0 - self.autoScaleSettings[3]) / cntLowerDeltaZLayers



        -- iterate each layer
        for i,layer in ipairs(self.layers) do

            -- calculate how many layers away from 0-index layer
            local deltaZeroLayer = math.abs(self.autoScaleSettings[1] - layer.z)

            -- if layer.z is bigger than 0-index (farther away)
            if layer.z > self.autoScaleSettings[1] then
                layer.autoScaleSetting = 1.0 - deltaZeroLayer * scalePerHigherLayer

            -- if layer.z is smaller than 0-index (closer)
            elseif layer.z < self.autoScaleSettings[1] then
                layer.autoScaleSetting = 1.0 + deltaZeroLayer * scalePerLowerLayer

            -- if layer.z is 0-index
            elseif layer.z == self.autoScaleSettings[1] then
                layer.autoScaleSetting = 1.0
            end

            Log:p(2, "autoScale layer:", layer.z, " -> ", layer.autoScaleSetting)

            -- apply new scale values to each object of this layer
            layer:ApplyAutoScale()
        end


        -------------------------------------------------
        -- CALCULATE AUTO FADE

        -- calculate how many layers have higher z than 0-layer
        local cntHigherDeltaFadeLayers = cntLayer - self.autoFadeSettings[1]

        -- calculate how many layers have smaller z than 0-layer
        local cntLowerDeltaFadeLayers = self.autoFadeSettings[1] - 1



        -- calculate how many steps each layer objects gets scaled when z is higher than 0 layer
        local fadePerHigherLayer = (1.0 - self.autoFadeSettings[2]) / cntHigherDeltaFadeLayers

        -- calculate how many steps each layer objects gets scaled when z is smaller than 0 layer
        local fadePerLowerLayer = (1.0 - self.autoFadeSettings[3]) / cntLowerDeltaFadeLayers



        -- iterate each layer
        for i,layer in ipairs(self.layers) do

            -- calculate how may layers away from 0-index layer
            local deltaZeroLayer = math.abs(self.autoFadeSettings[1] - layer.z)

            -- if layer.z is bigger than 0-index (farther away)
            if layer.z > self.autoFadeSettings[1] then
                layer.autoFadeSetting = 1.0 - deltaZeroLayer * fadePerHigherLayer

            -- if layer.z is smaller than 0-index (closer)
            elseif layer.z < self.autoFadeSettings[1] then

                -- if isAutoFadeNear == true then make the transparency bigger the closer to the camera
                if self.isAutoFadeNear == true then 
                    layer.autoFadeSetting = 1.0 - deltaZeroLayer * fadePerLowerLayer

                -- if isAutoFadeNear == false then alpha = 1
                else
                    layer.autoFadeSetting = 1.0
                end

            -- if layer.z is 0-index
            elseif layer.z == self.autoFadeSettings[1] then
                layer.autoFadeSetting = 1.0
            end

            -- apply new fade values to each object of this layer
            layer:ApplyAutoFade()
        end


        -------------------------------------------------
        -- CALCULATE BLUR

        -- calculate how much each layer object gets blured
        local blurSizePerLayer = (self.autoBlurSettings[2] - self.autoBlurSettings[1]) / cntLayer
        local blurSigmaPerLayer = (self.autoBlurSettings[4] - self.autoBlurSettings[3]) / cntLayer

        -- iterate each layer
        for i,layer in ipairs(self.layers) do

            -- calculate how may layers away from focused layer
            local deltaZeroLayer = math.abs(self.focusLayer - layer.z)

            -- if layer is not the focused layer then blur it
            if deltaZeroLayer ~= 0 then
                layer.autoBlurSetting[1] = self.autoBlurSettings[1] + deltaZeroLayer * blurSizePerLayer
                layer.autoBlurSetting[2] = self.autoBlurSettings[3] + deltaZeroLayer * blurSigmaPerLayer

            -- if layer is the focused layer then do not blur
            elseif deltaZeroLayer == 0 then
                layer.autoBlurSetting[1] = 0
                layer.autoBlurSetting[2] = 0
            end

            -- apply new blur settings
            layer:ApplyAutoBlur()
        end

    end



   -----------------------------------------------------------------------------
   -- cam:CountLayer()
   -- return the number of layers in the camera
   -----------------------------------------------------------------------------
   function cam:CountLayer()
      Log:p(2, "cam:CountLayer")
      return #self.layers
   end


   -----------------------------------------------------------------------------
   -- cam:GetLayerWithIndex( pIndex )
   -- returns the layer with the index pIndex
   -----------------------------------------------------------------------------
   function cam:GetLayerWithIndex( pIndex )
      Log:p(2, "cam:GetLayerWithIndex ", pIndex)
      return self.layers[pIndex]
   end


    -----------------------------------------------------------------------------
    -- cam:Insert( pObj, pLayerIndex )
    -- Inserts an display object pObj into the layer with the index pLayerIndex
    -- pLayerIndex is an integer for the corresponding layer number
    -- 0 = background layer
    -- 1 = foreground layer
    -----------------------------------------------------------------------------
    function cam:Insert( pObj, pLayerIndex )
        Log:p(2, "cam:Insert", pObj.type, pLayerIndex )

        -- check if layer index does exist
        if pLayerIndex > #self.layers then 
            print("Camera Error: layer index " .. tostring( pLayerIndex ) .. " does not exist")
            return
        end

        -- if layer index == 0 then insert object into special background layer
        if pLayerIndex == 0 then 
            self.backgroundLayer:insert( pObj )

       -- if layer index == -1 then insert object into special foreground layer
        elseif pLayerIndex == -1 then 
            self.foregroundLayer:insert( pObj )

        else
            -- insert object to layer
            local layer = self:GetLayerWithIndex( pLayerIndex )
            layer:Insert( pObj )
        end

        -- add a cam and layer property to object
        pObj.cam = self
        pObj.layer = layer

   end


    -----------------------------------------------------------------------------
    -- cam:Move(x, y)
    -- moves the Camera with all its layers by pX and pY
    -----------------------------------------------------------------------------
    function cam:Move(pX, pY)
        self.posX = self.posX + pX
        self.posY = self.posY + pY
    end

    -----------------------------------------------------------------------------
    -- cam:Move(x, y)
    -- moves the Camera with all its layers by pX and pY
    -----------------------------------------------------------------------------
    function cam:MoveTo(pX, pY)
        self.posX = pX
        self.posY = pY
    end


    -----------------------------------------------------------------------------
    -- cam:MoveTrackedObject(px,py)
    -- moves the tracked object by px and px
    -----------------------------------------------------------------------------
    function cam:MoveTrackedObject(px,py)
        self.trackObjectMoveX = px
        self.trackObjectMoveY = py
    end



   -----------------------------------------------------------------------------
   -- cam:Remove()
   -----------------------------------------------------------------------------
   function cam:Remove()
      Log:p(1, "cam:Remove()")
      Runtime:removeEventListener( "enterFrame", cam )
      self:removeSelf( )
      self = nil
   end


   -----------------------------------------------------------------------------
   -- cam:Rotation( pRot )
   -- rotates the layer to pRot degrees
   -----------------------------------------------------------------------------
   function cam:Rotation( pRot )
      for i,layer in ipairs(self.layers) do
         layer.rotation = pRot
      end
   end



    -----------------------------------------------------------------------------
    -- cam:Rotate( pRot )
    -- rotates the layer by pRot degrees
    -----------------------------------------------------------------------------
    function cam:Rotate( pRot )
        for i,layer in ipairs(self.layers) do
            layer.rotation = layer.rotation + pRot
        end
    end


   -----------------------------------------------------------------------------
   -- cam:SetAutoBlurSettings( pLayerIndex, pNewFactor )
   -- minSize, maxSize, minSigma, maxSigma
   -----------------------------------------------------------------------------
   function cam:SetAutoBlurSettings( p1,p2,p3,p4 )
      Log:p(1, "cam:SetAutoBlurSettings()", p1,p2,p3,p4)
      
      local oldP1 = self.autoBlurSettings[1]
      local oldP2 = self.autoBlurSettings[2]
      local oldP3 = self.autoBlurSettings[3]
      local oldP4 = self.autoBlurSettings[4]

      local newP1 = p1 or oldP1
      local newP2 = p2 or oldP2
      local newP3 = p3 or oldP3
      local newP4 = p4 or oldP4

      self.autoBlurSettings[1] = newP1
      self.autoBlurSettings[2] = newP2
      self.autoBlurSettings[3] = newP3
      self.autoBlurSettings[4] = newP4

      self:CalculateAutoDOFValues()
   end


    -----------------------------------------------------------------------------
    -- cam:SetAutoFadeSettings( pLayerIndex, pNewFactor )
    -- 0-index Layer, fade strength for farther away layers, fade strength for closer layers
    -----------------------------------------------------------------------------
    function cam:SetAutoFadeSettings( p1,p2,p3 )
        Log:p(1, "cam:SetAutoBlurSettings()", p1,p2,p3)

        local oldP1 = self.autoFadeSettings[1]
        local oldP2 = self.autoFadeSettings[2]
        local oldP3 = self.autoFadeSettings[3]

        local newP1 = p1 or oldP1
        local newP2 = p2 or oldP2
        local newP3 = p3 or oldP3

        self.autoFadeSettings[1] = newP1
        self.autoFadeSettings[2] = newP2
        self.autoFadeSettings[3] = newP3

        self:CalculateAutoDOFValues()
    end


    -----------------------------------------------------------------------------
    -- cam:SetAutoFadeZeroLayer( pLayerIndex )
    -----------------------------------------------------------------------------
    function cam:SetAutoFadeZeroLayer( pLayerIndex )
        self.autoFadeSettings[1] = pLayerIndex or 1
        self:CalculateAutoDOFValues()
    end


    -----------------------------------------------------------------------------
    -- cam:SetAutoScaleSettings( p1,p2,p3 )
    -- 0-index Layer, scale strength for farther away layers, fade strength for closer layers
    -----------------------------------------------------------------------------
    function cam:SetAutoScaleSettings( p1,p2,p3 )
        Log:p(1, "cam:SetAutoScaleSettings()", p1,p2,p3)

        local oldP1 = self.autoScaleSettings[1]
        local oldP2 = self.autoScaleSettings[2]
        local oldP3 = self.autoScaleSettings[3]

        local newP1 = p1 or oldP1
        local newP2 = p2 or oldP2
        local newP3 = p3 or oldP3

        self.autoScaleSettings[1] = newP1
        self.autoScaleSettings[2] = newP2
        self.autoScaleSettings[3] = newP3

        self:CalculateAutoDOFValues()
    end


    -----------------------------------------------------------------------------
    -- cam:SetAutoScaleZeroLayer( pLayerIndex )
    -----------------------------------------------------------------------------
    function cam:SetAutoScaleZeroLayer( pLayerIndex )
        self.autoScaleSettings[1] = pLayerIndex or 1
        self:CalculateAutoDOFValues()
    end


    -----------------------------------------------------------------------------
    -- cam:SetDebugOff( )
    -----------------------------------------------------------------------------
    function cam:SetDebugOff()
        Log:p(1, "cam:SetDebugOff()")

        self.debug = false

        self.debugText.isVisible     = self.debug
        self.debugLine1.isVisible    = self.debug
        self.debugLine2.isVisible    = self.debug
    end


    -----------------------------------------------------------------------------
    -- cam:SetDebugOn( )
    -----------------------------------------------------------------------------
    function cam:SetDebugOn()
        Log:p(1, "cam:SetDebugOn()")

        self.debug = true

        self.debugText.isVisible     = self.debug
        self.debugLine1.isVisible    = self.debug
        self.debugLine2.isVisible    = self.debug
    end


    -----------------------------------------------------------------------------
    -- cam:SetParallaxFactor( pLayerIndex, pNewFactor )
    -- sets the parallax factor of a layer
    -----------------------------------------------------------------------------
    function cam:SetFocusLayer( pLayerIndex )
        Log:p(1, "cam:SetFocusLayer()", pLayerIndex)
        self.focusLayer = pLayerIndex
        self:CalculateAutoDOFValues()
    end

    -----------------------------------------------------------------------------
    -- cam:SetLayerAutoBlurOff( pLayerIndex )
    -- sets the automatic blur effect for layer with pLayerIndex off
    -- pLayerIndex is the layer number
    -- if pLayerIndex is nil then iterate all layers
    -----------------------------------------------------------------------------
    function cam:SetLayerAutoBlurOff( pLayerIndex )
        if pLayerIndex == nil then
            local cntLayer = self:CountLayer()

            for i=1,cntLayer do
                print(i)
                self.layers[i].isAutoBlur = false
            end
        else
            self.layers[pLayerIndex].isAutoBlur = false
        end
    end

    -----------------------------------------------------------------------------
    -- cam:SetLayerAutoBlurOn( pLayerIndex )
    -- sets the automatic blur effect for layer with pLayerIndex on
    -- pLayerIndex is the layer number
    -- if pLayerIndex is nil then iterate all layers
    -----------------------------------------------------------------------------
    function cam:SetLayerAutoBlurOn( pLayerIndex )
        if pLayerIndex == nil then
            local cntLayer = self:CountLayer()

            for i=1,cntLayer do
                print(i)
                self.layers[i].isAutoBlur = true
            end
        else
            self.layers[pLayerIndex].isAutoBlur = true
        end
    end


    -----------------------------------------------------------------------------
    -- cam:SetLayerAutoFadeOff( pLayerIndex )
    -- sets the automatic fading for layer with pLayerIndex off
    -- pLayerIndex is the layer number
    -- if pLayerIndex is nil then iterate all layers
    -----------------------------------------------------------------------------
    function cam:SetLayerAutoFadeOff( pLayerIndex )
        if pLayerIndex == nil then
            local cntLayer = self:CountLayer()

            for i=1,cntLayer do
                print(i)
                self.layers[i].isAutoFade = false
            end
        else
            self.layers[pLayerIndex].isAutoFade = false
        end
    end

    -----------------------------------------------------------------------------
    -- cam:SetLayerAutoFadeOn( pLayerIndex )
    -- sets the automatic fading for layer with pLayerIndex on
    -- pLayerIndex is the layer number
    -- if pLayerIndex is nil then iterate all layers
    -----------------------------------------------------------------------------
    function cam:SetLayerAutoFadeOn( pLayerIndex )
        if pLayerIndex == nil then
            local cntLayer = self:CountLayer()

            for i=1,cntLayer do
                print(i)
                self.layers[i].isAutoFade = true
            end
        else
            self.layers[pLayerIndex].isAutoFade = true
        end
    end


    -----------------------------------------------------------------------------
    -- cam:SetLayerAutoScaleOff( pLayerIndex )
    -- sets the automatic scaling for layer with pLayerIndex off
    -- pLayerIndex is the layer number
    -- if pLayerIndex is nil then iterate all layers
    -----------------------------------------------------------------------------
    function cam:SetLayerAutoScaleOff( pLayerIndex )
        if pLayerIndex == nil then
            local cntLayer = self:CountLayer()

            for i=1,cntLayer do
                print(i)
                self.layers[i].isAutoScale = false
            end
        else
            self.layers[pLayerIndex].isAutoScale = false
        end
    end


    -----------------------------------------------------------------------------
    -- cam:SetLayerAutoScaleOn( pLayerIndex )
    -- sets the automatic scaling for layer with pLayerIndex on
    -- pLayerIndex is the layer number
    -- if pLayerIndex is nil then iterate all layers
    -----------------------------------------------------------------------------
    function cam:SetLayerAutoScaleOn( pLayerIndex )
        if pLayerIndex == nil then
            local cntLayer = self:CountLayer()

            for i=1,cntLayer do
                print(i)
                self.layers[i].isAutoScale = true
            end
        else
            self.layers[pLayerIndex].isAutoScale = true
        end
    end


    -----------------------------------------------------------------------------
    -- cam:SetLayerBlurFactor( pLayerIndex, pBlur )
    -- sets the parallax factor of a layer
    -----------------------------------------------------------------------------
    function cam:SetLayerBlurFactor( pLayerIndex, pBlur, pSigma )
        Log:p(1, "cam:SetLayerBlurFactor()", pLayerIndex, pBlur, pSigma)

        if pLayerIndex == nil then
            print("cam:SetLayerBlurFactor() – mising parameter 1 – no layer index assigned")
            return
        end

        local pBlur = pBlur or self.layers[pLayerIndex].autoBlurSetting[1]
        local pSigma = pSigma or self.layers[pLayerIndex].autoBlurSetting[2]

        self.layers[pLayerIndex].autoBlurSetting[1] = pBlur
        self.layers[pLayerIndex].autoBlurSetting[2] = pSigma

        self.layers[pLayerIndex]:ApplyAutoBlur()
    end


    -----------------------------------------------------------------------------
    -- cam:SetLayerScaleFactor( pLayerIndex, pScale )
    -- sets the scale factor of a layer
    -----------------------------------------------------------------------------
    function cam:SetLayerScaleFactor( pLayerIndex, pScale )
        Log:p(1, "cam:SetLayerScaleFactor()", pLayerIndex, pScale )

        if pLayerIndex == nil then
            print("cam:SetLayerScaleFactor() – mising parameter 1 – no layer index assigned")
            return
        end

        local pScale = pScale or self.layers[pLayerIndex].autoScaleSetting

        self.layers[pLayerIndex].autoScaleSetting = pScale

        self.layers[pLayerIndex]:ApplyAutoScale()
    end


    -----------------------------------------------------------------------------
    -- cam:SetLayerFadeFactor( pLayerIndex, pFade )
    -- sets the fade factor of a layer manually
    -----------------------------------------------------------------------------
    function cam:SetLayerFadeFactor( pLayerIndex, pFade )
        Log:p(1, "cam:SetLayerFadeFactor()", pLayerIndex, pFade )

        if pLayerIndex == nil then
            print("cam:SetLayerFadeFactor() – mising parameter 1 – no layer index assigned")
            return
        end

        local pFade = pFade or self.layers[pLayerIndex].autoFadeSetting

        self.layers[pLayerIndex].autoFadeSetting = pFade

        self.layers[pLayerIndex]:ApplyAutoFade()
    end


    -----------------------------------------------------------------------------
    -- cam:SetLayerParallaxFactor( pLayerIndex, pNewFactor )
    -- sets the parallax factor of a layer
    -----------------------------------------------------------------------------
    function cam:SetLayerParallaxFactor( pLayerIndex, pNewFactor )
        Log:p(1, "cam:SetLayerParallaxFactor()", pLayerIndex, pNewFactor)
        self.layers[pLayerIndex].parallaxFactor = pNewFactor
    end




    -----------------------------------------------------------------------------
    -- cam:LockTrackingAxis( lx, ly )
    -- locks the x and/or y axis for tracking
    -- if an axis is locked then it ignores the movement in that direction for the tracked object
    -- set lx to true to lock x axis movement
    -- set ly to true to lock y axis movement
    -----------------------------------------------------------------------------
    function cam:LockTrackingAxis( lx, ly )
        if lx == true then self.trackAxisX = false else self.trackAxisX = true end
        if ly == true then self.trackAxisY = false else self.trackAxisY = true end
    end


    -----------------------------------------------------------------------------
    -- cam:SetTracking( pObj, pDamping )
    -- tracks the display object pObj
    -- pDamping damps the tracking, try values between 2 and 20
    -- pDamping of 1 = snap to object
    -----------------------------------------------------------------------------
    function cam:SetTracking( pObj, pDamping )
        Log:p(1, "cam:SetTracking()", pObj.type, pDamping)

        if pObj == nil then 
            print("Camera Track Error: object to track is nil")
            return 
        end

        self.trackObject  = pObj
        self.trackDamping = pDamping or 0
        self.isTracking     = true
    end


    -----------------------------------------------------------------------------
    -- cam:SwitchDebug( )
    -- switches the debug state
    -----------------------------------------------------------------------------
    function cam:SwitchDebug()
        Log:p(1, "cam:SwitchDebug()")

        if self.debug == false then
            self:SetDebugOn()
        else
            self:SetDebugOff()
        end
    end


    -----------------------------------------------------------------------------
    -- cam:UpdateTracking()
    -----------------------------------------------------------------------------
    function cam:UpdateTracking()
        if self.trackObject == nil then 
            print("Camera Track Error: object to track is nil")
            return 
        end

        -- update tracked object movement
        self.trackObject.x = self.trackObject.x + self.trackObjectMoveX
        self.trackObject.y = self.trackObject.y + self.trackObjectMoveY

        -- reset tracked object movement
        self.trackObjectMoveX = 0
        self.trackObjectMoveY = 0

        -- calculate distance from center
        local objX, objY = self.trackObject:localToContent( 0,0 )
        local diffX = _W2 - objX
        local diffY = _H2 - objY
        local distance = math.sqrt( diffX*diffX + diffY*diffY )

        --print(_W2, _H2, objX, objY, diffX, diffY)

        if self.trackDamping > 0 then
            -- calculate damping
            local damping = math.abs( MapRange( 0, display.contentWidth/2 , 0, 1, distance ) )
            damping = damping / self.trackDamping or 1
            --print(damping)

            -- apply damping
            diffX = diffX * damping
            diffY = diffY * damping
        end

        self:Move( -diffX, -diffY )

    end


    -----------------------------------------------------------------------------
    -- cam:UpdateTracking2()
    -----------------------------------------------------------------------------
    function cam:UpdateTracking2()
        if self.trackObject == nil then 
            print("Camera Track Error: object to track is nil")
            return 
        end

        -- update tracked object movement
        self.trackObject.x = self.trackObject.x + self.trackObjectMoveX
        self.trackObject.y = self.trackObject.y + self.trackObjectMoveY

        -- reset tracked object movement
        self.trackObjectMoveX = 0
        self.trackObjectMoveY = 0

        -- calculate distance from center
        local objX, objY = self.trackObject:localToContent( 0,0 )
        local diffX = _W2 - objX
        local diffY = _H2 - objY
        local distance = math.sqrt( diffX*diffX + diffY*diffY )

        --print(_W2, _H2, objX, objY, diffX, diffY)

        if self.trackDamping > 0 then
            -- calculate damping
            local damping = LERP1( 0, distance, self.trackDamping )
            --damping = damping / self.trackDamping or 1
            --print(damping)

            -- apply damping
            diffX = diffX * damping
            diffY = diffY * damping
        end

        -- check locked axis
        if self.trackAxisX == false then diffX = 0 end
        if self.trackAxisY == false then diffY = 0 end
            
        -- move the camera
        self:Move( -diffX, -diffY ) 
    end


    -----------------------------------------------------------------------------
    -- cam:Update()
    -----------------------------------------------------------------------------
    function cam:Update()
        if self.isTracking == true then self:UpdateTracking2() end

        -- update layer positions to camera
        for i=1,#self.layers do
            self.layers[i]:Update()
        end
        
    end



   -----------------------------------------------------------------------------
   -- cam:UpdateDebug( )
   -----------------------------------------------------------------------------
   function  cam:UpdateDebug()
      Log:p(0, "cam:UpdateDebug()")

      local txt = ""
      txt = txt .. "cam xy: " .. string.format(" %i | %i ", self.x, self.y) .. "\n"
      txt = txt .. "cam pos: " .. string.format(" %i | %i ", self.posX, self.posY) .. "\n"
      txt = txt .. "layers: " .. self:CountLayer() .. "\n"
      txt = txt .. "isAutoBlur: " .. tostring(self.isAutoBlur) .. "\n"
      txt = txt .. "isAutoFade: " .. tostring(self.isAutoFade) .. "\n"
      txt = txt .. "focusLayer: " .. self.focusLayer .. "\n"
      txt = txt .. "isTracking: " .. tostring(self.isTracking) .. "\n"
      txt = txt .. "trackDamping: " .. self.trackDamping .. "\n\n"

      for i=1, self:CountLayer() do
         txt = txt .. "layer(" .. i .. "): children: " .. self.layers[i].numChildren .. "\n"
         txt = txt .. "parallax: " .. self.layers[i].parallaxFactor .. "\n"
         txt = txt .. string.format("pos: %i | %i ", self.layers[i].x, self.layers[i].y) .. "\n"
         txt = txt .. "autoBlur: " .. string.format("pos: %i | %i ", self.layers[i].autoBlurSetting[1], self.layers[i].autoBlurSetting[2]) .. "\n"
         txt = txt .. "autoScale: " .. self.layers[i].autoScaleSetting .. "\n"
         txt = txt .. "autoFade: " .. self.layers[i].autoFadeSetting .. "\n"
         txt = txt .. "--------------------\n"
      end

      self.debugText.text = txt
      self.debugText:toFront( )

   end



    -----------------------------------------------------------------------------
    -- cam:timer( event )
    -----------------------------------------------------------------------------
    function cam:timer( event )
        self:Update()
        if self.debug then self:UpdateDebug() end
    end

    local tm = timer.performWithDelay( 1, cam, 0 )
    table.insert( cam.timers, tm )



   --###########################################################################
   -----------------------------------------------------------------------------
   -- create the initial layers when Camera objects gets created
   -- if no value in the constructor is given, default is 3 layers
 
   for i=1,pLayers or 3 do
      cam:AddLayer()
   end
   cam:CalculateAutoDOFValues()

    if pLayers >= 12 then
        print("\n\n***\nWARNING: You created more than 11 layers.\nMake sure to set the parallac factor manually for each layer by using the SetParallaxFactor() method.\n***\n\n")
    end

   return cam
end



return Camera