-- SUPER HUB Main Loader
-- Memuat semua module dan UI secara online
-- Created by: donitono
-- Version: 1.0

-- Script Information
local SCRIPT_INFO = {
    name = "SUPER HUB",
    version = "1.0",
    author = "donitono",
    repository = "https://github.com/donitono/spinnerxxxHUB",
    discord = "https://discord.gg/superhub"
}

-- Online URLs untuk loading script
local URLS = {
    -- URLs GitHub repository Anda
    autofarm = "https://raw.githubusercontent.com/donitono/spinnerxxxHUB/main/Modules/autofarm.lua",
    kavo = "https://raw.githubusercontent.com/donitono/spinnerxxxHUB/main/kavo.lua",
    -- URL fallback jika ada masalah
    fallback_autofarm = "https://raw.githubusercontent.com/donitono/spinnerxxxHUB/main/Modules/autofarm.lua",
    fallback_kavo = "https://raw.githubusercontent.com/donitono/spinnerxxxHUB/main/kavo.lua"
}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Variables
local player = Players.LocalPlayer

-- Loading UI
local function createLoadingUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SuperHubLoader"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(0.5, -150, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = SCRIPT_INFO.name .. " v" .. SCRIPT_INFO.version
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 30)
    status.Position = UDim2.new(0, 0, 0, 60)
    status.BackgroundTransparency = 1
    status.Text = "Initializing..."
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.TextScaled = true
    status.Font = Enum.Font.Gotham
    status.Parent = frame
    
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0.8, 0, 0, 8)
    progressBar.Position = UDim2.new(0.1, 0, 0, 100)
    progressBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = frame
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 4)
    progressCorner.Parent = progressBar
    
    local progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.Position = UDim2.new(0, 0, 0, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBar
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = progressFill
    
    local credits = Instance.new("TextLabel")
    credits.Size = UDim2.new(1, 0, 0, 20)
    credits.Position = UDim2.new(0, 0, 0, 120)
    credits.BackgroundTransparency = 1
    credits.Text = "Created by " .. SCRIPT_INFO.author
    credits.TextColor3 = Color3.fromRGB(150, 150, 150)
    credits.TextScaled = true
    credits.Font = Enum.Font.Gotham
    credits.Parent = frame
    
    return {
        gui = screenGui,
        status = status,
        progressFill = progressFill
    }
end

-- Update loading progress
local function updateProgress(ui, progress, statusText)
    ui.status.Text = statusText
    local tween = TweenService:Create(
        ui.progressFill,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(progress, 0, 1, 0)}
    )
    tween:Play()
end

-- Load script from URL with error handling
local function loadScriptFromURL(url, fallbackUrl, scriptName)
    local success, result = pcall(function()
        return game:GetService("HttpService"):GetAsync(url)
    end)
    
    if not success then
        warn("Failed to load " .. scriptName .. " from primary URL: " .. tostring(result))
        
        -- Try alternative HttpGet method
        success, result = pcall(function()
            return game:HttpGet(url)
        end)
        
        if not success and fallbackUrl then
            warn("Trying fallback URL...")
            success, result = pcall(function()
                return game:HttpGet(fallbackUrl)
            end)
        end
        
        if not success then
            error("Failed to load " .. scriptName .. ": " .. tostring(result))
        end
    end
    
    return result
end

