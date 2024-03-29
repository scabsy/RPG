local Helper = {}



 -----------------------------------------------------------------------------
 -- shuffle(t)
 -- shuffles the contents of table t
 -----------------------------------------------------------------------------
function Helper:shuffle(t)
	local n = #t

	while n >= 2 do
		-- n is now the last pertinent index
		local k = math.random(n) -- 1 <= k <= n
		-- Quick swap
		t[n], t[k] = t[k], t[n]
		n = n - 1
	end

	return t
end

 -----------------------------------------------------------------------------
 -- map_range( a1, a2, b1, b2, aVal )
 -- map the value aVal from range a1,a2 to range b1,b2
 -----------------------------------------------------------------------------
function Helper:map_range( a1, a2, b1, b2, aVal )
	return b1 + (aVal-a1)*(b2-b1)/(a2-a1)
end


-----------------------------------------------------------------------------
-- rgb(r,g,b)
-- convert rgb values to values between 0..1
-----------------------------------------------------------------------------
function Helper:rgb(r,g,b)
   return r/255, g/255, b/255
end

-----------------------------------------------------------------------------
-- CreateColor(r,g,b)
-- Creates a table object with three color values
-- Use together with the following function: col( colName )
--
-- Example:
-- local colRed = CreateColor(192,57,43) 
-- object:setFillColor( col( colRed ) )
-----------------------------------------------------------------------------
function Helper:CreateColor(r,g,b)
   return { r/255, g/255, b/255 }
end

-----------------------------------------------------------------------------
-- col( colName )
-- returns r,g,b from colName 
-----------------------------------------------------------------------------
function Helper:col( colName )
   return colName[1], colName[2], colName[3]
end


-----------------------------------------------------------------------------
-- MoveToDisplayGroup( obj, newDG)
-- moves an object to a different display group
-- while maintaining its position
-----------------------------------------------------------------------------
function Helper:MoveToDisplayGroup( obj, newDG)
   local oldX, oldY = obj.parent:localToContent(obj.x, obj.y);
   newDG:insert( obj )
   obj.x, obj.y = newDG:contentToLocal(oldX, oldY)
end


-----------------------------------------------------------------------------
-- Distance( x1,y1, x2,y2)
-- Calculate distance between two points
-----------------------------------------------------------------------------
function Helper:Distance( x1,y1, x2,y2)
   dx = (x2 - x1)
   dy = (y2 - y1)
   return math.sqrt( dx*dx + dy*dy )
end


-----------------------------------------------------------------------------
-- HasCollided( obj1, obj2 )
-- Check if the rectangle boundaries of two objects do overlap
-----------------------------------------------------------------------------
function Helper:HasCollided( obj1, obj2 )
	if ( obj1 == nil ) then  --make sure the first object exists
		return false
	end
	if ( obj2 == nil ) then  --make sure the other object exists
		return false
	end

	local left = obj1.contentBounds.xMin <= obj2.contentBounds.xMin and obj1.contentBounds.xMax >= obj2.contentBounds.xMin
	local right = obj1.contentBounds.xMin >= obj2.contentBounds.xMin and obj1.contentBounds.xMin <= obj2.contentBounds.xMax
	local up = obj1.contentBounds.yMin <= obj2.contentBounds.yMin and obj1.contentBounds.yMax >= obj2.contentBounds.yMin
	local down = obj1.contentBounds.yMin >= obj2.contentBounds.yMin and obj1.contentBounds.yMin <= obj2.contentBounds.yMax

	return (left or right) and (up or down)
end


-----------------------------------------------------------------------------
-- toboolean( val )
-- converts any value to a boolean value
-----------------------------------------------------------------------------
function Helper:toboolean( val )
	if val == 1 then return true end
	if val == 0 then return false end

	if val == "1" then return true end
	if val == "0" then return false end

	if val == true then return true end
	if val == false then return false end

	if string.lower(val) == "true" then return true end
	if string.lower(val) == "false" then return false end

	if string.lower(val) == "yes" then return true end
	if string.lower(val) == "no" then return false end

	if string.lower(val) == "y" then return true end
	if string.lower(val) == "n" then return false end

	if val == nil then return false end
