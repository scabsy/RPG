local lfs = require "lfs"

local M = {}
 
----------------------------------------------------------------------------------
-- DoesFileExist( fname, path )
--
-- Checks to see if a file exists in the path.
--
-- Enter:   name = file name
--  path = path to file (directory)
--  defaults to ResourceDirectory if "path" is missing.
--
-- Returns: true = file exists, false = file not found
--
-- Example: Checking for file in Documents directory
-- local results = doesFileExist( "Images/cat.png", system.DocumentsDirectory )
    
-- Example: checking in Resource directory
-- local results = doesFileExist( "Images/cat.png" )
----------------------------------------------------------------------------------
--
local function DoesFileExist( fname, path )
    local results = false

    local filePath = system.pathForFile( fname, path )

    -- filePath will be nil if file doesn't exist and the path is ResourceDirectory
    --
    if filePath then
        filePath = io.open( filePath, "r" )
    end

    if  filePath then
        print( "File found -> " .. fname )
        -- Clean up our file handles
        filePath:close()
        results = true
    else
        print( "File does not exist -> " .. fname )
    end

    print()

    return results
end
M.DoesFileExist = DoesFileExist


----------------------------------------------------------------------------------
-- copyFile( src_name, src_path, dst_name, dst_path, overwrite )
--
-- Copies the source name/path to destination name/path
--
-- Enter:   src_name = source file name
--      src_path = source path to file (directory), nil for ResourceDirectory
--      dst_name = destination file name
--      overwrite = true to overwrite file, false to not overwrite
--
-- Returns: false = error creating/copying file
--      nil = source file not found
--      1 = file already exists (not copied)
--      2 = file copied successfully
--
-- Example
-- copyFile( "readme.txt", nil, "readme.txt", system.DocumentsDirectory, true )
-- local catImage = display.newImage( "cat.png", system.DocumentsDirectory, 0, 0 )
----------------------------------------------------------------------------------
--
local function CopyFile( srcName, srcPath, dstName, dstPath, overwrite )

    local results = false

    local srcPath = doesFileExist( srcName, srcPath )

    if srcPath == false then
        -- Source file doesn't exist
        return nil
    end

    -- Check to see if destination file already exists
    if not overwrite then
        if fileLib.doesFileExist( dstName, dstPath ) then
            -- Don't overwrite the file
            return 1
        end
    end

    -- Copy the source file to the destination file
    --
    local rfilePath = system.pathForFile( srcName, srcPath )
    local wfilePath = system.pathForFile( dstName, dstPath )

    local rfh = io.open( rfilePath, "rb" )

    local wfh = io.open( wfilePath, "wb" )

    if  not wfh then
        print( "writeFileName open error!" )
        return false            -- error
    else
        -- Read the file from the Resource directory and write it to the destination directory
        local data = rfh:read( "*a" )
        if not data then
            print( "read error!" )
            return false    -- error
        else
            if not wfh:write( data ) then
                print( "write error!" )
                return false    -- error
            end
        end
    end

    results = 2     -- file copied

    -- Clean up our file handles
    rfh:close()
    wfh:close()

    return results
end
M.CopyFile = CopyFile

return M