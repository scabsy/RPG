-------------------------------------------------
-- bitmapfontbutton.lua
-- Creates an button with a bitmapFont for labeling
--
-- **REQUIREMENTS:**
--
-- you have to install Paul Robson's great **fontmanager.lua module**
-- get it here:<br><a href="https://github.com/autismuk/Font-Manager">https://github.com/autismuk/Font-Manager</a><br>
--
-- Furthermore you will need some bitmap fonts: [How to create Bitmap Fonts](http://devilsquid.com/bitmap-fonts-a-step-by-step-guide/)
-- 
-- @module BitmapFontButton
-- @author René Aye
-- @license MIT
-- @copyright DevilSquid, René Aye 2016
-------------------------------------------------
if devilsquid == nil then
    devilsquid = {}
    if devilsquid.requirepath == nil then devilsquid.requirepath = "devilsquid." end
    if devilsquid.filepath == nil then devilsquid.filepath = "devilsquid/" end
end





local fm = require( devilsquid.requirepath .. "util.fontmanager" )
fm.FontManager:setEncoding("utf8")

local BitmapFontButton = {}

-------------------------------------------------
-- Constructor function of **bitmapfontbutton** module
--
-- @param options a table with all options for the **bitmapfontbutton**
--
--  - `text`:              the text string to print on the button (**string**)
--  - `font`:              the font to use (**string**)
--  - `fontSize`:          the font size (**int**)
--  - `width`:             width of the button (**int**)
--  - `height`:            height of the button (**int**)
--  - `cornerRadius`:      cornerRadius of the background (**int**)
--  - `fontColor`:         tint color of the bitmap font (**table[1]=r, table[2]=g, table[3]=b**)
--  - `fillColor`:         fill color of the background (**table[1]=r, table[2]=g, table[3]=b**)
--  - `strokeColor`:       stroke color of the background (**table[1]=r, table[2]=g, table[3]=b**)
--  - `strokeWidth`:       stroke width of the background (**table[1]=r, table[2]=g, table[3]=b**)
--  - `anchorX`:           anchorX value of background and bitmap font (**int**)<br>use anchorX=0 if you want to create a list of left aligned buttons i.e. for a menu
--  - `anchorY`:           anchorY value of background and bitmap font (**int**)
--  - `onRelease`:         function for a touch ended event (**function**)
--  - `onTap`:             function for a touch began event (**function**)
--  - `yOffset`:           changes the y position of the text (**int**)
--  - `padding`:           padding room left and right of the text, makes the button width bigger (**int**)
--  - `hitTestable`:       the isHitTestable option (see Corona docs) (**int**)

-- @usage 
--  local BMFButton = require( "util.bitmapfontbutton" )
--  local function startTap() 
--      print("TAP")
--  end
--  local button1 = BMFButton:new({text="my button", font="font01", fontSize=80, anchorX=0, strokeWidth=0, onTap=startTap})
--  sceneGroup:insert(button1)
--  button1.x = 50
--  button1.y = _H2 + 200
-------------------------------------------------
function BitmapFontButton:new( options )

    local text          = options.text or "Button"
    local font          = options.font
    local fontSize      = options.fontSize or 20
    local width         = options.width or 0
    local height        = options.height or 70
    local cornerRadius  = options.cornerRadius or 0
    local fontColor     = options.fontColor or {1,1,1,1}
    local fillColor     = options.fillColor or {1,1,1,0}
    local strokeColor   = options.strokeColor or {1,1,1,1}
    local strokeWidth   = options.strokeWidth or 1
    local anchorX       = options.anchorX or 0.5
    local anchorY       = options.anchorY or 0.5
    local onRelease     = options.onRelease or nil
    local onTap         = options.onTap or nil
    local yOffset       = options.yOffset or 0
    local padding       = options.padding or 0
    local hitTestable   = options.isHitTestable or false

    local button        = display.newGroup()
    button.options      = options

    button.bitmapfont   = display.newBitmapText(text, 0, yOffset, font, fontSize )
    button.bitmapfont:setTintColor( fontColor[1],fontColor[2],fontColor[3],fontColor[4] )
    --button.bitmapfont:setAnchor( anchorX, anchorY )

    -- get width of the text
    if width < button.bitmapfont.width then width = button.bitmapfont.width end
    width = width + padding * 2

    button.background               = display.newRoundedRect( button, 0, 0, width, height, cornerRadius )
    button.background.strokeWidth   = strokeWidth
    button.background.isHitTestable = hitTestable

    button.background:setFillColor( fillColor[1],fillColor[2],fillColor[3],fillColor[4] )
    button.background:setStrokeColor( strokeColor[1],strokeColor[2],strokeColor[3],strokeColor[4] )

    button:insert( button.background )
    button:insert( button.bitmapfont ) 

    button.onRelease    = onRelease
    button.onTap        = onTap




    -------------------------------------------------
    -- PRIVATE FUNCTIONS
    -------------------------------------------------

    ---------------------------------------------------
    -- Hides the text button
    --
    function button:Hide()
        self.background.alpha = 0
        self.bitmapfont.alpha = 0
    end  

    ---------------------------------------------------
    -- Shows the text button
    --
    function button:Show()
        self.background.alpha = 1
        self.bitmapfont.alpha = 1
    end  


    ---------------------------------------------------
    -- Sets the x anchor
    --
    function button:SetAnchorX( anchorX )
        
        self.options.anchorX = anchorX
        self.background.anchorX = anchorX

        self.bitmapfont.x = self.background.x + (self.background.width * (0.5-anchorX))

    end


    ---------------------------------------------------
    -- Sets the y anchor
    --
    function button:SetAnchorY( anchorY )
        
        self.options.anchorY = anchorY
        self.background.anchorY = anchorY

        self.bitmapfont.y = self.background.y + (self.background.height * (0.5-anchorY))
        self.bitmapfont.y = self.bitmapfont.y + self.options.yOffset
    end

    ---------------------------------------------------
    -- Sets the text of the button
    --
    function button:SetText( txt )
        self.bitmapfont:setText(txt)

        -- adjust the size of the button
        local width = self.options.width or 0
        if width < self.bitmapfont.width then width = self.bitmapfont.width end

        local padding = self.options.padding or 0
        width = width + padding * 2

        self.background.width = width

        self:SetAnchorX( self.options.anchorX )
        self:SetAnchorY( self.options.anchorY )
    end  


    button:SetAnchorX( anchorX )
    button:SetAnchorY( anchorY )


    return button
end
 
return BitmapFontButton