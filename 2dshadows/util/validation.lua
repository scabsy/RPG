-------------------------------------------------
-- validation.lua
--
-- A string validation module for common validation like formfields etc
--
-- @module Validation
-- @author René Aye
-- @license MIT
-- @copyright DevilSquid, René Aye 2016
-------------------------------------------------
 


local Validation = {}


-------------------------------------------------
-- Validates an email adress
-- @string email the email address to check for
-- @return boolean true ot false
-------------------------------------------------
function Validation:Email( email )
    if ( email:match("[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?") ) then
       return true
    else
       return false
    end
end


return Validation