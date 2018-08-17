local M = {}
 
local newCenteredMultilineText = function(tableText, font, size, spacing, embossed)
        local group = display.newGroup()
        local currText
        spacing = spacing or size / 2
        embossed = embossed or false
        
        -- center and space out the text then put into a display group
        for i=1, #tableText do
                if embossed then
                        currText = display.newEmbossedText(tableText[i], 0, 0, font, size)
                else
                        currText = display.newText(tableText[i], 0, 0, font, size)
                end
                
                if #tableText == 1 then
                        y = 0
                elseif math.fmod(#tableText, 2) == 0 then
                        y = (-#tableText / 2 + i - 1)
                        y = spacing * y  + size / 2 * y
                else
                        y = -(#tableText / 2 + .5) + i
                        if y ~= 0 then
                                y = spacing * y + size / 2 * y - size / 4
                        else
                                y = - size / 4
                        end
                end
                
                currText.anchorX = 0.5
                currText.anchorY = 0.5
                currText.x, currText.y = 0, y
                group:insert(currText)
        end
        
        return group
end
M.newCenteredMultilineText = newCenteredMultilineText
 
local loopGroup = function (group, func)
        for i=1, group.numChildren do
                func(group[i])
        end
end
M.loopGroup = loopGroup
 
return M