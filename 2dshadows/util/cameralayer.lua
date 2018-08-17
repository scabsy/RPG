-------------------------------------------------
--
-- CameraLayer.lua
--
-- Camera layer class
--
-------------------------------------------------
if devilsquid == nil then
    devilsquid = {}
    if devilsquid.requirepath == nil then devilsquid.requirepath = "devilsquid." end
    if devilsquid.filepath == nil then devilsquid.filepath = "devilsquid/" end
end






local Helper = require( devilsquid.requirepath .. "util.helper" )
local Log = require( devilsquid.requirepath .. "util.log" )


local _W          = math.floor( display.actualContentWidth + 0.5 )
local _H          = math.floor( display.actualContentHeight + 0.5 )
local _W2         = _W * 0.5
local _H2         = _H * 0.5
local _W4         = _W2 * 0.5
local _H4         = _H2 * 0.5


-----------------------------------------------------------------------------
-- CONSTRUCTOR
-----------------------------------------------------------------------------

local CameraLayer = {}

function CameraLayer:new( pIndex )
    local layer = display.newGroup()

    layer.x                     = 0                         -- x position of this layer
    layer.y                     = 0                         -- position of this layer
    layer.timers                = {}                        -- table for timers

    layer.z                     = pIndex or 0               -- the z index value of the layer
    layer.type                  = "camlayer " .. layer.z    -- a string identifier
    layer.parallaxFactor        = -1.1 + (0.1 * layer.z)             -- how fast this layer moves in relation to other layers (automatically calculated by z index)

    layer.isFixed               = false                     -- if true then this layer will not move, nifty for backgrounds or GUI
    layer.isFocused             = false                     -- on the focused layer all objects are not auto blured/scaled
    layer.isAutoBlur            = true                      -- automatically blurs objects that are not on the focused layer
    layer.isAutoFade            = true                      -- if true all objects get faded away the farther it is away = the higher th z index
    layer.isAutoScale           = true                      -- if true, all objects farther away are scaled down

    layer.autoBlurSetting       = {20,128}                  -- values for size and sigma
    layer.autoScaleSetting      = 0.2                       -- value for auto scaling
    layer.autoFadeSetting       = 0.7                       -- value for auto fading
                                                            





    function layer:ApplyAutoBlur()
        Log:p(1, "camlayer:ApplyAutoBlur() z:", self.z )

        -- APPLY AUTO BLUR SETTINGS

        if self.isAutoBlur == false then return end
        
        -- iterate each display object in this layer

        for i=1,self.numChildren do

            -- get the current display object
            local pObj = self[i]
            
            if pObj.fill ~= nil then 

                pObj.isVisible = true

                -- get blur effect fill settings
                local size = self.autoBlurSetting[1]
                local sigma = self.autoBlurSetting[2]

                -- remove effect
                if size == 0 or sigma == 0 then
                    pObj.fill.effect = nil

                -- create effect
                else
                    pObj.fill.effect = "filter.blurGaussian"
                    pObj.fill.effect.horizontal.blurSize = size
                    pObj.fill.effect.horizontal.sigma = sigma
                    pObj.fill.effect.vertical.blurSize = size
                    pObj.fill.effect.vertical.sigma = sigma
                end

            end
        end
    end



    function layer:ApplyAutoFade()
        Log:p(2, "camlayer:UpdateAutoFade()" )

        -- APPLY AUTO FADE SETTINGS

        if self.isAutoFade == false then return end

        for i=1,self.numChildren do
            self[i].alpha = self.autoFadeSetting
        end
    end


    function layer:ApplyAutoScale()
        Log:p(2, "camlayer:UpdateAutoScale()" )

        -- APPLY AUTO SCALE SETTINGS

        if self.isAutoScale == false then return end

        for i=1,self.numChildren do
            local newXScale = self[i].originalXScale * self.autoScaleSetting
            local newYScale = self[i].originalYScale * self.autoScaleSetting
            self[i].xScale = newXScale
            self[i].yScale = newYScale
        end
    end


    function layer:Insert( pObj )
        Log:p(2, "CameraLayer:Insert", pObj.type, "layer:" , self.z )

        -- check if object is not nil
        if pObj == nil then 
            print("Camera Layer Error: layer index " .. tostring( self.z ) .. " -> Object to insert is nil")
            return
        end

        pObj.originalXScale = pObj.xScale
        pObj.originalYScale = pObj.yScale

        -- insert into display group
        self:insert( pObj )
    end



    -----------------------------------------------------------------------------
    -- layer:Update( )
    -----------------------------------------------------------------------------
    function  layer:Update()
        Log:p(0, "layer:Update()")

        -- update layer position to camera
        self.x = self.cam.posX * self.parallaxFactor
        self.y = self.cam.posY * self.parallaxFactor

    end


    -----------------------------------------------------------------------------
    -- layer:UpdateDebug( )
    -----------------------------------------------------------------------------
    function  layer:UpdateDebug()
        Log:p(0, "layer:UpdateDebug()")
    end




    return layer
end



return CameraLayer