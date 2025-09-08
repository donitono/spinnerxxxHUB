-- Test script untuk memverifikasi auto reel
-- Load Advanced Auto Reel module

print("🧪 Testing Auto Reel Module...")

-- Test 1: Load module
local success, advancedReel = pcall(function()
    return loadfile("/workspaces/spinnerxxxHUB/Modules/auto-reel-advanced.lua")()
end)

if success then
    print("✅ Advanced Auto Reel module loaded successfully")
    
    -- Test 2: Check functions
    if type(advancedReel.start) == "function" then
        print("✅ start() function exists")
    else
        print("❌ start() function missing")
    end
    
    if type(advancedReel.stop) == "function" then
        print("✅ stop() function exists")
    else
        print("❌ stop() function missing")
    end
    
    if type(advancedReel.test) == "function" then
        print("✅ test() function exists")
    else
        print("❌ test() function missing")
    end
    
    -- Test 3: Check status
    local status = advancedReel.getStatus()
    print("📊 Current status:")
    print("  - Enabled: " .. tostring(status.enabled))
    print("  - Debug Mode: " .. tostring(status.debugMode))
    print("  - Human-like: " .. tostring(status.humanLike))
    print("  - Active Connection: " .. tostring(status.hasActiveConnection))
    
    -- Test 4: Test input simulation
    print("🎮 Testing input simulation...")
    if advancedReel.test then
        advancedReel.test()
    end
    
    print("🎯 Advanced Auto Reel module is ready to use!")
    print("💡 Use advancedReel.start() to begin auto reel")
    
else
    print("❌ Failed to load Advanced Auto Reel module:")
    print("Error: " .. tostring(advancedReel))
end
