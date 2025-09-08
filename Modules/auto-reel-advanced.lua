-- Advanced Auto Reel Module
-- Automatically completes reel minigame with human-like behavior
-- Based on debug analysis from debugminigamereel.txt

local autoReel = {}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Auto Reel States
autoReel.enabled = false
autoReel.humanLike = true
autoReel.debugMode = true -- Enable debug by default for troubleshooting
autoReel.currentConnection = nil
autoReel.inputConnection = nil
autoReel.aggressiveMode = false -- Default to balanced mode
autoReel.lastFishPosition = 0 -- Track fish movement
autoReel.fishVelocity = 0 -- Predict fish movement
autoReel.gameStartTime = 0 -- Track when minigame started
autoReel.lastProgressCheck = 0 -- Track progress building
autoReel.allowedToPlay = false -- Control when to start playing

-- Toggle debug mode
function autoReel.setDebugMode(enabled)
    autoReel.debugMode = enabled
    print("🎣 Auto Reel Debug: " .. (enabled and "Enabled" or "Disabled"))
end

-- Toggle aggressive mode for ultra-responsive tracking
function autoReel.setAggressiveMode(enabled)
    autoReel.aggressiveMode = enabled
    print("🎣 Auto Reel Aggressive Mode: " .. (enabled and "Enabled - Ultra responsive tracking" or "Disabled - Normal tracking"))
end

-- Get current status
function autoReel.getStatus()
    return {
        enabled = autoReel.enabled,
        humanLike = autoReel.humanLike,
        debugMode = autoReel.debugMode,
        aggressiveMode = autoReel.aggressiveMode,
        fishVelocity = autoReel.fishVelocity
    }
end

-- Configuration (Balanced for natural gameplay)
local CONFIG = {
    -- Timing settings (more balanced)
    reactionTime = {min = 0.05, max = 0.15}, -- More human-like reaction (50-150ms)
    holdDuration = {min = 0.1, max = 0.4}, -- Longer holds for natural gameplay
    releaseDelay = {min = 0.05, max = 0.2}, -- Reasonable release timing
    
    -- Precision settings (balanced)
    targetTolerance = 0.03, -- Reasonable tolerance (3%)
    progressThreshold = 0.85, -- Start being more careful at 85% progress
    updateFrequency = 0.05, -- 20 FPS update rate (natural pace)
    
    -- Natural gameplay settings
    fastTrackingMode = false, -- Disable for more natural gameplay
    predictiveMovement = false, -- Disable prediction for realism
    progressWaitTime = {min = 0.5, max = 1.5}, -- Wait for progress to build naturally
    
    -- Human behavior (increased for realism)
    missChance = 0.08, -- 8% chance to "miss" 
    overcompensateChance = 0.12, -- 12% chance to overcompensate
    perfectPlayChance = 0.65, -- 65% chance to play perfectly
    struggleChance = 0.15, -- 15% chance to "struggle" briefly
}

-- Helper function for random delays
local function randomDelay(min, max)
    return min + (math.random() * (max - min))
end

-- Human-like random behavior (enhanced)
local function getRandomBehavior()
    local rand = math.random()
    if rand < CONFIG.missChance then
        return "miss" -- Intentionally miss slightly
    elseif rand < CONFIG.missChance + CONFIG.overcompensateChance then
        return "overcompensate" -- Overcompensate movement
    elseif rand < CONFIG.missChance + CONFIG.overcompensateChance + CONFIG.struggleChance then
        return "struggle" -- Brief struggle/hesitation
    else
        return "normal" -- Normal behavior
    end
end

-- Get fish and player bar positions
local function getReelPositions(reelGui)
    local bar = reelGui:FindFirstChild("bar")
    if not bar then return nil, nil, nil end
    
    local fish = bar:FindFirstChild("fish")
    local playerbar = bar:FindFirstChild("playerbar")
    local progress = bar:FindFirstChild("progress")
    
    if not fish or not playerbar or not progress then
        return nil, nil, nil
    end
    
    return fish, playerbar, progress
end