-- Main loading function
local function loadSuperHub()
    print("=================================")
    print("     SUPER HUB v" .. SCRIPT_INFO.version)
    print("     Loading script components...")
    print("=================================")
    
    local loadingUI = createLoadingUI()
    
    -- Step 1: Load Autofarm Module
    updateProgress(loadingUI, 0.2, "Loading autofarm module...")
    wait(0.5)
    
    local autofarm
    local success, err = pcall(function()
        if game:GetService("RunService"):IsStudio() then
            -- Local development mode - load from file
            warn("Studio mode detected - using local fallback")
            autofarm = require(script.Parent.Modules.autofarm)
        else
            -- Online mode - load from GitHub
            print("Loading autofarm module from GitHub...")
            local autofarmScript = loadScriptFromURL(
                URLS.autofarm,
                URLS.fallback_autofarm,
                "Autofarm Module"
            )
            autofarm = loadstring(autofarmScript)()
        end
    end)
    
    if not success then
        updateProgress(loadingUI, 0.2, "Failed to load autofarm!")
        warn("Autofarm loading error: " .. tostring(err))
        wait(2)
        loadingUI.gui:Destroy()
        return false
    end
    
    updateProgress(loadingUI, 0.5, "Autofarm module loaded!")
    print("✓ Autofarm module loaded successfully")
    
    -- Step 2: Load Kavo UI Library
    updateProgress(loadingUI, 0.7, "Loading Kavo UI library...")
    wait(0.5)
    
    local Library
    success, err = pcall(function()
        if game:GetService("RunService"):IsStudio() then
            -- Local development mode - create basic fallback UI
            warn("Studio mode detected - using basic UI fallback")
            Library = createBasicUI()
        else
            -- Online mode - try to load Kavo library
            print("Loading Kavo UI library...")
            
            -- Try multiple Kavo library sources
            local kavoSources = {
                "https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua",
                "https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/kavo",
                URLS.kavo -- Our custom kavo if available
            }
            
            local kavoLoaded = false
            for i, kavoUrl in ipairs(kavoSources) do
                local kavoSuccess, kavoResult = pcall(function()
                    return game:HttpGet(kavoUrl)
                end)
                
                if kavoSuccess then
                    local librarySuccess, libraryResult = pcall(function()
                        return loadstring(kavoResult)()
                    end)
                    
                    if librarySuccess then
                        Library = libraryResult
                        kavoLoaded = true
                        print("✓ Kavo loaded from source " .. i)
                        break
                    end
                end
            end
            
            if not kavoLoaded then
                warn("Failed to load Kavo library, using basic fallback")
                Library = createBasicUI()
            end
        end
    end)
    
    if not success then
        updateProgress(loadingUI, 0.7, "Failed to load Kavo UI!")
        warn("Kavo UI loading error: " .. tostring(err))
        -- Try to continue with basic UI fallback
        print("Continuing with basic UI fallback...")
    end
    
    updateProgress(loadingUI, 0.9, "Building user interface...")
    print("✓ Kavo UI library loaded successfully")
    
    -- Step 3: Create UI
    wait(0.5)
    success, err = pcall(function()
        createMainUI(Library, autofarm)
    end)
    
    if not success then
        updateProgress(loadingUI, 0.9, "Failed to create UI!")
        warn("UI creation error: " .. tostring(err))
        wait(2)
        loadingUI.gui:Destroy()
        return false
    end
    
    -- Step 4: Complete
    updateProgress(loadingUI, 1.0, "Loaded successfully!")
    wait(1)
    loadingUI.gui:Destroy()
    
    print("=================================")
    print("    SUPER HUB v" .. SCRIPT_INFO.version .. " LOADED!")
    print("    Status: Ready for use!")
    print("    Repository: " .. SCRIPT_INFO.repository)
    print("=================================")
    
    return true
end

