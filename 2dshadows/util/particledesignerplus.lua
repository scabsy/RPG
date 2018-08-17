if devilsquid == nil then
    devilsquid = {}
    if devilsquid.requirepath == nil then devilsquid.requirepath = "devilsquid." end
    if devilsquid.filepath == nil then devilsquid.filepath = "devilsquid/" end
end




-------------------------------------------------
--
-- particledesignerplus.lua
--
-- Particle Designer Plus is a workaround system to synchronise 
-- particle emitters with sound
--
-- HOW TO USE

-- example 1

-- local emitterPulse = ParticleDesigner:new({ fileName="pfx/pulse.json" })


-- example 2
-- if we want to change the gap between a looping particle effect
-- we can use the duration and the delay parameter
-- delay does only work if duration has a value too

-- local emitterPulse = ParticleDesigner:new({ fileName="pfx/pulse.json", duration=2000, delay=2000 })


-- example 3
-- play an audio file at each start of the particle effect

-- local emitterPulse = ParticleDesigner:new({ fileName="pfx/pulse.json", startSound=explosionAudioHandle })


-- example 4
-- delay the startAudio to better synchronise to visual effect
-- without duration/delay values the sound is only played when emitter:start() is called

-- local emitterPulse = ParticleDesigner:new({ fileName="pfx/pulse.json", startSound=explosionAudioHandle, startSoundDelay=500 })


-- example 5
-- stopAudio is possible too
-- without duration/delay values the sound is only played when emitter:stop() is called

-- local emitterPulse = ParticleDesigner:new({ fileName="pfx/pulse.json", stopSound=explosionAudioHandle, stopSoundDelay=500 })


-- example 6
-- automatic sound play on start of a new loop ( without calling emitter:start() )
-- in the following example the effect gets stopped after 2000 ms, then waits 4000ms to re-start again
-- on re-start the audio file is played with a delay of 500 ms

-- local emitterPulse = ParticleDesigner:new({ fileName="pfx/pulse.json", duration=2000, delay=4000, startSound=explosionAudioHandle, startSoundDelay=500 })


-- example 7
-- we have a also some eventHandler named "started" and "stopped"
-- the following exa,mple prints "emitterPulse stopped", when the effect gets stopped after 2000 ms 
-- then after 4000 ms the effects starts again
-- the eventHandler prints "emitterPulse started" and 1000ms later it plays an audio file

-- local emitterPulse = ParticleDesigner:new({ fileName="pfx/pulse.json", duration=2000, delay=4000 })
-- emitterPulse:addEventListener( "stopped", function() print("emitterPulse stopped") end )
-- emitterPulse:addEventListener( "started", function() 
--      print("emitterPulse started")
--      timer.performWithDelay( 1000, function() audio.play( Audio.sfx.pulse2 ) end )
--   end )
--
-------------------------------------------------
local particleDesignerPlus = {}


local json      = require( "json" )
local Helper    = require( devilsquid.requirepath .. "util.helper" )
local log       = require( devilsquid.requirepath .. "util.log" )

local ParticleDesignerPlus = {}



