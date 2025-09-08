-- SUPER HUB Simple Loader (Error-Safe Version)
-- Versi yang lebih stabil dengan error handling yang lebih baik

print("=================================")
print("   SUPER HUB - Loading...")
print("   Version: 1.0 (Stable)")
print("=================================")

-- Safer script loading function
local function safeLoadString(code, name)
    local success, result = pcall(function()
        return loadstring(code)
    end)
    
    if not success then
        warn("Failed to parse " .. name .. ": " .. tostring(result))
        return nil
    end
    
    local executeSuccess, executeResult = pcall(result)
    if not executeSuccess then
        warn("Failed to execute " .. name .. ": " .. tostring(executeResult))
        return nil
    end
    
    return executeResult
end

-- Safer HTTP request function
local function safeHttpGet(url, name)
    -- Try multiple methods
    local methods = {
        function() return game:GetService("HttpService"):GetAsync(url) end,
        function() return game:HttpGet(url) end
    }
    
    for i, method in ipairs(methods) do
        local success, result = pcall(method)
        if success and result and #result > 0 then
            print("✓ " .. name .. " loaded via method " .. i)
            return result
        end
    end
    
    warn("✗ Failed to load " .. name .. " from " .. url)
    return nil
end

-- Load autofarm module
print("Loading autofarm module...")
local autofarmCode = safeHttpGet(
    "https://raw.githubusercontent.com/donitono/spinnerxxxHUB/main/Modules/autofarm.lua",
    "Autofarm Module"
)

if not autofarmCode then
    error("Failed to load autofarm module")
end

local autofarm = safeLoadString(autofarmCode, "Autofarm Module")
if not autofarm then
    error("Failed to initialize autofarm module")
end

print("✓ Autofarm module loaded successfully")

-- Create simple UI (fallback method)
print("Creating user interface...")

-- Simple notification-based UI
local function createNotification(title, text)
    local success, err = pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title;
            Text = text;
            Duration = 3;
        })
    end)
    if not success then
        print(title .. ": " .. text)
    end
end

-- Basic controls via chat commands
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Create floating button for UI control
local function createUIFloatingButton()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SimpleLoaderFloatingButton"
    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 50, 0, 50)
    frame.Position = UDim2.new(1, -70, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    frame.Active = true
    frame.Draggable = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = frame
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 50))
    })
    gradient.Rotation = 45
    gradient.Parent = frame
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = "SL"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.Parent = frame
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        local tween = TweenService:Create(frame, 
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 60, 0, 60)}
        )
        tween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local tween = TweenService:Create(frame,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 50, 0, 50)}
        )
        tween:Play()
    end)
    
    -- Show controls when clicked
    local controlsVisible = false
    button.MouseButton1Click:Connect(function()
        if not controlsVisible then
            createSimpleControls()
            controlsVisible = true
            
            -- Change button appearance
            button.Text = "✕"
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 150, 50)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 25))
            })
        else
            -- Hide controls
            local controlGui = player.PlayerGui:FindFirstChild("SimpleLoaderControls")
            if controlGui then
                controlGui:Destroy()
            end
            controlsVisible = false
            
            -- Reset button appearance
            button.Text = "SL"
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 50))
            })
        end
    end)
    
    return screenGui
end

-- Create simple control panel
local function createSimpleControls()
    -- Remove existing controls
    local existingGui = player.PlayerGui:FindFirstChild("SimpleLoaderControls")
    if existingGui then
        existingGui:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SimpleLoaderControls"
    screenGui.Parent = player.PlayerGui
    screenGui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 400)
    frame.Position = UDim2.new(0.5, -150, 0.5, -200)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "Simple Loader Controls"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -60)
    scrollFrame.Position = UDim2.new(0, 10, 0, 50)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = frame
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = scrollFrame
    
    -- Add control buttons
    local controlButtons = {
        {text = "Start All Autofarm", cmd = "startall"},
        {text = "Stop All Autofarm", cmd = "stopall"},
        {text = "Toggle Auto Cast", cmd = "autocast"},
        {text = "Toggle Auto Shake", cmd = "autoshake"},
        {text = "Toggle Auto Reel", cmd = "autoreel"},
        {text = "Toggle Always Catch", cmd = "alwayscatch"},
        {text = "Toggle Random Delay", cmd = "randomdelay"},
        {text = "Enable Advanced Reel", cmd = "advancedreel"},
        {text = "Check Status", cmd = "status"}
    }
    
    for _, buttonData in ipairs(controlButtons) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 35)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        button.BorderSizePixel = 0
        button.Text = buttonData.text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Font = Enum.Font.Gotham
        button.Parent = scrollFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 5)
        buttonCorner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            handleChatCommand("/" .. buttonData.cmd)
        end)
        
        -- Hover effect
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end)
    end
    
    -- Update scroll canvas size
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
    end)