-- Create floating button for minimized state
local function createFloatingButton(restoreCallback)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SuperHubFloatingButton"
    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 60, 0, 60)
    frame.Position = UDim2.new(1, -80, 0.5, -30)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    frame.Active = true
    frame.Draggable = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 30)
    corner.Parent = frame
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 162, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 120, 200))
    })
    gradient.Rotation = 45
    gradient.Parent = frame
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = "SH"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.Parent = frame
    
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 4, 1, 4)
    shadow.Position = UDim2.new(0, -2, 0, 2)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.5
    shadow.ZIndex = frame.ZIndex - 1
    shadow.Parent = frame
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 30)
    shadowCorner.Parent = shadow
    
    -- Hover effects
    local isHovering = false
    
    button.MouseEnter:Connect(function()
        isHovering = true
        local tween = TweenService:Create(frame, 
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 70, 0, 70)}
        )
        tween:Play()
        
        button.Text = "SUPER\nHUB"
        button.TextScaled = false
        button.TextSize = 8
    end)
    
    button.MouseLeave:Connect(function()
        isHovering = false
        wait(0.1)
        if not isHovering then
            local tween = TweenService:Create(frame,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 60, 0, 60)}
            )
            tween:Play()
            
            button.Text = "SH"
            button.TextScaled = true
        end
    end)
    
    button.MouseButton1Click:Connect(function()
        -- Animate button click
        local clickTween = TweenService:Create(frame,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {Size = UDim2.new(0, 55, 0, 55)}
        )
        clickTween:Play()
        
        clickTween.Completed:Connect(function()
            local returnTween = TweenService:Create(frame,
                TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 60, 0, 60)}
            )
            returnTween:Play()
        end)
        
        -- Restore UI
        if restoreCallback then
            restoreCallback()
        end
        screenGui:Destroy()
    end)
    
    -- Notification
    spawn(function()
        wait(2)
        local notification = Instance.new("TextLabel")
        notification.Size = UDim2.new(0, 150, 0, 30)
        notification.Position = UDim2.new(0, -155, 0.5, -15)
        notification.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        notification.BackgroundTransparency = 0.1
        notification.BorderSizePixel = 0
        notification.Text = "Click to restore UI"
        notification.TextColor3 = Color3.fromRGB(255, 255, 255)
        notification.TextScaled = true
        notification.Font = Enum.Font.Gotham
        notification.Parent = frame
        
        local notifCorner = Instance.new("UICorner")
        notifCorner.CornerRadius = UDim.new(0, 5)
        notifCorner.Parent = notification
        
        -- Fade in notification
        notification.BackgroundTransparency = 1
        notification.TextTransparency = 1
        
        local fadeIn = TweenService:Create(notification,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.1, TextTransparency = 0}
        )
        fadeIn:Play()
        
        -- Fade out after 3 seconds
        wait(3)
        local fadeOut = TweenService:Create(notification,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1, TextTransparency = 1}
        )
        fadeOut:Play()
        
        fadeOut.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
    
    return screenGui
end