end


-----------------------------------------------------------------------------
-- print_r ( t )
-- prints the content of a table t
-----------------------------------------------------------------------------
function Helper:print_r ( t ) 
	local print_r_cache={}
	local function sub_print_r(t,indent)
		if (print_r_cache[tostring(t)]) then
			print(indent.."*"..tostring(t))
		else
			print_r_cache[tostring(t)]=true
			if (type(t)=="table") then
				for pos,val in pairs(t) do
					if (type(val)=="table") then
						print(indent.."["..pos.."] => "..tostring(t).." {")
						sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
						print(indent..string.rep(" ",string.len(pos)+6).."}")
					elseif (type(val)=="string") then
						print(indent.."["..pos..'] => "'..val..'"')
					else
						print(indent.."["..pos.."] => "..tostring(val))
					end
				end
			else
				print(indent..tostring(t))
			end
		end
	end
	if (type(t)=="table") then
		print(tostring(t).." {")
		sub_print_r(t,"  ")
		print("}")
	else
		sub_print_r(t,"  ")
	end
	print()
end


-----------------------------------------------------------------------------
-- print_fonts()
-- prints the installed fonts to console
-----------------------------------------------------------------------------
function Helper:print_fonts()
  	local fonts = native.getFontNames()
  	local count, found_count = 0,0

	for i,fontname in ipairs( fonts ) do
		count = count+1
		found_count = found_count + 1
		print( "found font: " .. fontname )
	end

end


-----------------------------------------------------------------------------
-- Log(_debuglevel, _txt)
-----------------------------------------------------------------------------
function Helper:Log(_debuglevel, _txt)
	if _debuglevel == 1 then 
		print( _txt)
	end
end


-----------------------------------------------------------------------------
-- ReadBuildNumber( filename )
-- reads a textfile that only contains a number – the buildnumber i.e. 
-----------------------------------------------------------------------------
function Helper:ReadBuildNumber( filename )
	local path = system.pathForFile( filename, system.ResourceDirectory )

	if path == nil then
		return 0
	end

	local file = io.open( path, "r" )
	local buildno = file:read( "*n" )
	io.close( file )
	file = nil

	print("Build number: " .. tostring(buildno))

	return buildno
end


-----------------------------------------------------------------------------
-- copyFile( srcName, srcPath, dstName, dstPath, overwrite )
-- Copy file from Resource dir to /Documents dir
-- Example: copyFile( "Icon.png", system.ResourceDirectory, "NewIcon.png", system.DocumentsDirectory )
-----------------------------------------------------------------------------
function Helper:copyFile( srcName, srcPath, dstName, dstPath, overwrite )
	local results = true                -- assume no errors

	-- Copy the source file to the destination file
	--
	local rfilePath = system.pathForFile( srcName, srcPath )
	local wfilePath = system.pathForFile( dstName, dstPath )

	local rfh = io.open( rfilePath, "rb" )              
	local wfh = io.open( wfilePath, "wb" )

	if  not wfh then
		print( "writeFileName open error!" )
		results = false                 -- error
	else
		-- Read the file from the Resource directory and write it to the destination directory
		local data = rfh:read( "*a" )

		if not data then
			print( "read error!" )
			results = false     -- error
		else
			if not wfh:write( data ) then
				print( "write error!" ) 
				results = false -- error
			end
		end
	end

	-- Clean up our file handles
	rfh:close()
	wfh:close()

	return results  
end