end

-- Chat command handler
local function setupChatCommands()
    local success, err = pcall(function()
        player.Chatted:Connect(function(message)
            local msg = message:lower()
            
            if msg == "/superhub" or msg == "/help" then
                print("=== SUPER HUB Commands ===")
                print("/autocast - Toggle auto cast")
                print("/autoshake - Toggle auto shake") 
                print("/autoreel - Toggle auto reel")
                print("/alwayscatch - Toggle always catch")
                print("/randomdelay - Toggle random delay")
                print("/startall - Start all features")
                print("/stopall - Stop all features")
                print("/status - Show status")
                print("--- Advanced Reel ---")
                print("/reeldebug - Toggle reel debug mode")
                print("/analyze - Analyze current reel")
                print("/testreel - Test reel input")
                print("========================")
                
            elseif msg == "/autocast" then
                if autofarm.autoCastEnabled then
                    autofarm.stopAutoCast()
                    createNotification("Auto Cast", "Disabled")
                else
                    autofarm.startAutoCast(1)
                    createNotification("Auto Cast", "Enabled (Mode 1)")
                end
                
            elseif msg == "/autoshake" then
                if autofarm.autoShakeEnabled then
                    autofarm.stopAutoShake()
                    createNotification("Auto Shake", "Disabled")
                else
                    autofarm.startAutoShake(1)
                    createNotification("Auto Shake", "Enabled (Mode 1)")
                end
                
            elseif msg == "/autoreel" then
                if autofarm.autoReelEnabled then
                    autofarm.stopAutoReel()
                    createNotification("Auto Reel", "Disabled")
                else
                    autofarm.startAutoReel()
                    createNotification("Auto Reel", "Enabled")
                end
                
            elseif msg == "/alwayscatch" then
                if autofarm.alwaysCatchEnabled then
                    autofarm.stopAlwaysCatch()
                    createNotification("Always Catch", "Disabled")
                else
                    autofarm.startAlwaysCatch()
                    createNotification("Always Catch", "Enabled")
                end
                
            elseif msg == "/randomdelay" then
                if autofarm.randomDelayEnabled then
                    autofarm.setRandomDelay(false)
                    createNotification("Random Delay", "Disabled")
                else
                    autofarm.setRandomDelay(true)
                    createNotification("Random Delay", "Enabled")
                end
                
            elseif msg == "/startall" then
                autofarm.startAll(1, 1)
                autofarm.setRandomDelay(true)
                createNotification("SUPER HUB", "All features enabled!")
                
            elseif msg == "/stopall" then
                autofarm.stopAll()
                createNotification("SUPER HUB", "All features disabled!")
                
            elseif msg == "/status" then
                local status = autofarm.getStatus()
                print("=== SUPER HUB Status ===")
                print("Auto Cast: " .. tostring(status.autoCast))
                print("Auto Shake: " .. tostring(status.autoShake))
                print("Auto Reel: " .. tostring(status.autoReel))
                print("Always Catch: " .. tostring(status.alwaysCatch))
                print("Random Delay: " .. tostring(status.randomDelay))
                print("Cast Mode: " .. tostring(status.castMode))
                print("Shake Mode: " .. tostring(status.shakeMode))
                print("=======================")
                createNotification("Status", "Check console for details")
                
            elseif msg == "/reeldebug" then
                if autofarm.setReelDebugMode then
                    local currentState = autofarm.advancedReel and autofarm.advancedReel.debugMode or false
                    autofarm.setReelDebugMode(not currentState)
                    createNotification("Reel Debug", (not currentState) and "Enabled" or "Disabled")
                else
                    createNotification("Error", "Advanced reel not available")
                end
                
            elseif msg == "/analyze" then
                if autofarm.analyzeCurrentReel then
                    autofarm.analyzeCurrentReel()
                    createNotification("Reel Analysis", "Check console for details")
                else
                    createNotification("Error", "Advanced reel not available")
                end
                
            elseif msg == "/advancedreel" then
                if autofarm.autoReelEnabled then
                    autofarm.stopAutoReel()
                    createNotification("Advanced Reel", "Disabled")
                else
                    autofarm.startAutoReel()
                    createNotification("Advanced Reel", "Enabled with human behavior")
                end
            end
        end)
    end)
    
    if success then
        print("✓ Chat commands initialized")
    else
        warn("Chat commands failed: " .. tostring(err))
    end
end

