-------------------------------------------------
-- device.lua
-- Sets up some simple boolean flags that lets us do various device tests.
--
-- Target devices: simulator, device
--
-- Returns a table with infos about the current used system
--
--  - `isApple`: true if an Apple system is used
--  - `isAndroid`: true if an Android system is used
--  - `isGoogle`: true if a Google system is used
--  - `isKindleFire`: true if a Kindle Fire system is used
--  - `isNook`: true if a Nook system is used
--  - `is_iPad`: true if an iPad system is used
--  - `isTall`: true if an tall device system is used
--  - `isSimulator`: true if the simulator system is used
-- @usage
-- local devices = require( "util.devices" )
-- if devices.isApple == true then
-- end
--
-- @module Device
-- @author Corona Labs
-- @license Sample code is MIT licensed, see http://www.coronalabs.com/links/code/license
-- @copyright 2012 Corona Labs Inc. All Rights Reserved
-------------------------------------------------
local M = {}

--
-- Set up some defaults
--

M.isApple       = false
M.isAndroid     = false
M.isGoogle      = false
M.isAmazon      = false
M.isKindleFire  = false
M.isNook        = false
M.is_iPad       = false
M.isTall        = false
M.isTablet      = false
M.isSimulator   = false
M.isTV          = false
M.isFireTV      = false

M.model             = system.getInfo("model")
M.platform          = ""
M.platformVersion   = system.getInfo("platformVersion")
M.targetAppStore    = system.getInfo("targetAppStore")
M.deviceID          = system.getInfo("deviceID")


-- Are we on the simulator?

if "simulator" == system.getInfo("environment") then
    M.isSimulator = true
end

-- lets see if we are a tall device


if (display.pixelHeight/display.pixelWidth) >= 1.5 then
    M.isTall = true
    M.isTablet = false
else
    M.isTall = false
    M.isTablet = true
end

-- first, look to see if we are on some Apple platform.
-- All models start with iP, so we can check that.

if string.sub(M.model,1,2) == "iP" then 
     -- We are an iOS device of some sort
     M.isApple = true

     if string.sub(M.model, 1, 4) == "iPad" then
         M.is_iPad = true
         M.isTablet = true
     end
else
    -- Not Apple, then we must be one of the Android devices
    M.isAndroid = true

    -- lets assume we are Google for the moment
    M.isGoogle = true
    M.isAmazon = false

    -- All the Kindles start with K, though Corona SDK before build 976's Kindle Fire 9 returned "WFJWI" instead of "KFJWI"

    if M.model == "Kindle Fire" or M.model == "WFJWI" or string.sub(M.model,1,2) == "KF" then
        M.isKindleFire  = true
        M.isAmazon      = true
        M.isTablet      = true
        M.isGoogle      = false
    end

    -- Are we a nook?

    if string.sub(M.model,1,4) == "Nook" or string.sub(M.model,1,4) == "BNRV" then
        M.isNook        = true
        M.isTablet      = true
        M.isGoogle      = false
    end

    -- Are we a Amazon Fire TV?

    if string.sub(M.model,1,3) == "AFT" then
        M.isTV          = true
        M.isFireTV      = true
        M.isGoogle      = false
        M.isAmazon      = true
    end

    -- is Amazon target store?
    if M.targetAppStore == "amazon" then
        M.isGoogle      = false
        M.isAmazon      = true
    end

end


if M.isApple == true then
    M.platform = "ios"
elseif M.isAndroid == true then
    M.platform = "android"
elseif M.isKindleFire == true then
    M.platform = "amazon"
end


return M

