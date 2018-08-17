-------------------------------------------------
--
-- object.lua
--
-- The base class for nearly all objects 
--
-------------------------------------------------
if devilsquid == nil then
    devilsquid = {}
    if devilsquid.requirepath == nil then devilsquid.requirepath = "devilsquid." end
    if devilsquid.filepath == nil then devilsquid.filepath = "devilsquid/" end
end




local Object = {}

local log       = require( devilsquid.requirepath .. "util.log" )
local helper    = require( devilsquid.requirepath .. "util.helper" ) 


function Object:new(px,py, color)

    local object = display.newGroup()

    object.x                        = px or 0
    object.y                        = py or 0
    object.type                     = "object"

    object.markX                    = 0                 -- needed for the dragging
    object.markY                    = 0                 -- needed for the dragging
    object.isDraggable              = true              -- if the object is draggable
    object.isRotateable             = false             -- if the object should rotate on touch
    object.isStopTouchPropagation   = true              -- if touch propagation shouldbe stopped or not
    object.hasMoved                 = false             -- needed to check if object has been dragged or only tapped
    object.isTouched                = false             -- if the object is currently being touched

    object.timers                   = {}                -- table of all timers
    object.transitions              = {}                -- table of all transitions

    object.isGarbage                = false             -- if set to true the object can be removed from any tables
                                                        -- the main controller (and only the main controller) class should check it
                                                        -- and delete the object if this is set to true

    object.debug                    = false             -- display debugging text
    object.debugText                = display.newText( {parent=object, text="Debug", x=0, y=0, width=128, font=native.systemFont, fontSize=10} )
    object.debugText.isVisible      = false
    object.debugText:setFillColor( 0,0,0 )



   -----------------------------------------------------------------------------
   -- object:HasBegun( event )
   -- gets called when the object has began to receive a touch event
   -----------------------------------------------------------------------------
    function object:HasBegun( event )
        log:p(2,"object has began being touched")
        
        local eventX = event.x
        local eventY = event.y

        local newEvent = {
            name = "began",
            x = eventX,
            y = eventY,
        }
        self:dispatchEvent( newEvent )
    end

   
   -----------------------------------------------------------------------------
   -- object:HasMoved( event )
   -- gets called when the object has been moved (not tapped)
   -----------------------------------------------------------------------------
    function object:HasMoved( event )
        log:p(2,"object has been moved")
        
        local eventX = event.x
        local eventY = event.y
        local eventXStart = event.xStart
        local eventYStart = event.yStart

        local newEvent = {
            name = "moved",
            x = eventX,
            y = eventY,
            xStart = eventXStart,
            yStart = eventYStart
        }
        self:dispatchEvent( newEvent )

        object.debugText.text = self.x .. "/" .. self.y
    end


   -----------------------------------------------------------------------------
   -- object:HasDoubleTapped( event )
   -- gets called if the object has been double tapped
   -----------------------------------------------------------------------------
    function object:HasDoubleTapped( event )
        log:p(2,"object has been double tapped")
        
        local eventX = event.x
        local eventY = event.y
        local eventXStart = event.xStart
        local eventYStart = event.yStart

        local newEvent = {
            name = "doubletapped",
            x = eventX,
            y = eventY,
            xStart = eventXStart,
            yStart = eventYStart
        }
        self:dispatchEvent( newEvent )
    end


   -----------------------------------------------------------------------------
   -- object:HasTapped( event )
   -- gets called if the object has been tapped
   -----------------------------------------------------------------------------
    function object:HasTapped( event )
        log:p(2,"object has been tapped")
        
        local eventX = event.x
        local eventY = event.y
        local eventXStart = event.xStart
        local eventYStart = event.yStart

        local newEvent = {
            name = "tapped",
            x = eventX,
            y = eventY,
            xStart = eventXStart,
            yStart = eventYStart
        }
        self:dispatchEvent( newEvent )
    end


   -----------------------------------------------------------------------------
   -- object:HasEnded( event )
   -- gets called if the object touch has been ended
   -----------------------------------------------------------------------------
    function object:HasEnded( event )
        log:p(2,"object touch has been ended")
        
        local eventX = event.x
        local eventY = event.y
        local eventXStart = event.xStart
        local eventYStart = event.yStart

        local newEvent = {
            name = "ended",
            x = eventX,
            y = eventY,
            xStart = eventXStart,
            yStart = eventYStart
        }
        self:dispatchEvent( newEvent )
    end



    -------------------------------------------------
    -- PRIVATE FUNCTIONS
    -------------------------------------------------


    -- ##########################################################################
    -- tap event objectr of the object
    -- ##########################################################################
    function object:tap( event )    
        if ( event.numTaps == 2 ) then
            self:HasDoubleTapped( event )
        else
            return true
        end
    end

    -- ##########################################################################
    -- touch event objectr of the object
    -- ##########################################################################
    function object:touch( event )      

        if event.phase == "began" then
            -- begin focus
            display.getCurrentStage():setFocus( self, event.id )

            self.isFocus   = true
            self.isTouched = true

            self.markX = self.x
            self.markY = self.y

            self:HasBegun( event )

        elseif self.isFocus then

            if event.phase == "moved" then
                self.hasMoved = true

                -- drag touch object
                if self.isDraggable == true then
                   self.x = event.x - event.xStart + self.markX
                   self.y = event.y - event.yStart + self.markY
                end

                self:HasMoved( event )

            elseif event.phase == "ended" or event.phase == "cancelled" then
            
                -- check if has moved or only tapped
                if self.hasMoved == false then
                    if self.isRotateable == true then
                        transition.to( self, {  rotation = self.rotation+45, 
                                                time = 250, 
                                                transition = easing.outExpo, 
                                                onComplete = function() 
                                                    self.rotation = self.rotation - (self.rotation % 45)
                                                    print(self.rotation) 
                                                end 
                                            })
                    end

                    self:HasTapped( event )
                end

                -- end focus
                display.getCurrentStage():setFocus( self, nil )
                self.isFocus   = false
                self.hasMoved  = false
                self.isTouched = false

                self:HasEnded( event )
            end
        end

        -- return true if propagation should be stopped
        return self.isStopTouchPropagation
    end

    -- create an event listener for touching
    object:addEventListener("touch", object)
    object:addEventListener("tap", object)

   return object
end

return Object