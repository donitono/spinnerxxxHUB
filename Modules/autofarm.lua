-- Autofarm Module
-- Kombinasi fitur dari sanhub, kinghub, dan neoxhub

local autofarm = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Autofarm States
autofarm.autoCastEnabled = false
autofarm.autoShakeEnabled = false
autofarm.autoReelEnabled = false
autofarm.alwaysCatchEnabled = false
autofarm.randomDelayEnabled = false -- New: Random delay for human-like behavior
autofarm.shakeMode = 1 -- 1 = sanhub method, 2 = neoxhub method
autofarm.castMode = 1 -- 1 = legit, 2 = rage, 3 = random

-- Human-like random delay function
local function getRandomDelay(baseDelay, variationPercent)
    if not autofarm.randomDelayEnabled then
        return baseDelay
    end
    
    -- Add random variation (±variationPercent)
    local variation = baseDelay * (variationPercent / 100)
    local minDelay = baseDelay - variation
    local maxDelay = baseDelay + variation
    
    -- Ensure minimum delay is at least 0.1 seconds
    minDelay = math.max(minDelay, 0.1)
    
    local randomDelay = minDelay + (math.random() * (maxDelay - minDelay))
    return randomDelay
end

-- Auto Cast (dari kinghub dengan metodenya)
function autofarm.startAutoCast(mode)
    autofarm.autoCastEnabled = true
    autofarm.castMode = mode or 1
    
    -- Hook untuk tool equipped
    local function onCharacterChildAdded(child)
        if not autofarm.autoCastEnabled then return end
        
        if child:IsA("Tool") and child:FindFirstChild("events") then
            local castEvent = child.events:FindFirstChild("cast")
            if castEvent then
                local castDelay = getRandomDelay(2, 30) -- 2±30% = 1.4-2.6 seconds
                task.wait(castDelay) -- Random delay sebelum cast
                
                local success, err = pcall(function()
                    if autofarm.castMode == 1 then
                        -- Mode 1: Legit - simulate mouse click dan tunggu full power
                        local VirtualInputManager = game:GetService("VirtualInputManager")
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, player, 0)
                        
                        -- Monitor power bar untuk release saat FULL (seperti kinghub)
                        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                        if humanoidRootPart then
                            local powerConnection
                            powerConnection = humanoidRootPart.ChildAdded:Connect(function(powerChild)
                                if powerChild.Name == "power" then
                                    local powerbar = powerChild:FindFirstChild("powerbar")
                                    if powerbar and powerbar:FindFirstChild("bar") then
                                        local barConnection
                                        barConnection = powerbar.bar:GetPropertyChangedSignal("Size"):Connect(function()
                                            -- Release saat mencapai FULL power (100%) seperti kinghub
                                            if powerbar.bar.Size == UDim2.new(1, 0, 1, 0) then
                                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, player, 0)
                                                barConnection:Disconnect()
                                                powerConnection:Disconnect()
                                            end
                                        end)
                                    end
                                end
                            end)
                        end
                        
                    elseif autofarm.castMode == 2 then
                        -- Mode 2: Rage - direct FireServer with random delay
                        local rageDelay = getRandomDelay(0.2, 100) -- 0.2±100% = 0.1-0.4 seconds
                        task.wait(rageDelay) -- Small random delay even for rage mode
                        castEvent:FireServer(100)
                        
                    elseif autofarm.castMode == 3 then
                        -- Mode 3: Random - legit with random timing (85-100%)
                        local VirtualInputManager = game:GetService("VirtualInputManager")
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, player, 0)
                        
                        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                        if humanoidRootPart then
                            local powerConnection
                            powerConnection = humanoidRootPart.ChildAdded:Connect(function(powerChild)
                                if powerChild.Name == "power" then
                                    local powerbar = powerChild:FindFirstChild("powerbar")
                                    if powerbar and powerbar:FindFirstChild("bar") then
                                        local barConnection
                                        -- Random target antara 85-100% untuk variasi
                                        local randomTarget = math.random(85, 100) / 100
                                        barConnection = powerbar.bar:GetPropertyChangedSignal("Size"):Connect(function()
                                            if powerbar.bar.Size.X.Scale >= randomTarget then
                                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, player, 0)
                                                barConnection:Disconnect()
                                                powerConnection:Disconnect()
                                            end
                                        end)
                                    end
                                end
                            end)
                        end
                    end
                end)
                
                if not success then
                    warn("Auto Cast Error: " .. tostring(err))
                end
            end
        end
    end
    
    -- Hook untuk reel finished (auto recast)
    local function onGuiRemoved(gui)
        if not autofarm.autoCastEnabled then return end
        
        if gui.Name == "reel" then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("events") then
                local castEvent = tool.events:FindFirstChild("cast")
                if castEvent then
                    local recastDelay = getRandomDelay(2, 40) -- 2±40% = 1.2-2.8 seconds
                    task.wait(recastDelay) -- Random delay sebelum recast
                    
                    local success, err = pcall(function()
                        if autofarm.castMode == 1 then
                            -- Legit mode recast - tunggu full power seperti kinghub
                            local VirtualInputManager = game:GetService("VirtualInputManager")
                            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, player, 0)
                            
                            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                            if humanoidRootPart then
                                local powerConnection
                                powerConnection = humanoidRootPart.ChildAdded:Connect(function(powerChild)
                                    if powerChild.Name == "power" then
                                        local powerbar = powerChild:FindFirstChild("powerbar")
                                        if powerbar and powerbar:FindFirstChild("bar") then
                                            local barConnection
                                            barConnection = powerbar.bar:GetPropertyChangedSignal("Size"):Connect(function()
                                                -- Release saat mencapai FULL power (100%) seperti kinghub
                                                if powerbar.bar.Size == UDim2.new(1, 0, 1, 0) then
                                                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, player, 0)
                                                    barConnection:Disconnect()
                                                    powerConnection:Disconnect()
                                                end
                                            end)
                                        end
                                    end
                                end)
                            end
                            
                        elseif autofarm.castMode == 2 then
                            -- Rage mode recast with random delay
                            local rageRecastDelay = getRandomDelay(0.3, 80) -- 0.3±80% = 0.15-0.55 seconds
                            task.wait(rageRecastDelay)
                            castEvent:FireServer(100)
                            
                        elseif autofarm.castMode == 3 then
                            -- Random mode recast - random target 85-100%
                            local VirtualInputManager = game:GetService("VirtualInputManager")
                            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, player, 0)
                            
                            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                            if humanoidRootPart then
                                local powerConnection
                                powerConnection = humanoidRootPart.ChildAdded:Connect(function(powerChild)
                                    if powerChild.Name == "power" then
                                        local powerbar = powerChild:FindFirstChild("powerbar")
                                        if powerbar and powerbar:FindFirstChild("bar") then
                                            local barConnection
                                            -- Random target antara 85-100% untuk variasi
                                            local randomTarget = math.random(85, 100) / 100
                                            barConnection = powerbar.bar:GetPropertyChangedSignal("Size"):Connect(function()
                                                if powerbar.bar.Size.X.Scale >= randomTarget then
                                                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, player, 0)
                                                    barConnection:Disconnect()
                                                    powerConnection:Disconnect()
                                                end
                                            end)
                                        end
                                    end
                                end)
                            end
                        end
                    end)
                    
                    if not success then
                        warn("Auto Cast Recast Error: " .. tostring(err))
                    end
                end
            end
        end
    end
    
    -- Connect events
    autofarm.castConnection1 = character.ChildAdded:Connect(onCharacterChildAdded)
    autofarm.castConnection2 = player.PlayerGui.ChildRemoved:Connect(onGuiRemoved)
    
    print("Auto Cast started with mode: " .. autofarm.castMode)