function ParticleDesignerPlus:new( options )

    -- check mandatory options
    if type(options.fileName) ~= "string" then
        error("ParticleDesignerPlus:new() - no fileName to load a particle effect")

    elseif type(options.duration) ~= "nil" and type(options.duration) ~= "number" then
        error("ParticleDesignerPlus:new() - duration is not a number")

    elseif type(options.delay) ~= "nil" and type(options.delay) ~= "number" then
        error("ParticleDesignerPlus:new() - delay is not a number")

    end

    local pfx   = display.newGroup()
    
    pfx.emitter         = nil               -- the emitter object
    pfx.timers          = {}                -- a table that contains all timer objects
    pfx.loop            = false             -- whether the emitter is a looping effect (duration == -1)    
    pfx.startTime       = 0
    pfx.stopTime        = 0
    pfx.state           = ""                -- the state of the whole system (this is not emitter.state)

    pfx.fileName        = options.fileName
    pfx.baseDir         = options.baseDir
    pfx.duration        = options.duration or 0
    pfx.delay           = options.delay or 0
    pfx.startSound      = options.startSound
    pfx.startSoundDelay = options.startSoundDelay or 0
    pfx.stopSound       = options.stopSound
    pfx.stopSoundDelay  = options.stopSoundDelay or 0

    pfx.debug                   = false
    pfx.debugText               = display.newText( {text="Debug", x=0, y=0, width=400, font=native.systemFont, fontSize=12} )
    pfx.debugText.isVisible     = pfx.debug
    pfx.debugText:setFillColor( 1,1,1 )
    pfx.debugText.anchorX       = 0
    pfx.debugText.anchorY       = 0
    pfx.debugText.x             = 20
    pfx.debugText.y             = 20

    log:p(2, "particleDesignerPlus:new()", options.fileName, options.duration)




    -----------------------------------------------------------------------------
    -- pfx:start( event )
    -----------------------------------------------------------------------------
    function pfx:start()
        log:p(2, "particleDesignerPlus pfx:start()")

        self.state = "playing"
        self.emitter:start()
        self.startTime = system.getTimer()

        if self.startSound ~= nil then
            if self.startSoundDelay == 0 then
                audio.play( self.startSound )
            else
                timer.performWithDelay( self.startSoundDelay, function() audio.play( self.startSound ) end )
            end
        end
    end


    -----------------------------------------------------------------------------
    -- pfx:pause( event )
    -----------------------------------------------------------------------------
    function pfx:pause()
        log:p(2, "particledesignerplus pfx:pause()")
        -- pause the particle emitter
        self.emitter:pause()
    end

    -----------------------------------------------------------------------------
    -- pfx:resume( event )
    -----------------------------------------------------------------------------
    function pfx:resume()
        log:p(2, "particledesignerplus pfx:resume()")
        -- resume the particle emitter
        self.emitter:start()
    end


    -----------------------------------------------------------------------------
    -- pfx:stop( event )
    -----------------------------------------------------------------------------
    function pfx:stop()
        log:p(2, "particledesignerplus pfx:stop()")
        self.emitter:stop()
        self.state = "stopped"

        -- play a stop sound if exists
        if self.stopSound ~= nil then

            -- check if the stop sound should be played immediatly or with a delay
            if self.stopSoundDelay == 0 then
                audio.play( self.stopSound )
            else
                timer.performWithDelay( self.stopSoundDelay, function() audio.play( self.stopSound ) end )
            end
        end
    end

    -----------------------------------------------------------------------------
    -- pfx:loopstop( event )
    -----------------------------------------------------------------------------
    function pfx:loopstop()
        log:p(2, "particledesignerplus pfx:loopstop()")
        self.emitter:stop()
        self.state = "loopstopped"

        -- play a stop sound if exists
        if self.stopSound ~= nil then

            -- check if the stop sound should be played immediatle or with a delay
            if self.stopSoundDelay == 0 then
                audio.play( self.stopSound )
            else
                timer.performWithDelay( self.stopSoundDelay, function() audio.play( self.stopSound ) end )
            end
        end
    end


    -----------------------------------------------------------------------------
    -- pfx:Update( event )
    -----------------------------------------------------------------------------
    function pfx:Update()
        
        if self.state ~= "stopped" then
            if self.loop == true then
                if self.duration == 0 then return end

                local now = system.getTimer()

                if self.emitter.state == "playing" then
                    if now - self.startTime >= self.duration then
                        self.stopTime = now
                        self:loopstop()
                        self:stop()

                        -- dispatch event
                        self:dispatchEvent( { name = "stopped" } )
                    end

                elseif self.emitter.state == "stopped" then
                    if now - self.stopTime >= self.delay then
                        self.startTime = now
                        self:start()

                        -- dispatch event
                        self:dispatchEvent( { name = "started" } )
                    end  
                end
            end
        end
    end


    -----------------------------------------------------------------------------
    -- pfx:UpdateDebug( )
    -----------------------------------------------------------------------------
    function pfx:UpdateDebug()
        local txt = ""
        txt = txt .. "self.state: " .. self.state .. "\n"
        txt = txt .. "self.emitter.tate: " .. self.emitter.state .. "\n"

        self.debugText.text = txt
    end

    -----------------------------------------------------------------------------
    -- pfx:timer( event )
    -----------------------------------------------------------------------------
    function pfx:timer( event )
        self:Update()
        if self.debug == true then self:UpdateDebug() end
    end

    local tm = timer.performWithDelay( 10, pfx, 0 )
    table.insert( pfx.timers, tm )





    -----------------------------------------------------------------------------
    -- CONSTRUCTOR AREA – THESE METHODS DO GET CALLED WHEN New() HAS BEEN CALLED
    -----------------------------------------------------------------------------

    -----------------------------------------------------------------------------
    -- pfx:LoadEmitter()
    -----------------------------------------------------------------------------
    function pfx:LoadEmitter()
        -- load particle designer data
        local baseDir = self.baseDir or system.ResourceDirectory

        local filePath = system.pathForFile(self.fileName, baseDir)
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
            tmpPos = self.fileName:find("/", tmpPos + 1)

            if (tmpPos) then
                slashPos = tmpPos
            end
        until not tmpPos

        if (slashPos) then
            local subfolder = self.fileName:sub(1, slashPos)

            -- future-proofing in case CoronaLabs fixes this issue
            if (not emitterParams.textureFileName:find("/")) then
                emitterParams.textureFileName = subfolder .. emitterParams.textureFileName
            end
        end
        -- fix end ------------------


        local emitter = display.newEmitter(emitterParams)
        self.startTime = system.getTimer()

        self:insert(emitter)
        emitter.x, emitter.y = 0, 0

        -- check if this emitter is a looping emitter
        -- if yes set self.loop to true
        if emitter.duration == -1 then
            self.loop = true
        end

        return emitter
    end
    pfx.emitter = pfx:LoadEmitter( fileName, baseDir )

    

    --- return the pfx object

    return pfx
end

return ParticleDesignerPlus