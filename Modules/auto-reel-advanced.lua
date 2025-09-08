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
autoReel.debugMode = false
autoReel.currentConnection = nil
autoReel.inputConnection = nil

-- Configuration
local CONFIG = {
    -- Timing settings (human-like)
    reactionTime = {min = 0.1, max = 0.3}, -- Human reaction delay
    holdDuration = {min = 0.2, max = 0.8}, -- How long to hold input
    releaseDelay = {min = 0.1, max = 0.4}, -- Delay before next action
    
    -- Precision settings
    targetTolerance = 0.05, -- How close to fish position (5% tolerance)
    progressThreshold = 0.85, -- Start being more careful at 85% progress
    
    -- Human behavior
    missChance = 0.05, -- 5% chance to "miss" like human
    overcompensateChance = 0.1, -- 10% chance to overcompensate
    perfectPlayChance = 0.7, -- 70% chance to play perfectly
}

-- Helper function for random delays
local function randomDelay(min, max)
    return min + (math.random() * (max - min))
end

-- Human-like random behavior
local function getRandomBehavior()
    local rand = math.random()
    if rand < CONFIG.missChance then
        return "miss" -- Intentionally miss slightly
    elseif rand < CONFIG.missChance + CONFIG.overcompensateChance then
        return "overcompensate" -- Overcompensate movement
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

-- Calculate if player needs to move towards fish
local function calculateMovement(fish, playerbar, progress)
    local fishPos = fish.Position.X.Scale
    local playerPos = playerbar.Position.X.Scale
    local progressBar = progress:FindFirstChild("bar")
    local currentProgress = progressBar and progressBar.Size.X.Scale or 0
    
    -- Calculate distance and required movement
    local distance = fishPos - playerPos
    local absDistance = math.abs(distance)
    
    -- Adjust behavior based on progress
    local tolerance = CONFIG.targetTolerance
    if currentProgress > CONFIG.progressThreshold then
        tolerance = tolerance * 0.5 -- More precise near completion
    end
    
    -- Get human behavior for this action
    local behavior = getRandomBehavior()
    
    -- Determine if we need to move
    local needsMovement = absDistance > tolerance
    local direction = distance > 0 and "right" or "left"
    
    return needsMovement, direction, absDistance, currentProgress, behavior
end

-- Simulate human input
local function simulateInput(action, duration)
    if not autoReel.enabled then return end
    
    local VirtualInputManager = game:GetService("VirtualInputManager")
    
    if action == "hold" then
        -- Start holding
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, player, 0)
        
        -- Hold for specified duration with slight variation
        local actualDuration = duration + randomDelay(-0.05, 0.05)
        
        spawn(function()
            wait(actualDuration)
            if autoReel.enabled then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, player, 0)
            end
        end)
        
    elseif action == "tap" then
        -- Quick tap
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, player, 0)
        wait(randomDelay(0.05, 0.15))
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, player, 0)
    end
end

-- Main reel automation logic
local function handleReelMinigame(reelGui)
    local fish, playerbar, progress = getReelPositions(reelGui)
    if not fish or not playerbar or not progress then
        warn("Auto Reel: Could not find reel elements")
        return
    end
    
    if autoReel.debugMode then
        print("🎣 Auto Reel: Minigame detected, starting automation...")
    end
    
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
        
        -- Get current positions and calculate movement
        local needsMovement, direction, distance, currentProgress, behavior = calculateMovement(fish, playerbar, progress)
        
        if autoReel.debugMode then
            print(string.format("🎣 Distance: %.3f, Progress: %.1f%%, Behavior: %s", 
                distance, currentProgress * 100, behavior))
        end
        
        if needsMovement then
            -- Calculate hold duration based on distance and behavior
            local baseDuration = distance * 2 -- Base duration proportional to distance
            local holdTime = math.clamp(baseDuration, CONFIG.holdDuration.min, CONFIG.holdDuration.max)
            
            -- Modify based on behavior
            if behavior == "miss" then
                holdTime = holdTime * 0.7 -- Shorter hold (miss slightly)
            elseif behavior == "overcompensate" then
                holdTime = holdTime * 1.3 -- Longer hold (overcompensate)
            end
            
            -- Add human-like reaction delay
            local reactionDelay = randomDelay(CONFIG.reactionTime.min, CONFIG.reactionTime.max)
            
            spawn(function()
                wait(reactionDelay)
                if autoReel.enabled then
                    simulateInput("hold", holdTime)
                    
                    -- Wait before next action
                    wait(holdTime + randomDelay(CONFIG.releaseDelay.min, CONFIG.releaseDelay.max))
                end
            end)
            
            -- Prevent rapid-fire inputs
            wait(0.1)
        else
            -- We're close enough, just maintain position with small adjustments
            if math.random() < 0.3 then -- 30% chance to make small adjustment
                simulateInput("tap")
                wait(randomDelay(0.2, 0.5))
            end
        end
        
        -- Small delay to prevent overwhelming the system
        wait(0.05)
    end)
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