end

function autofarm.stopAutoCast()
    autofarm.autoCastEnabled = false
    
    -- Disconnect connections
    if autofarm.castConnection1 then
        autofarm.castConnection1:Disconnect()
        autofarm.castConnection1 = nil
    end
    if autofarm.castConnection2 then
        autofarm.castConnection2:Disconnect()
        autofarm.castConnection2 = nil
    end
    
    print("Auto Cast stopped")
end

-- Auto Shake dengan 2 mode
function autofarm.startAutoShake(mode)
    autofarm.autoShakeEnabled = true
    autofarm.shakeMode = mode or 1
    
    if autofarm.shakeMode == 1 then
        -- Mode 1: Method dari sanhub - continuous checking
        local function handleShake()
            if not autofarm.autoShakeEnabled then return end
            
            local success, err = pcall(function()
                local playerGui = player:WaitForChild("PlayerGui")
                local shakeUI = playerGui:FindFirstChild("shakeui")
                
                if shakeUI then
                    local safezone = shakeUI:FindFirstChild("safezone")
                    if safezone then
                        local button = safezone:FindFirstChild("button")
                        if button then
                            -- Add random delay even for SanHub method
                            local shakeDelay = getRandomDelay(0.05, 80) -- 0.05±80% = 0.01-0.09 seconds
                            task.wait(shakeDelay)
                            
                            -- Set selected object dan send return key
                            game:GetService("GuiService").SelectedObject = button
                            if game:GetService("GuiService").SelectedObject == button then
                                local VirtualInputManager = game:GetService("VirtualInputManager")
                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                                print("Shake performed (SanHub method)")
                            end
                        end
                    end
                end
            end)
            
            if not success then
                warn("Auto Shake Error: " .. tostring(err))
            end
        end
        
        -- Connect to RenderStepped untuk continuous checking
        autofarm.shakeConnection = RunService.RenderStepped:Connect(handleShake)
        
    elseif autofarm.shakeMode == 2 then
        -- Mode 2: Method dari neoxhub - event-driven approach
        local function onShakeUIAdded(descendant)
            if not autofarm.autoShakeEnabled then return end
            
            local success, err = pcall(function()
                -- Detect shake UI button seperti di neoxhub
                if descendant.Name == "button" and descendant.Parent and descendant.Parent.Name == "safezone" then
                    local shakeDelay = getRandomDelay(0.3, 50) -- 0.3±50% = 0.15-0.45 seconds
                    task.wait(shakeDelay) -- Random delay seperti reaksi manusia
                    
                    -- Method 1: Set SelectedObject + Return key (seperti neoxhub)
                    game:GetService("GuiService").SelectedObject = descendant
                    local VirtualInputManager = game:GetService("VirtualInputManager")
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                    
                    local cleanupDelay = getRandomDelay(0.1, 50) -- 0.1±50% = 0.05-0.15 seconds
                    task.wait(cleanupDelay)
                    game:GetService("GuiService").SelectedObject = nil
                    
                    print("Shake performed (NeoxHub event method)")
                    
                    -- Method 2: Backup dengan tool shake event
                    local tool = character:FindFirstChildOfClass("Tool")
                    if tool and tool:FindFirstChild("events") then
                        local shakeEvent = tool.events:FindFirstChild("shake")
                        if shakeEvent then
                            shakeEvent:FireServer()
                            print("Shake backup performed (Tool method)")
                        end
                    end
                end
            end)
            
            if not success then
                warn("Auto Shake NeoxHub Error: " .. tostring(err))
            end
        end
        
        -- Connect to PlayerGui.DescendantAdded seperti neoxhub
        autofarm.shakeConnection = player.PlayerGui.DescendantAdded:Connect(onShakeUIAdded)
    end
    
    print("Auto Shake started with mode: " .. autofarm.shakeMode)