-----------------------------------------------------------------------------
-- QuickButton(txt,w,h,fontSize,font,color,strokeWidth,strokecolor,cornerRadiu)
-- Create a button quickly
-----------------------------------------------------------------------------
function Helper:QuickButton(txt,w,h,fontSize,font,color,strokeWidth,strokeColor,cornerRadius,fontColor)
  
	if color == nil then color = {0.1725, 0.2431, 0.3137} end
	if strokeColor == nil then strokeColor = {0.5, 0.5, 0.5} end
	if cornerRadius == nil then cornerRadius = 4 end
	local font = font or native.systemFont

	local button = display.newGroup( )

	button.bg = display.newRoundedRect( button, 0, 0, w or 150, h or 30, cornerRadius )
	button.bg:setFillColor( color[1], color[2], color[3], color[4] )
	button.bg:setStrokeColor( strokeColor[1], strokeColor[2], strokeColor[3], strokeColor[4] )
	button.bg.strokeWidth = strokeWidth or 1
	button.text = display.newText( button, txt or "Button", 0, 0, font, fontSize or 12 )
	button.text:setFillColor( fontColor[1], fontColor[2], fontColor[3], fontColor[4] )
	return button
end


-----------------------------------------------------------------------------
-- printMemUsage()
-----------------------------------------------------------------------------
function Helper:PrintMemUsage()      
	local memUsed = ( collectgarbage("count") ) / 1000
	local texUsed = system.getInfo( "textureMemoryUsed" ) / 1000000
		
	local txt 
	print("\n---------MEMORY USAGE INFORMATION---------")
	print("System Memory Used:", string.format("%.03f", memUsed), "Mb")
	print("Texture Memory Used:", string.format("%.03f", texUsed), "Mb")
	print("------------------------------------------\n")
	 
	return true
end


-----------------------------------------------------------------------------
-- urlencode(str)
-----------------------------------------------------------------------------
function Helper:urlencode(str)
   if (str) then
      str = string.gsub (str, "\n", "\r\n")
      str = string.gsub (str, "([^%w ])",
         function (c) return string.format ("%%%02X", string.byte(c)) end)
      str = string.gsub (str, " ", "+")
   end
   return str    
end

-----------------------------------------------------------------------------
-- usleep(nMilliseconds)
-----------------------------------------------------------------------------
function Helper:usleep(nMilliseconds)
    local nStartTime = system.getTimer()
    local nEndTime = nStartTime + nMilliseconds

    while true do 
        if system.getTimer() >= nEndTime then
            break
        end
    end
 end

 
-----------------------------------------------------------------------------
-- trim(s)
-----------------------------------------------------------------------------
function Helper:trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end


-----------------------------------------------------------------------------
-- add a decimal delimiter to separate thousands
-- @param number The number to add delimiters to
-- @param delimiter The delimiter character (optional), default is ","
-- @return a string with the delimited number 
-----------------------------------------------------------------------------
function Helper:DecimalDelimiter(number, delimiter)
	local delimiter = delimiter or ","

  	local formatted = number

  	while true do  
    	formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1' .. delimiter .. '%2')
    	if (k==0) then
      		break
    	end
  	end
  	return formatted
end


-----------------------------------------------------------------------------
-- create a ordinal number from an integer like 1st, 2nd, 3rd, 4th, 34th, 101st, etc
-- @param n The number to be converted
-- @return a string value with the ordinal number
-----------------------------------------------------------------------------
function Helper:OrdinalNumber(n)
  local ordinal, digit = {"st", "nd", "rd"}, string.sub(n, -1)
  if tonumber(digit) > 0 and tonumber(digit) <= 3 and string.sub(n,-2) ~= 11 and string.sub(n,-2) ~= 12 and string.sub(n,-2) ~= 13 then
    return n .. ordinal[tonumber(digit)]
  else
    return n .. "th"
  end
end


-----------------------------------------------------------------------------
-- Remove all event listeners from an object
-- @param obj The The object, the get rid of all event listeners (can also be the global Runtime object)
-----------------------------------------------------------------------------
function Helper:RemoveAllListeners( obj )
  obj._functionListeners = nil
  obj._tableListeners = nil
end


return Helper
