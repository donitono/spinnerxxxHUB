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
local player = Players.LocalPlayer

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
            end
        end)
    end)
    
    if success then
        print("✓ Chat commands initialized")
    else
        warn("Chat commands failed: " .. tostring(err))
    end
end

-- Initialize
setupChatCommands()

-- Success message
print("=================================")
print("   SUPER HUB LOADED SUCCESSFULLY!")
print("   Type /superhub for commands")
print("   Created by: donitono")
print("=================================")

createNotification("SUPER HUB v1.0", "Loaded! Type /superhub for help")

-- Return autofarm for external access
return autofarm