end

function autofarm.stopAutoShake()
    autofarm.autoShakeEnabled = false
    
    -- Disconnect shake connection
    if autofarm.shakeConnection then
        autofarm.shakeConnection:Disconnect()
        autofarm.shakeConnection = nil
    end
    
    print("Auto Shake stopped")
end

-- Auto Reel (dari sanhub)
function autofarm.startAutoReel()
    autofarm.autoReelEnabled = true
    
    spawn(function()
        while autofarm.autoReelEnabled do
            local success, err = pcall(function()
                -- Method dari sanhub
                local playerGui = player:WaitForChild("PlayerGui")
                local reel = playerGui:FindFirstChild("reel")
                
                if reel then
                    local bar = reel:FindFirstChild("bar")
                    if bar and bar.Visible then
                        -- Auto reel ketika bar muncul
                        local reelEventDelay = getRandomDelay(0.05, 70) -- 0.05±70% = 0.015-0.085 seconds
                        task.wait(reelEventDelay)
                        
                        local reelEvent = ReplicatedStorage:FindFirstChild("events")
                        if reelEvent then
                            local reelAction = reelEvent:FindFirstChild("reelfinished")
                            if reelAction then
                                reelAction:FireServer(100, true) -- Perfect reel
                            end
                        end
                        
                        -- Alternative method - simulate space key press
                        local keyPressDelay = getRandomDelay(0.05, 60) -- 0.05±60% = 0.02-0.08 seconds
                        UserInputService:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                        wait(keyPressDelay)
                        UserInputService:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    end
                end
                
                -- Backup method - check for reel prompt
                local reelPrompt = playerGui:FindFirstChild("ReelPrompt")
                if reelPrompt and reelPrompt.Visible then
                    local promptDelay = getRandomDelay(0.08, 60) -- 0.08±60% = 0.032-0.128 seconds
                    task.wait(promptDelay)
                    
                    local reelEvent = ReplicatedStorage:FindFirstChild("events")
                    if reelEvent then
                        local reel = reelEvent:FindFirstChild("reel")
                        if reel then
                            reel:FireServer()
                        end
                    end
                end
            end)
            
            if not success then
                warn("Auto Reel Error: " .. tostring(err))
            end
            
            local loopDelay = getRandomDelay(0.1, 40) -- 0.1±40% = 0.06-0.14 seconds
            wait(loopDelay)
        end
    end)
