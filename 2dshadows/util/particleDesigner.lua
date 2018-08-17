if devilsquid == nil then
    devilsquid = {}
    if devilsquid.requirepath == nil then devilsquid.requirepath = "devilsquid." end
    if devilsquid.filepath == nil then devilsquid.filepath = "devilsquid/" end
end





local particleDesigner = {}

local json = require( "json" )
local Helper = require( devilsquid.requirepath .. "util.helper" )


function particleDesigner.newEmitter( fileName, baseDir )
    local baseDir = baseDir or system.ResourceDirectory

    local filePath = system.pathForFile(fileName, baseDir)
    --print("fileName", fileName, baseDir)
    --print("filePath", filePath)
    local f = io.open(filePath, "r")
    local fileData = f:read("*a")
    f:close()

    local emitterParams = json.decode(fileData)

    -- fix start ------------------
    -- Corona builds do not support particle textures in subfolders
    -- the code below fixes this issue
    local slashPos = nil
    local tmpPos = 0

    -- find last slash in input string
    repeat
        tmpPos = fileName:find("/", tmpPos + 1)

        if (tmpPos) then
            slashPos = tmpPos
        end
    until not tmpPos

    if (slashPos) then
        local subfolder = fileName:sub(1, slashPos)

        -- future-proofing in case CoronaLabs fixes this issue
        if (not emitterParams.textureFileName:find("/")) then
            emitterParams.textureFileName = subfolder .. emitterParams.textureFileName
        end
    end
    -- fix end ------------------


    local emitter = display.newEmitter(emitterParams)
    emitter.x, emitter.y = 0, 0
    --emitter.isVisible = false

    return emitter
end


return particleDesigner