-- Calculate if player needs to move towards fish (Balanced tracking)
local function calculateMovement(fish, playerbar, progress)
    local fishPos = fish.Position.X.Scale
    local playerPos = playerbar.Position.X.Scale
    local progressBar = progress:FindFirstChild("bar")
    local currentProgress = progressBar and progressBar.Size.X.Scale or 0
    
    -- Simple distance calculation (no prediction for natural gameplay)
    local distance = fishPos - playerPos
    local absDistance = math.abs(distance)
    
    -- Adjust tolerance based on progress (more forgiving early game)
    local tolerance = CONFIG.targetTolerance
    if currentProgress < 0.3 then
        tolerance = tolerance * 2 -- More forgiving in early game
    elseif currentProgress > CONFIG.progressThreshold then
        tolerance = tolerance * 0.6 -- More precise near completion
    end
    
    -- Get human behavior for this action
    local behavior = getRandomBehavior()
    
    -- Determine if we need to move
    local needsMovement = absDistance > tolerance
    local direction = distance > 0 and "right" or "left"
    
    -- Simple urgency based on distance only
    local urgency = "normal"
    if absDistance > 0.1 then
        urgency = "high"
    elseif absDistance > 0.05 then
        urgency = "medium"
    end
    
    return needsMovement, direction, absDistance, currentProgress, behavior, urgency
end

-- Natural input simulation with realistic timing  
local function simulateInput(action, duration, urgency)
    if not autoReel.enabled or not autoReel.allowedToPlay then return end
    
    urgency = urgency or "normal"
    
    if action == "hold" then
        -- Use mouse click and hold method for reel minigame
        local VirtualInputManager = game:GetService("VirtualInputManager")
        
        -- Start holding (mouse down)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        
        if autoReel.debugMode then
            print("🎣 Auto Reel: Holding for " .. tostring(duration) .. "s")
        end
        
        -- Realistic duration with natural variation
        local actualDuration = duration + randomDelay(-0.05, 0.05)
        
        spawn(function()
            wait(actualDuration)
            if autoReel.enabled and autoReel.allowedToPlay then
                -- Release mouse
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                if autoReel.debugMode then
                    print("🎣 Auto Reel: Released")
                end
            end
        end)
        
    elseif action == "tap" then
        -- Quick tap for fine adjustments
        local VirtualInputManager = game:GetService("VirtualInputManager")
        
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        local tapDuration = randomDelay(0.08, 0.15) -- Natural tap duration
        wait(tapDuration)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        
        if autoReel.debugMode then
            print("🎣 Auto Reel: Quick tap")
        end
    end
end

-- Main reel automation logic (Natural gameplay version)
local function handleReelMinigame(reelGui)
    local fish, playerbar, progress = getReelPositions(reelGui)
    if not fish or not playerbar or not progress then
        warn("Auto Reel: Could not find reel elements")
        return
    end
    
    print("🎣 Auto Reel: Minigame detected, starting natural gameplay...")
    
    -- Initialize game timing
    autoReel.gameStartTime = tick()
    autoReel.allowedToPlay = false
    autoReel.lastProgressCheck = 0
    
    -- Initial delay to let player see the minigame start
    spawn(function()
        wait(randomDelay(0.3, 0.8)) -- Natural start delay
        autoReel.allowedToPlay = true
        print("🎣 Auto Reel: Starting to play...")
    end)
    
    -- Main automation loop
    autoReel.currentConnection = RunService.Heartbeat:Connect(function()
        if not autoReel.enabled then return end
        
        local reelCheck = player.PlayerGui:FindFirstChild("reel")
        if not reelCheck then
            -- Reel ended
            if autoReel.currentConnection then
                autoReel.currentConnection:Disconnect()
                autoReel.currentConnection = nil
            end
            if autoReel.debugMode then
                print("🎣 Auto Reel: Minigame ended")
            end
            return
        end
        
        -- Don't play immediately - wait for allowedToPlay
        if not autoReel.allowedToPlay then
            wait(0.1)
            return
        end
        
        -- Get current positions and calculate movement
        local needsMovement, direction, distance, currentProgress, behavior, urgency = calculateMovement(fish, playerbar, progress)
        
        -- Progress-based behavior: let progress build naturally
        local timePlaying = tick() - autoReel.gameStartTime
        local shouldPause = false
        
        -- Check if progress is building too fast
        if currentProgress > autoReel.lastProgressCheck + 0.15 and timePlaying < 2 then
            shouldPause = true -- Pause to let progress normalize
            if autoReel.debugMode then
                print("🎣 Auto Reel: Pausing to let progress build naturally...")
            end
        end
        autoReel.lastProgressCheck = currentProgress
        
        if autoReel.debugMode then
            print(string.format("🎣 Distance: %.3f, Progress: %.1f%%, Behavior: %s, Time: %.1fs", 
                distance, currentProgress * 100, behavior, timePlaying))
        end
        
        -- Implement struggle/pause behavior
        if behavior == "struggle" then
            if autoReel.debugMode then
                print("🎣 Auto Reel: Struggling briefly...")
            end
            wait(randomDelay(0.3, 0.8)) -- Brief struggle pause
            return
        end
        
        -- Pause if progress building too fast
        if shouldPause then
            wait(randomDelay(0.5, 1.2))
            return
        end
        
        if needsMovement then
            -- Natural response system with realistic timing
            local reactionDelay = randomDelay(CONFIG.reactionTime.min, CONFIG.reactionTime.max)
            local holdTime = math.clamp(distance * 1.5, CONFIG.holdDuration.min, CONFIG.holdDuration.max)
            
            -- Modify based on behavior for realism
            if behavior == "miss" then
                holdTime = holdTime * 0.7 -- Shorter hold (intentional miss)
                if autoReel.debugMode then
                    print("🎣 Auto Reel: Intentional slight miss")
                end
            elseif behavior == "overcompensate" then
                holdTime = holdTime * 1.4 -- Longer hold (overcompensate)
                if autoReel.debugMode then
                    print("🎣 Auto Reel: Overcompensating movement")
                end
            end
            
            -- Execute movement with natural delays
            spawn(function()
                wait(reactionDelay)
                if autoReel.enabled and autoReel.allowedToPlay then
                    simulateInput("hold", holdTime, urgency)
                    
                    -- Natural wait before next action
                    local nextDelay = holdTime + randomDelay(CONFIG.releaseDelay.min, CONFIG.releaseDelay.max)
                    wait(nextDelay)
                end
            end)
            
            -- Prevent rapid inputs
            wait(randomDelay(0.1, 0.25))
        else
            -- Fine adjustments with realistic frequency
            if distance > 0.01 and math.random() < 0.3 then -- 30% chance for adjustment
                simulateInput("tap", nil, "normal")
                wait(randomDelay(0.2, 0.5))
            end
        end
        
        -- Natural update frequency (not too fast)
        wait(CONFIG.updateFrequency)
    end)