-- Create main UI function
function createMainUI(Library, autofarm)
    -- Create Main Window
    local Window = Library.CreateLib("SUPER HUB v" .. SCRIPT_INFO.version, "DarkTheme")
    
    -- Store window reference for minimize/restore
    local isMinimized = false
    local windowGui = nil
    
    -- Find the main window GUI
    spawn(function()
        wait(1) -- Wait for UI to be created
        for _, gui in pairs(Players.LocalPlayer.PlayerGui:GetChildren()) do
            if gui.Name:lower():find("kavo") or gui.Name:lower():find("lib") then
                windowGui = gui
                break
            end
        end
    end)
    
    -- Autofarm Tab
    local AutofarmTab = Window:NewTab("🎣 Autofarm")
    local AutofarmSection = AutofarmTab:NewSection("Fishing Automation")
    
    -- Cast Mode Selection
    local currentCastMode = 1
    AutofarmSection:NewDropdown("Cast Mode", "Select auto cast mode", {
        "Mode 1 (Legit - Perfect)", 
        "Mode 2 (Rage - Instant)", 
        "Mode 3 (Random - Variable)"
    }, function(option)
        if option == "Mode 1 (Legit - Perfect)" then
            currentCastMode = 1
        elseif option == "Mode 2 (Rage - Instant)" then
            currentCastMode = 2
        elseif option == "Mode 3 (Random - Variable)" then
            currentCastMode = 3
        end
        autofarm.setCastMode(currentCastMode)
        print("Cast Mode changed to: " .. currentCastMode)
    end)
    
    -- Auto Cast Toggle
    AutofarmSection:NewToggle("Auto Cast", "Automatically cast fishing rod", function(state)
        if state then
            autofarm.startAutoCast(currentCastMode)
            print("Auto Cast: Enabled (Mode " .. currentCastMode .. ")")
        else
            autofarm.stopAutoCast()
            print("Auto Cast: Disabled")
        end
    end)
    
    -- Shake Mode Selection
    local currentShakeMode = 1
    AutofarmSection:NewDropdown("Shake Mode", "Select auto shake mode", {
        "Mode 1 (SanHub)", 
        "Mode 2 (NeoxHub)"
    }, function(option)
        if option == "Mode 1 (SanHub)" then
            currentShakeMode = 1
        elseif option == "Mode 2 (NeoxHub)" then
            currentShakeMode = 2
        end
        autofarm.setShakeMode(currentShakeMode)
        print("Shake Mode changed to: " .. currentShakeMode)
    end)
    
    -- Auto Shake Toggle
    AutofarmSection:NewToggle("Auto Shake", "Automatically shake when needed", function(state)
        if state then
            autofarm.startAutoShake(currentShakeMode)
            print("Auto Shake: Enabled (Mode " .. currentShakeMode .. ")")
        else
            autofarm.stopAutoShake()
            print("Auto Shake: Disabled")
        end
    end)
    
    -- Auto Reel Toggle
    AutofarmSection:NewToggle("Auto Reel", "Automatically complete reel minigame like human", function(state)
        if state then
            autofarm.startAutoReel()
            print("Auto Reel: Enabled (Advanced minigame automation)")
        else
            autofarm.stopAutoReel()
            print("Auto Reel: Disabled")
        end
    end)
    
    -- Advanced Reel Controls Section
    local AdvancedReelSection = AutofarmTab:NewSection("Advanced Reel Controls")
    
    AdvancedReelSection:NewToggle("Reel Debug Mode", "Show detailed reel automation logs", function(state)
        autofarm.setReelDebugMode(state)
        print("Reel Debug Mode: " .. (state and "Enabled" or "Disabled"))
    end)
    
    AdvancedReelSection:NewButton("Analyze Current Reel", "Analyze active reel minigame", function()
        autofarm.analyzeCurrentReel()
    end)
    
    AdvancedReelSection:NewButton("Test Reel Input", "Test reel input simulation", function()
        if autofarm.advancedReel then
            autofarm.advancedReel.test()
        else
            print("Advanced reel not available")
        end
    end)
    
    -- Always Catch Toggle
    AutofarmSection:NewToggle("Always Catch", "Never miss a fish - perfect catch every time", function(state)
        if state then
            autofarm.startAlwaysCatch()
            print("Always Catch: Enabled")
        else
            autofarm.stopAlwaysCatch()
            print("Always Catch: Disabled")
        end
    end)
    
    -- Random Delay Toggle (NEW)
    AutofarmSection:NewToggle("Random Delay", "Enable human-like random delays for anti-detection", function(state)
        autofarm.setRandomDelay(state)
        if state then
            print("Random Delay: Enabled - All delays now randomized")
            print("Cast: 1.4-2.6s | Shake: 0.15-0.45s | Reel: 0.06-0.14s")
        else
            print("Random Delay: Disabled - Fixed delays restored")
        end
    end)
    
    -- Quick Actions Section
    local QuickSection = AutofarmTab:NewSection("Quick Actions")
    
    QuickSection:NewButton("Start All Autofarm", "Enable all autofarm features", function()
        autofarm.startAll(currentShakeMode, currentCastMode)
        print("All Autofarm Features: Enabled")
        print("Cast Mode: " .. currentCastMode .. ", Shake Mode: " .. currentShakeMode)
    end)
    
    QuickSection:NewButton("Stop All Autofarm", "Disable all autofarm features", function()
        autofarm.stopAll()
        print("All Autofarm Features: Disabled")
    end)
    
    QuickSection:NewButton("Check Status", "Show current autofarm status", function()
        local status = autofarm.getStatus()
        print("=== Autofarm Status ===")
        print("Auto Cast: " .. tostring(status.autoCast))
        print("Auto Shake: " .. tostring(status.autoShake))
        print("Auto Reel: " .. tostring(status.autoReel))
        print("Always Catch: " .. tostring(status.alwaysCatch))
        print("Random Delay: " .. tostring(status.randomDelay))
        print("Cast Mode: " .. tostring(status.castMode))
        print("Shake Mode: " .. tostring(status.shakeMode))
        print("=====================")
    end)
    
    -- Player Tab
    local PlayerTab = Window:NewTab("👤 Player")
    local PlayerSection = PlayerTab:NewSection("Player Modifications")
    
    -- Player Speed
    PlayerSection:NewSlider("Walkspeed", "Change player walkspeed", 500, 16, function(value)
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = value
            print("Walkspeed set to: " .. value)
        end
    end)
    
    -- Jump Power
    PlayerSection:NewSlider("Jump Power", "Change player jump power", 200, 50, function(value)
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.JumpPower = value
            print("Jump Power set to: " .. value)
        end
    end)
    
    -- Infinite Oxygen
    PlayerSection:NewToggle("Infinite Oxygen", "Never run out of oxygen", function(state)
        spawn(function()
            while state do
                local character = player.Character
                if character then
                    local oxygen = character:FindFirstChild("Oxygen")
                    if oxygen then
                        oxygen.Value = 100
                    end
                end
                wait(1)
            end
        end)
        print("Infinite Oxygen: " .. tostring(state))
    end)
    
    -- Teleports Tab
    local TeleportTab = Window:NewTab("🚀 Teleports")
    local TeleportSection = TeleportTab:NewSection("Zone Teleports")
    
    -- Common fishing zones
    local zones = {
        ["Spawn"] = Vector3.new(0, 5, 0),
        ["Ocean"] = Vector3.new(1000, 5, 1000),
        ["Lake"] = Vector3.new(-500, 5, 500),
        ["River"] = Vector3.new(200, 5, -300),
        ["Deep Sea"] = Vector3.new(2000, -50, 2000)
    }
    
    for zoneName, position in pairs(zones) do
        TeleportSection:NewButton("Teleport to " .. zoneName, "Teleport to " .. zoneName, function()
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = CFrame.new(position)
                print("Teleported to: " .. zoneName)
            else
                warn("Character or HumanoidRootPart not found!")
            end
        end)
    end
    
    -- Credits Tab
    local CreditsTab = Window:NewTab("ℹ️ Credits")
    local CreditsSection = CreditsTab:NewSection("Script Information")
    
    CreditsSection:NewLabel("SUPER HUB v" .. SCRIPT_INFO.version)
    CreditsSection:NewLabel("Created by: " .. SCRIPT_INFO.author)
    CreditsSection:NewLabel("UI Library: Kavo")
    CreditsSection:NewLabel("GitHub: " .. SCRIPT_INFO.repository)
    
    CreditsSection:NewButton("Copy Discord", "Copy Discord invite", function()
        if setclipboard then
            setclipboard(SCRIPT_INFO.discord)
            print("Discord link copied to clipboard!")
        else
            print("Discord: " .. SCRIPT_INFO.discord)
        end
    end)
    
    CreditsSection:NewButton("Copy GitHub", "Copy GitHub repository", function()
        if setclipboard then
            setclipboard(SCRIPT_INFO.repository)
            print("GitHub link copied to clipboard!")
        else
            print("GitHub: " .. SCRIPT_INFO.repository)
        end
    end)
    
    -- UI Control Section
    local UIControlSection = CreditsTab:NewSection("UI Control")
    
    UIControlSection:NewButton("Minimize UI", "Hide UI and show floating button", function()
        if not isMinimized and windowGui then
            isMinimized = true
            
            -- Hide main window with animation
            local hideTween = TweenService:Create(windowGui,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                {
                    Size = UDim2.new(0, 0, 0, 0),
                    Position = UDim2.new(0.5, 0, 0.5, 0)
                }
            )
            hideTween:Play()
            
            hideTween.Completed:Connect(function()
                windowGui.Enabled = false
                
                -- Create floating button
                createFloatingButton(function()
                    if windowGui then
                        windowGui.Enabled = true
                        isMinimized = false
                        
                        -- Restore window with animation
                        local showTween = TweenService:Create(windowGui,
                            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {
                                Size = UDim2.new(0, 500, 0, 400), -- Adjust size as needed
                                Position = UDim2.new(0.5, -250, 0.5, -200)
                            }
                        )
                        showTween:Play()
                        
                        print("SUPER HUB UI restored!")
                    end
                end)
            end)
            
            print("SUPER HUB UI minimized - Click floating button to restore")
        else
            print("UI is already minimized or not found")
        end
    end)
    
    UIControlSection:NewButton("Reset UI Position", "Reset UI to center of screen", function()
        if windowGui then
            local resetTween = TweenService:Create(windowGui,
                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Position = UDim2.new(0.5, -250, 0.5, -200)
                }
            )
            resetTween:Play()
            print("UI position reset to center")
        end
    end)
