-------------------------------------------------
--
-- imageblur.lua
--
-- Creates a display object that can be blurred
--
-------------------------------------------------

local ImageBlur = {}

-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------


-------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------
function ImageBlur:new( parent, filename, width, height, steps, stepSize )

    local blur       = display.newGroup()
    parent:insert( blur )

    blur.image          = display.newImageRect( blur, filename, width, height )         -- the main image
    blur.image.alpha    = 1
    blur.images         = {}                                                            -- table where all blur images are stored in
    blur.steps          = steps or 8                                                    -- number of images used for the blur effects
    blur.stepSize       = stepSize or 1                                                 -- how far each blurredimage gets moved in pixels
    blur.isBlurHidden   = false

    if blur.steps%2 ~= 0 then                                                           -- check if blur.steps is even, if not then add 1
        blur.steps = blur.steps + 1
    end

    -- create 20 images that will be used for the blur effect
    for i=1,blur.steps do
        local newImage = display.newImageRect( blur, filename, width, height ) 
        table.insert( blur.images, newImage )
        blur.image:toFront()
    end

    -------------------------------------------------
    -- PRIVATE FUNCTIONS
    -------------------------------------------------

    -----------------------------------------------------------------------------
    -- blur:Update()
    -----------------------------------------------------------------------------
    function blur:Update()
        local startAlpha    = 0.5
        local xStepAlpha    = 0.5 / #self.images
        local globalAlpha   = 0.5

        print(xStepAlpha)

        -- for i=1,self.steps do
        --     self.images[i].alpha = 0.5 - stepAlpha * i
        --     self.images[i]:scale( 1 - stepAlpha * i, 1 - stepAlpha * i )
        -- end

        local cnt = 0
        
        for i = 1, #self.images, 2 do
            cnt = cnt + 1

            --self.images[i].xScale   = self.xScale - xStepAlpha * cnt
            --self.images[i].yScale   = self.yScale - xStepAlpha * cnt
            self.images[i].alpha    = (startAlpha - xStepAlpha * i) * globalAlpha
            self.images[i].x        = 0 + cnt*self.stepSize

            --self.images[i+1].xScale = self.xScale - xStepAlpha * cnt
            --self.images[i+1].yScale = self.yScale - xStepAlpha * cnt
            self.images[i+1].alpha  = (startAlpha - xStepAlpha * i) * globalAlpha
            self.images[i+1].x      = 0 - cnt*self.stepSize
        end
    end


    -----------------------------------------------------------------------------
    -- blur:Show()
    -----------------------------------------------------------------------------
    function blur:ShowBlur()
        for i=1,#self.images do
            self.images[i].isVisible = true
        end
        self.isBlurHidden = false
    end


    -----------------------------------------------------------------------------
    -- blur:Hide()
    -----------------------------------------------------------------------------
    function blur:HideBlur()
        for i=1,#self.images do
            self.images[i].isVisible = false
        end
        self.isBlurHidden = true
    end


    -----------------------------------------------------------------------------
    -- blur:Remove()
    -----------------------------------------------------------------------------
    function blur:Remove()
        -- delete captures
        for i=#self.images,1,-1 do
            self.images[i]:removeSelf()
            self.images[i] = nil
        end

        self:removeSelf( )
        self = nil
    end


    blur:Update()

    return blur
end

return ImageBlur