end
end

-- Start auto reel
function autoReel.start()
    if autoReel.enabled then
        autoReel.stop()
    end
    
    autoReel.enabled = true
    
    -- Monitor for reel minigame
    autoReel.inputConnection = player.PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "reel" and child:IsA("ScreenGui") then
            -- Small delay to let UI fully load
            wait(0.1)
            handleReelMinigame(child)
        end
    end)
    
    -- Check if reel is already active
    local existingReel = player.PlayerGui:FindFirstChild("reel")
    if existingReel then
        handleReelMinigame(existingReel)
    end
    
    print("🎣 Auto Reel: Started (Human-like behavior)")
end

-- Stop auto reel
function autoReel.stop()
    autoReel.enabled = false
    
    if autoReel.currentConnection then
        autoReel.currentConnection:Disconnect()
        autoReel.currentConnection = nil
    end
    
    if autoReel.inputConnection then
        autoReel.inputConnection:Disconnect()
        autoReel.inputConnection = nil
    end
    
    print("🎣 Auto Reel: Stopped")
end

-- Toggle debug mode
function autoReel.setDebugMode(enabled)
    autoReel.debugMode = enabled
    print("🎣 Auto Reel: Debug mode " .. (enabled and "enabled" or "disabled"))
end

-- Configure behavior
function autoReel.configure(settings)
    for key, value in pairs(settings) do
        if CONFIG[key] then
            CONFIG[key] = value
            print("🎣 Auto Reel: " .. key .. " updated")
        end
    end
end

-- Get status
function autoReel.getStatus()
    return {
        enabled = autoReel.enabled,
        humanLike = autoReel.humanLike,
        debugMode = autoReel.debugMode,
        hasActiveConnection = autoReel.currentConnection ~= nil
    }
end

-- Test function for manual testing
function autoReel.test()
    print("🎣 Auto Reel: Testing input simulation...")
    simulateInput("hold", 0.5)
    wait(1)
    simulateInput("tap")
    print("🎣 Auto Reel: Test completed")
end

-- Advanced: Analyze reel performance
function autoReel.analyzeReel()
    local reelGui = player.PlayerGui:FindFirstChild("reel")
    if not reelGui then
        print("🎣 Auto Reel: No active reel minigame")
        return
    end
    
    local fish, playerbar, progress = getReelPositions(reelGui)
    if fish and playerbar and progress then
        local fishPos = fish.Position.X.Scale
        local playerPos = playerbar.Position.X.Scale
        local progressBar = progress:FindFirstChild("bar")
        local currentProgress = progressBar and progressBar.Size.X.Scale or 0
        
        print("🎣 === REEL ANALYSIS ===")
        print("Fish Position: " .. string.format("%.3f", fishPos))
        print("Player Position: " .. string.format("%.3f", playerPos))
        print("Distance: " .. string.format("%.3f", math.abs(fishPos - playerPos)))
        print("Progress: " .. string.format("%.1f%%", currentProgress * 100))
        print("======================")
    end
end

return autoReel