end

-- Basic UI fallback function
local function createBasicUI()
    return {
        CreateLib = function(name, theme)
            print("Creating basic UI: " .. name)
            return {
                NewTab = function(tabName)
                    print("Tab created: " .. tabName)
                    return {
                        NewSection = function(sectionName)
                            print("Section created: " .. sectionName)
                            return {
                                NewToggle = function(name, desc, callback)
                                    print("Toggle: " .. name .. " (Default: false)")
                                    if callback then callback(false) end
                                end,
                                NewButton = function(name, desc, callback)
                                    print("Button: " .. name)
                                    -- Auto-trigger for testing
                                    if name:find("Status") and callback then
                                        spawn(function()
                                            wait(1)
                                            callback()
                                        end)
                                    end
                                end,
                                NewSlider = function(name, desc, max, min, callback)
                                    print("Slider: " .. name .. " (Default: " .. min .. ")")
                                    if callback then callback(min) end
                                end,
                                NewDropdown = function(name, desc, options, callback)
                                    print("Dropdown: " .. name .. " (Default: " .. (options[1] or "None") .. ")")
                                    if callback and options[1] then callback(options[1]) end
                                end,
                                NewTextBox = function(name, desc, callback)
                                    print("TextBox: " .. name)
                                    if callback then callback("") end
                                end,
                                NewLabel = function(text)
                                    print("Label: " .. text)
                                end
                            }
                        end
                    }
                end
            }
        end
    }
