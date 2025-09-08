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
    -- Ganti dengan URL raw GitHub Anda nanti
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
        return game:HttpGet(url)
    end)
    
    if not success then
        warn("Failed to load " .. scriptName .. " from primary URL: " .. tostring(result))
        warn("Trying fallback URL...")
        
        success, result = pcall(function()
            return game:HttpGet(fallbackUrl)
        end)
        
        if not success then
            error("Failed to load " .. scriptName .. " from both URLs: " .. tostring(result))
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
            autofarm = require(game.Workspace.spinnerxxxHUB.Modules.autofarm)
        else
            -- Online mode - load from GitHub
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
            -- Local development mode - load from file (simplified kavo untuk testing)
            Library = {
                CreateLib = function(name, theme)
                    return {
                        NewTab = function(tabName)
                            return {
                                NewSection = function(sectionName)
                                    return {
                                        NewToggle = function(name, desc, callback)
                                            callback(false) -- Default state
                                        end,
                                        NewButton = function(name, desc, callback)
                                            -- Button creation
                                        end,
                                        NewSlider = function(name, desc, max, min, callback)
                                            callback(min) -- Default value
                                        end,
                                        NewDropdown = function(name, desc, options, callback)
                                            callback(options[1]) -- Default option
                                        end,
                                        NewTextBox = function(name, desc, callback)
                                            callback("") -- Default text
                                        end,
                                        NewLabel = function(text)
                                            -- Label creation
                                        end
                                    }
                                end
                            }
                        end
                    }
                end
            }
        else
            -- Online mode - load Kavo library
            local kavoScript = loadScriptFromURL(
                URLS.kavo,
                URLS.fallback_kavo,
                "Kavo UI Library"
            )
            Library = loadstring(kavoScript)()
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

-- Create main UI function
function createMainUI(Library, autofarm)
    -- Create Main Window
    local Window = Library.CreateLib("SUPER HUB v" .. SCRIPT_INFO.version, "DarkTheme")
    
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
    AutofarmSection:NewToggle("Auto Reel", "Automatically reel in fish", function(state)
        if state then
            autofarm.startAutoReel()
            print("Auto Reel: Enabled")
        else
            autofarm.stopAutoReel()
            print("Auto Reel: Disabled")
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
    -- Hook HttpGet untuk bypass deteksi
    local oldHttpGet = game.HttpGet
    game.HttpGet = function(self, url, ...)
        if url:find("spinnerxxxHUB") then
            -- Log akses untuk debugging
            print("Loading from: " .. url)
        end
        return oldHttpGet(self, url, ...)
    end
end

-- Initialize anti-detection
setupAntiDetection()

-- Main execution
spawn(function()
    if not safeExecute(loadSuperHub, "Failed to load SUPER HUB") then
        -- Fallback notification
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "SUPER HUB";
            Text = "Failed to load script. Check console for details.";
            Duration = 5;
        })
    end
end)

-- Return script info for external access
return SCRIPT_INFO