-- Chat command handler function (for button integration)
local function handleChatCommand(message)
    local msg = message:lower()
    
    if msg == "/superhub" or msg == "/help" then
        print("=== SUPER HUB Commands ===")
        print("/autocast - Toggle auto cast")
        print("/autoshake - Toggle auto shake") 
        print("/autoreel - Toggle auto reel")
        print("/alwayscatch - Toggle always catch")
        print("/randomdelay - Toggle random delay")
        print("/startall - Start all features")
        print("/stopall - Stop all features")
        print("/status - Show status")
        print("--- Advanced Reel ---")
        print("/reeldebug - Toggle reel debug mode")
        print("/analyze - Analyze current reel")
        print("/testreel - Test reel input")
        print("========================")
        
    elseif msg == "/autocast" then
        if autofarm.autoCastEnabled then
            autofarm.stopAutoCast()
            createNotification("Auto Cast", "Disabled")
        else
            autofarm.startAutoCast(1)
            createNotification("Auto Cast", "Enabled (Mode 1)")
        end
        
    elseif msg == "/autoshake" then
        if autofarm.autoShakeEnabled then
            autofarm.stopAutoShake()
            createNotification("Auto Shake", "Disabled")
        else
            autofarm.startAutoShake(1)
            createNotification("Auto Shake", "Enabled (Mode 1)")
        end
        
    elseif msg == "/autoreel" then
        if autofarm.autoReelEnabled then
            autofarm.stopAutoReel()
            createNotification("Auto Reel", "Disabled")
        else
            autofarm.startAutoReel()
            createNotification("Auto Reel", "Enabled")
        end
        
    elseif msg == "/alwayscatch" then
        if autofarm.alwaysCatchEnabled then
            autofarm.stopAlwaysCatch()
            createNotification("Always Catch", "Disabled")
        else
            autofarm.startAlwaysCatch()
            createNotification("Always Catch", "Enabled")
        end
        
    elseif msg == "/randomdelay" then
        local currentState = autofarm.getStatus().randomDelay
        autofarm.setRandomDelay(not currentState)
        createNotification("Random Delay", (not currentState) and "Enabled" or "Disabled")
        
    elseif msg == "/startall" then
        autofarm.startAll(1, 1) -- Default modes
        createNotification("Autofarm", "All features enabled")
        
    elseif msg == "/stopall" then
        autofarm.stopAll()
        createNotification("Autofarm", "All features disabled")
        
    elseif msg == "/status" then
        local status = autofarm.getStatus()
        print("=== Autofarm Status ===")
        print("Auto Cast: " .. tostring(status.autoCast))
        print("Auto Shake: " .. tostring(status.autoShake))
        print("Auto Reel: " .. tostring(status.autoReel))
        print("Always Catch: " .. tostring(status.alwaysCatch))
        print("Random Delay: " .. tostring(status.randomDelay))
        print("Cast Mode: " .. tostring(status.castMode))
        print("Shake Mode: " .. tostring(status.shakeMode))
        print("=======================")
        createNotification("Status", "Check console for details")
        
    elseif msg == "/reeldebug" then
        if autofarm.setReelDebugMode then
            local currentState = autofarm.advancedReel and autofarm.advancedReel.debugMode or false
            autofarm.setReelDebugMode(not currentState)
            createNotification("Reel Debug", (not currentState) and "Enabled" or "Disabled")
        else
            createNotification("Error", "Advanced reel not available")
        end
        
    elseif msg == "/analyze" then
        if autofarm.analyzeCurrentReel then
            autofarm.analyzeCurrentReel()
            createNotification("Reel Analysis", "Check console for details")
        else
            createNotification("Error", "Advanced reel not available")
        end
        
    elseif msg == "/testreel" then
        if autofarm.advancedReel and autofarm.advancedReel.test then
            autofarm.advancedReel.test()
            createNotification("Reel Test", "Input simulation test performed")
        else
            createNotification("Error", "Advanced reel not available")
        end
        
    elseif msg == "/advancedreel" then
        if autofarm.autoReelEnabled then
            autofarm.stopAutoReel()
            createNotification("Advanced Reel", "Disabled")
        else
            autofarm.startAutoReel()
            createNotification("Advanced Reel", "Enabled with human behavior")
        end
    end
end

-- Initialize
setupChatCommands()

-- Create floating button
createUIFloatingButton()

-- Success message
print("=================================")
print("   SUPER HUB LOADED SUCCESSFULLY!")
print("   Type /superhub for commands")
print("   Click floating button for GUI")
print("   Created by: donitono")
print("=================================")

createNotification("SUPER HUB v1.0", "Loaded! Click floating button or type /superhub")

-- Return autofarm for external access
return autofarm