end

-- Error handling wrapper
local function safeExecute(func, errorMessage)
    local success, err = pcall(func)
    if not success then
        warn(errorMessage .. ": " .. tostring(err))
        return false
    end
    return true
end

-- Anti-detection measures
local function setupAntiDetection()
    -- Safer HttpGet hook
    local success, err = pcall(function()
        local HttpService = game:GetService("HttpService")
        if HttpService and HttpService.GetAsync then
            print("✓ HttpService available")
        end
        
        -- Only hook if necessary
        if game.HttpGet then
            local oldHttpGet = game.HttpGet
            game.HttpGet = function(self, url, ...)
                if url and url:find("spinnerxxxHUB") then
                    print("Loading from: " .. url)
                end
                return oldHttpGet(self, url, ...)
            end
        end
    end)
    
    if not success then
        warn("Anti-detection setup failed: " .. tostring(err))
    end
end

-- Initialize anti-detection
setupAntiDetection()

-- Main execution with comprehensive error handling
spawn(function()
    local function executeWithFallback()
        -- Try main loading
        local success = safeExecute(loadSuperHub, "Failed to load SUPER HUB")
        
        if not success then
            warn("Main loading failed, trying emergency fallback...")
            
            -- Emergency fallback - basic functionality only
            local success2, err2 = pcall(function()
                print("=== EMERGENCY MODE ===")
                print("SUPER HUB - Basic Mode")
                print("Some features may be limited")
                print("======================")
                
                -- Try to provide basic notification
                if game:GetService("StarterGui") then
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "SUPER HUB - Emergency Mode";
                        Text = "Loaded in basic mode. Check console for details.";
                        Duration = 5;
                    })
                end
            end)
            
            if not success2 then
                warn("Emergency fallback also failed: " .. tostring(err2))
            end
        end
    end
    
    executeWithFallback()
end)

-- Return script info for external access
return SCRIPT_INFO