end

function autofarm.stopAutoReel()
    autofarm.autoReelEnabled = false
end

-- Always Catch (dari sanhub)
function autofarm.startAlwaysCatch()
    autofarm.alwaysCatchEnabled = true
    
    spawn(function()
        -- Hook reelfinished event untuk always catch
        local replicatedStorage = ReplicatedStorage
        local events = replicatedStorage:WaitForChild("events")
        local reelfinished = events:WaitForChild("reelfinished")
        
        -- Store original FireServer method
        local originalFireServer = reelfinished.FireServer
        
        -- Override FireServer method
        reelfinished.FireServer = function(self, ...)
            local args = {...}
            if autofarm.alwaysCatchEnabled then
                -- Always catch dengan perfect score
                args[1] = 100  -- Perfect score
                args[2] = true -- Success flag
                print("Always Catch: Perfect catch applied!")
            end
            return originalFireServer(self, unpack(args))
        end
        
        print("Always Catch: Hook installed successfully!")
    end)
end

function autofarm.stopAlwaysCatch()
    autofarm.alwaysCatchEnabled = false
    
    -- Restore original FireServer method
    spawn(function()
        local replicatedStorage = ReplicatedStorage
        local events = replicatedStorage:FindFirstChild("events")
        if events then
            local reelfinished = events:FindFirstChild("reelfinished")
            if reelfinished then
                -- Note: Dalam implementasi nyata, kita perlu store original method
                -- Untuk sekarang, kita hanya disable flag
                print("Always Catch: Disabled")
            end
        end
    end)
end

-- Utility Functions
function autofarm.setRandomDelay(enabled)
    autofarm.randomDelayEnabled = enabled
    if enabled then
        print("Random Delay: Enabled - Human-like behavior activated")
    else
        print("Random Delay: Disabled - Fixed delays restored")
    end
    return true
end

function autofarm.setShakeMode(mode)
    if mode == 1 or mode == 2 then
        autofarm.shakeMode = mode
        return true
    else
        warn("Invalid shake mode. Use 1 (sanhub) or 2 (neoxhub)")
        return false
    end
end

function autofarm.setCastMode(mode)
    if mode == 1 or mode == 2 or mode == 3 then
        autofarm.castMode = mode
        return true
    else
        warn("Invalid cast mode. Use 1 (legit), 2 (rage), or 3 (random)")
        return false
    end
end

function autofarm.getStatus()
    return {
        autoCast = autofarm.autoCastEnabled,
        autoShake = autofarm.autoShakeEnabled,
        autoReel = autofarm.autoReelEnabled,
        alwaysCatch = autofarm.alwaysCatchEnabled,
        randomDelay = autofarm.randomDelayEnabled,
        shakeMode = autofarm.shakeMode,
        castMode = autofarm.castMode
    }
end

-- Start all autofarm features
function autofarm.startAll(shakeMode, castMode)
    shakeMode = shakeMode or 1
    castMode = castMode or 1
    autofarm.startAutoCast(castMode)
    autofarm.startAutoShake(shakeMode)
    autofarm.startAutoReel()
    autofarm.startAlwaysCatch()
end

-- Stop all autofarm features
function autofarm.stopAll()
    autofarm.stopAutoCast()
    autofarm.stopAutoShake()
    autofarm.stopAutoReel()
    autofarm.stopAlwaysCatch()
end

-- Error handling dan reconnection
local function handleCharacterRespawn()
    player.CharacterAdded:Connect(function(newCharacter)
        character = newCharacter
        humanoid = character:WaitForChild("Humanoid")
        
        -- Restart autofarm jika sedang aktif
        local status = autofarm.getStatus()
        if status.autoCast or status.autoShake or status.autoReel or status.alwaysCatch then
            local respawnDelay = getRandomDelay(2, 25) -- 2±25% = 1.5-2.5 seconds
            wait(respawnDelay) -- Random wait for character to load
            if status.autoCast then autofarm.startAutoCast(status.castMode) end
            if status.autoShake then autofarm.startAutoShake(status.shakeMode) end
            if status.autoReel then autofarm.startAutoReel() end
            if status.alwaysCatch then autofarm.startAlwaysCatch() end
        end
    end)
end

-- Initialize
handleCharacterRespawn()

return autofarm