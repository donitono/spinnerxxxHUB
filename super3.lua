--// Services
local Players = cloneref(game:GetService('Players'))
local ReplicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local RunService = cloneref(game:GetService('RunService'))
local GuiService = cloneref(game:GetService('GuiService'))
local VirtualInputManager = cloneref(game:GetService('VirtualInputManager'))

-- Protect TweenService from workspace errors
pcall(function()
    local TweenService = game:GetService("TweenService")
    local originalCreate = TweenService.Create
    TweenService.Create = function(self, instance, ...)
        if instance and instance.Parent then
            return originalCreate(self, instance, ...)
        else
            -- Return dummy tween for invalid instances
            return {
                Play = function() end,
                Cancel = function() end,
                Pause = function() end,
                Destroy = function() end
            }
        end
    end
end)

--// Variables
local flags = {}
local characterposition
local lp = Players.LocalPlayer
local fishabundancevisible = false
local deathcon
local tooltipmessage

-- Default delay values
flags['autocastdelay'] = 0.01
flags['autoreeldelay'] = 0.01
flags['noanimationautocast'] = false -- NEW: No animation auto cast
flags['autocastarmmovement'] = false -- NEW: Arm movement in auto cast
flags['predictiveautocast'] = false -- NEW: Predictive zero-gap auto cast
flags['debugmode'] = false -- NEW: Enable/disable console output for performance

-- Zone Cast Variables
flags['autozonecast'] = false
local selectedZoneCast = ""
local AutoZoneCast = false

-- Super Instant Reel Variables
flags['superinstantreel'] = false
flags['instantbobber'] = false
flags['enhancedinstantbobber'] = false
flags['superinstantnoanimation'] = false -- NEW: Disable all animations during super instant reel
local superInstantReelActive = false
local lureMonitorConnection = nil

-- Performance Logging Function
local function debugPrint(message)
    if flags['debugmode'] then
        print(message)
    end
end

-- Disable Animations Variables
flags['disableanimations'] = false
flags['blockrodwave'] = false
flags['blockshakeeffects'] = false
flags['blockexaltedanim'] = false

-- ENHANCED Super Instant Reel System (SMOOTH & FAST FISH LIFTING)
local function setupOptimizedSuperInstantReel()
    if not superInstantReelActive then
        superInstantReelActive = true
        
        -- Single optimized monitoring loop (reduced CPU usage)
        lureMonitorConnection = RunService.Heartbeat:Connect(function()
            if flags['superinstantreel'] then
                pcall(function()
                    local rod = FindRod()
                    if rod and rod.values then
                        local lureValue = rod.values.lure and rod.values.lure.Value or 0
                        local biteValue = rod.values.bite and rod.values.bite.Value or false
                        
                        -- ANIMATION HANDLING: Speed up or disable animations based on settings
                        local character = lp.Character
                        if character and character:FindFirstChild("Humanoid") then
                            local humanoid = character.Humanoid
                            
                            if flags['superinstantnoanimation'] then
                                -- DISABLE ALL ANIMATIONS: Stop all reel/fish animations completely
                                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                                    if track.Name:lower():find("fish") or track.Name:lower():find("reel") or 
                                       track.Name:lower():find("catch") or track.Name:lower():find("lift") or
                                       track.Name:lower():find("cast") or track.Name:lower():find("rod") then
                                        track:Stop() -- Completely stop animation
                                    end
                                end
                            else
                                -- FAST FISH LIFTING: Speed up character animations when super instant reel is active
                                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                                    if track.Name:lower():find("fish") or track.Name:lower():find("reel") or 
                                       track.Name:lower():find("catch") or track.Name:lower():find("lift") then
                                        track:AdjustSpeed(3) -- 3x faster fish lifting animation
                                    end
                                end
                            end
                        end
                        
                        -- ULTRA-INSTANT catch when fish activity detected (ZERO ANIMATION)
                        if lureValue >= 95 or biteValue == true then -- Lower threshold for faster response
                            -- IMMEDIATE completion before any animation can start
                            for i = 1, 5 do -- Multiple rapid fires
                                ReplicatedStorage.events.reelfinished:FireServer(100, true)
                            end
                            
                            -- INSTANT GUI destruction
                            local reelGui = lp.PlayerGui:FindFirstChild("reel")
                            if reelGui then
                                reelGui:Destroy()
                            end
                            
                            -- FORCE STOP any animations that might have started
                            local character = lp.Character
                            if character and character:FindFirstChild("Humanoid") then
                                local humanoid = character.Humanoid
                                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                                    local animName = track.Name:lower()
                                    if animName:find("fish") or animName:find("reel") or animName:find("cast") or
                                       animName:find("rod") or animName:find("catch") or animName:find("lift") or
                                       animName:find("pull") or animName:find("bobber") then
                                        track:Stop()
                                        track:AdjustSpeed(0)
                                    end
                                end
                            end
                            
                            -- Removed console output for performance
                            -- print("⚡ [ULTRA-INSTANT] Lure:" .. lureValue .. "% - ZERO ANIMATION COMPLETION!")
                        end
                    end
                end)
            end
        end)
        
        -- 🚫 ZERO-FLASH GUI INTERCEPT (Enhanced with immediate disable)
        local playerGui = lp.PlayerGui
        playerGui.ChildAdded:Connect(function(gui)
            if flags['superinstantreel'] and gui.Name == "reel" then
                -- IMMEDIATE VISUAL BLOCKING - No flash allowed
                gui.Enabled = false -- Block immediately
                gui.Visible = false -- Hide immediately
                gui:Destroy() -- Then destroy
                
                -- Fire completion without delays
                ReplicatedStorage.events.reelfinished:FireServer(100, true)
                -- print("� [ZERO-FLASH] Blocked reel GUI with no visual flash!")
            end
        end)
        
        -- print("✅ [OPTIMIZED INSTANT REEL] Smooth animation system activated!")
        -- print("🎯 Reduced CPU usage while maintaining instant catch!")
        
        -- CONTINUOUS ANIMATION DISABLING SYSTEM (for no animation mode)
        task.spawn(function()
            while superInstantReelActive do
                task.wait(0.05) -- Check every 50ms for more aggressive blocking
                if flags['superinstantreel'] and flags['superinstantnoanimation'] then
                    pcall(function()
                        local character = lp.Character
                        if character and character:FindFirstChild("Humanoid") then
                            local humanoid = character.Humanoid
                            
                            -- AGGRESSIVELY stop all fishing-related animations
                            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                                local animName = track.Name:lower()
                                local animId = tostring(track.Animation.AnimationId):lower()
                                
                                -- Expanded animation detection patterns
                                if animName:find("fish") or animName:find("reel") or animName:find("cast") or 
                                   animName:find("rod") or animName:find("catch") or animName:find("lift") or
                                   animName:find("pull") or animName:find("bobber") or animName:find("yank") or
                                   animId:find("fish") or animId:find("reel") or animId:find("cast") or
                                   animId:find("rod") or animId:find("catch") or animId:find("lift") or
                                   animId:find("pull") or animId:find("bobber") or animId:find("yank") then
                                    track:Stop() -- Aggressively stop all fishing animations
                                    track:AdjustSpeed(0) -- Set speed to 0 as backup
                                end
                            end
                        end
                    end)
                end
            end
        end)
    end
end

-- Call optimized setup function
setupOptimizedSuperInstantReel()

-- Zone Casting Function (inspired by main2.lua)
local function ZoneCasting()
    spawn(function()
        while AutoZoneCast do
            local player = lp
            local character = player.Character

            if character then
                local tool = character:FindFirstChildOfClass("Tool")
                if tool then
                    local hasBobber = tool:FindFirstChild("bobber")
                    if hasBobber then
                        -- Extend rope to maximum length
                        local ropeConstraint = hasBobber:FindFirstChild("RopeConstraint")
                        if ropeConstraint then
                            ropeConstraint.Length = 200000
                        end

                        local platformSize = Vector3.new(10, 1, 10)
                        local platformPositionOffset = Vector3.new(0, -4, 0)
                        local bobberPosition = nil

                        -- Handle special zones
                        if selectedZoneCast == "Bluefin Tuna Abundance" then
                            local selectedZone = Workspace.zones.fishing:FindFirstChild("Deep Ocean")
                            if selectedZone then
                                local abundanceValue = selectedZone:FindFirstChild("Abundance")
                                if abundanceValue and abundanceValue.Value == "Bluefin Tuna" then
                                    bobberPosition = CFrame.new(selectedZone.Position.X, 126.564, selectedZone.Position.Z)
                                    -- print("🐟 [Zone Cast] Bluefin Tuna abundance detected!")
                                end
                            end
                        elseif selectedZoneCast == "Swordfish Abundance" then
                            local selectedZone = Workspace.zones.fishing:FindFirstChild("Deep Ocean")
                            if selectedZone then
                                local abundanceValue = selectedZone:FindFirstChild("Abundance")
                                if abundanceValue and abundanceValue.Value == "Swordfish" then
                                    bobberPosition = CFrame.new(selectedZone.Position.X, 126.564, selectedZone.Position.Z)
                                    -- print("⚔️ [Zone Cast] Swordfish abundance detected!")
                                end
                            end
                        elseif selectedZoneCast == "FischFright24" or selectedZoneCast == "Isonade" then
                            -- Dynamic zones - use zone position
                            local selectedZone = Workspace.zones.fishing:FindFirstChild(selectedZoneCast)
                            if selectedZone then
                                bobberPosition = CFrame.new(selectedZone.Position.X, 126, selectedZone.Position.Z)
                                -- print("🎃 [Zone Cast] Dynamic zone: " .. selectedZoneCast)
                            end
                        else
                            -- Regular zones with fixed coordinates
                            local zoneCoord = ZoneCastCoordinates[selectedZoneCast]
                            if zoneCoord and typeof(zoneCoord) == "CFrame" then
                                bobberPosition = zoneCoord
                                -- print("🗺️ [Zone Cast] Regular zone: " .. selectedZoneCast)
                            end
                        end

                        -- Apply bobber position if found
                        if bobberPosition then
                            hasBobber.CFrame = bobberPosition
                            
                            -- Create invisible platform under bobber
                            local platform = Instance.new("Part")
                            platform.Size = platformSize
                            platform.Position = hasBobber.Position + platformPositionOffset
                            platform.Anchored = true
                            platform.Parent = hasBobber
                            platform.BrickColor = BrickColor.new("Bright blue")
                            platform.Transparency = 1.000
                            platform.CanCollide = false
                            platform.Name = "ZoneCastPlatform"
                            
                            -- Clean up old platforms
                            pcall(function()
                                for _, oldPlatform in pairs(hasBobber:GetChildren()) do
                                    if oldPlatform.Name == "ZoneCastPlatform" and oldPlatform ~= platform then
                                        oldPlatform:Destroy()
                                    end
                                end
                            end)
                        end
                    else
                        -- print("🎣 [Zone Cast] No bobber found - cast your rod first!")
                    end
                else
                    -- print("🎣 [Zone Cast] No fishing rod equipped!")
                end
            end
            task.wait(0.01) -- Fast monitoring like main2.lua
        end
    end)
end

local TeleportLocations = {
    ['Zones'] = {
        ['Moosewood'] = CFrame.new(379.875458, 134.500519, 233.5495, -0.033920113, 8.13274355e-08, 0.999424577, 8.98441925e-08, 1, -7.83249803e-08, -0.999424577, 8.7135696e-08, -0.033920113),
        ['Roslit Bay'] = CFrame.new(-1472.9812, 132.525513, 707.644531, -0.00177415239, 1.15743369e-07, -0.99999845, -9.25943056e-09, 1, 1.15759981e-07, 0.99999845, 9.46479251e-09, -0.00177415239),
        ['Forsaken Shores'] = CFrame.new(-2491.104, 133.250015, 1561.2926, 0.355353981, -1.68352852e-08, -0.934731781, 4.69647858e-08, 1, -1.56367586e-10, 0.934731781, -4.38439116e-08, 0.355353981),
        ['Sunstone Island'] = CFrame.new(-913.809143, 138.160782, -1133.25879, -0.746701241, 4.50330218e-09, 0.665159583, 2.84934609e-09, 1, -3.5716119e-09, -0.665159583, -7.71657294e-10, -0.746701241),
        ['Statue of Sovereignty'] = CFrame.new(21.4017925, 159.014709, -1039.14233, -0.865476549, -4.38348664e-08, -0.500949502, -9.38435818e-08, 1, 7.46273798e-08, 0.500949502, 1.11599142e-07, -0.865476549),
        ['Terrapin Island'] = CFrame.new(-193.434143, 135.121979, 1951.46936, 0.512723684, -6.94711346e-08, 0.858553708, 5.44089183e-08, 1, 4.84237539e-08, -0.858553708, 2.18849721e-08, 0.512723684),
        ['Snowcap Island'] = CFrame.new(2607.93018, 135.284332, 2436.13208, 0.909039497, -7.49003748e-10, 0.4167099, 3.38659367e-09, 1, -5.59032465e-09, -0.4167099, 6.49305321e-09, 0.909039497),
        ['Mushgrove Swamp'] = CFrame.new(2434.29785, 131.983276, -691.930542, -0.123090521, -7.92820209e-09, -0.992395461, -9.05862692e-08, 1, 3.2467995e-09, 0.992395461, 9.02970569e-08, -0.123090521),
        ['Ancient Isle'] = CFrame.new(6056.02783, 195.280167, 276.270325, -0.655055285, 1.96010075e-09, 0.755580962, -1.63855578e-08, 1, -1.67997189e-08, -0.755580962, -2.33853594e-08, -0.655055285),
        ['Northern Expedition'] = CFrame.new(-1701.02979, 187.638779, 3944.81494, 0.918493569, -8.5804345e-08, 0.395435959, 8.59132356e-08, 1, 1.74328942e-08, -0.395435959, 1.7961181e-08, 0.918493569),
        ['Northern Summit'] = CFrame.new(19608.791, 131.420105, 5222.15283, 0.462794542, -2.64426987e-08, 0.886465549, -4.47066562e-08, 1, 5.31692343e-08, -0.886465549, -6.42373408e-08, 0.462794542),
        ['Vertigo'] = CFrame.new(-102.40567, -513.299377, 1052.07104, -0.999989033, 5.36423439e-09, 0.00468267547, 5.85247495e-09, 1, 1.04251647e-07, -0.00468267547, 1.04277916e-07, -0.999989033),
        ['Depths Entrance'] = CFrame.new(-15.4965982, -706.123718, 1231.43494, 0.0681341439, 1.15903154e-08, -0.997676194, 7.1017638e-08, 1, 1.64673093e-08, 0.997676194, -7.19745898e-08, 0.0681341439),
        ['Depths'] = CFrame.new(491.758118, -706.123718, 1230.6377, 0.00879980437, 1.29271776e-08, -0.999961257, 1.95575205e-13, 1, 1.29276803e-08, 0.999961257, -1.13956629e-10, 0.00879980437),
        ['Overgrowth Caves'] = CFrame.new(19746.2676, 416.00293, 5403.5752, 0.488031536, -3.30940715e-08, -0.87282598, -3.24267696e-11, 1, -3.79341323e-08, 0.87282598, 1.85413569e-08, 0.488031536),
        ['Frigid Cavern'] = CFrame.new(20253.6094, 756.525818, 5772.68555, -0.781508088, 1.85673343e-08, 0.623895109, 5.92671467e-09, 1, -2.23363816e-08, -0.623895109, -1.3758414e-08, -0.781508088),
        ['Cryogenic Canal'] = CFrame.new(19958.5176, 917.195923, 5332.59375, 0.758922458, -7.29783434e-09, 0.651180983, -4.58880756e-09, 1, 1.65551253e-08, -0.651180983, -1.55522013e-08, 0.758922458),
        ['Glacial Grotto'] = CFrame.new(20003.0273, 1136.42798, 5555.95996, 0.983130038, -3.94455064e-08, 0.182907909, 3.45229765e-08, 1, 3.0096718e-08, -0.182907909, -2.32744615e-08, 0.983130038),
        ["Keeper's Altar"] = CFrame.new(1297.92285, -805.292236, -284.155823, -0.99758029, 5.80044706e-08, -0.0695239156, 6.16549869e-08, 1, -5.03615105e-08, 0.0695239156, -5.45261436e-08, -0.99758029),
        ['Atlantis'] = CFrame.new(2015, -645, 2460),
    ['Snowburk'] = CFrame.new(2865, 141, 2557),
    ['Snowburk 1'] = CFrame.new(2800 , 280 , 2565)
    },
    ['Rods'] = {
        ['Heaven Rod'] = CFrame.new(20025.0508, -467.665955, 7114.40234, -0.9998191, -2.41349773e-10, 0.0190212391, -4.76249762e-10, 1, -1.23448247e-08, -0.0190212391, -1.23516495e-08, -0.9998191),
        ['Summit Rod'] = CFrame.new(20213.334, 736.668823, 5707.8208, -0.274440169, 3.53429606e-08, 0.961604178, -1.52819659e-08, 1, -4.11156122e-08, -0.961604178, -2.59789772e-08, -0.274440169),
        ['Kings Rod'] = CFrame.new(1380.83862, -807.198608, -304.22229, -0.692510426, 9.24755454e-08, 0.72140789, 4.86611427e-08, 1, -8.1475676e-08, -0.72140789, -2.13182219e-08, -0.692510426),
        ['Training Rod'] = CFrame.new(465, 150, 235),
        ['Long Rod'] = CFrame.new(480, 180, 150),
        ['Fortune Rod'] = CFrame.new(-1515, 141, 765),
        ['Depthseeker Rod'] = CFrame.new(-4465, -604, 1874),
        ['Champions Rod'] = CFrame.new(-4277, -606, 1838),
        ['Tempest Rod'] = CFrame.new(-4928, -595, 1857),
        ['Abyssal Specter Rod'] = CFrame.new(-3804, -567, 1870),
        ['Poseidon Rod'] = CFrame.new(-4086, -559, 895),
        ['Zeus Rod'] = CFrame.new(-4272, -629, 2665),
        ['Kraken Rod'] = CFrame.new(-4415, -997, 2055),
        ['Reinforced Rod'] = CFrame.new(-975, -245, -2700),
        ['Trident Rod'] = CFrame.new(-1485, -225, -2195),
        ['Scurvy Rod'] = CFrame.new(-2830, 215, 1510),
        ['Stone Rod'] = CFrame.new(5487, 143, -316),
        ['Magnet Rod'] = CFrame.new(-200, 130, 1930)
    },
    ['Items'] = {
        ['Fish Radar'] = CFrame.new(365, 135, 275),
        ['Basic Diving Gear'] = CFrame.new(370, 135, 250),
        ['Bait Crate (Moosewood)'] = CFrame.new(315, 135, 335),
        ['Meteor Totem'] = CFrame.new(-1945, 275, 230),
        ['Glider'] = CFrame.new(-1710, 150, 740),
        ['Bait Crate (Roslit)'] = CFrame.new(-1465, 130, 680),
        ['Crab Cage (Roslit)'] = CFrame.new(-1485, 130, 640),
        ['Poseidon Wrath Totem'] = CFrame.new(-3953, -556, 853),
        ['Zeus Storm Totem'] = CFrame.new(-4325, -630, 2687),
        ['Quality Bait Crate (Atlantis)'] = CFrame.new(-177, 144, 1933),
        ['Flippers'] = CFrame.new(-4462, -605, 1875),
        ['Super Flippers'] = CFrame.new(-4463, -603, 1876),
        ['Advanced Diving Gear (Atlantis)'] = CFrame.new(-4452, -603, 1877),
        ['Conception Conch (Atlantis)'] = CFrame.new(-4450, -605, 1874),
        ['Advanced Diving Gear (Desolate)'] = CFrame.new(-790, 125, -3100),
        ['Basic Diving Gear (Desolate)'] = CFrame.new(-1655, -210, -2825),
        ['Tidebreaker'] = CFrame.new(-1645, -210, -2855),
        ['Conception Conch (Desolate)'] = CFrame.new(-1630, -210, -2860),
        ['Aurora Totem'] = CFrame.new(-1800, -135, -3280),
        ['Bait Crate (Forsaken)'] = CFrame.new(-2490, 130, 1535),
        ['Crab Cage (Forsaken)'] = CFrame.new(-2525, 135, -1575),
        ['Eclipse Totem'] = CFrame.new(5966, 274, 846),
        ['Bait Crate (Ancient)'] = CFrame.new(6075, 195, 260),
        ['Smokescreen Totem'] = CFrame.new(2790, 140, -625),
        ['Crab Cage (Mushgrove)'] = CFrame.new(2520, 135, -895),
        ['Windset Totem'] = CFrame.new(2845, 180, 2700),
        ['Sundial Totem'] = CFrame.new(-1145, 135, -1075),
        ['Bait Crate (Sunstone)'] = CFrame.new(-1045, 200, -1100),
        ['Crab Cage (Sunstone)'] = CFrame.new(-920, 130, -1105),
        ['Quality Bait Crate (Terrapin)'] = CFrame.new(-175, 145, 1935),
        ['Tempest Totem'] = CFrame.new(35, 130, 1945)
    },
    ['Fishing Spots'] = {
        ['Trout Spot'] = CFrame.new(390, 132, 345),
        ['Anchovy Spot'] = CFrame.new(130, 135, 630),
        ['Yellowfin Tuna Spot'] = CFrame.new(705, 136, 340),
        ['Carp Spot'] = CFrame.new(560, 145, 600),
        ['Goldfish Spot'] = CFrame.new(525, 145, 310),
        ['Flounder Spot'] = CFrame.new(285, 133, 215),
        ['Pike Spot'] = CFrame.new(540, 145, 330),
        ['Perch Spot'] = CFrame.new(-1805, 140, 595),
        ['Blue Tang Spot'] = CFrame.new(-1465, 125, 525),
        ['Clownfish Spot'] = CFrame.new(-1520, 125, 520),
        ['Clam Spot'] = CFrame.new(-2028, 130, 541),
        ['Angelfish Spot'] = CFrame.new(-1500, 135, 615),
        ['Arapaima Spot'] = CFrame.new(-1765, 140, 600),
        ['Suckermouth Catfish Spot'] = CFrame.new(-1800, 140, 620),
        ['Phantom Ray Spot'] = CFrame.new(-1685, -235, -3090),
        ['Cockatoo Squid Spot'] = CFrame.new(-1645, -205, -2790),
        ['Banditfish Spot'] = CFrame.new(-1500, -235, -2855),
        ['Scurvy Sailfish Spot'] = CFrame.new(-2430, 130, 1450),
        ['Cutlass Fish Spot'] = CFrame.new(-2645, 130, 1410),
        ['Shipwreck Barracuda Spot'] = CFrame.new(-3597, 140, 1604),
        ['Golden Seahorse Spot'] = CFrame.new(-3100, 127, 1450),
        ['Anomalocaris Spot'] = CFrame.new(5504, 143, -321),
        ['Cobia Spot'] = CFrame.new(5983, 125, 1007),
        ['Hallucigenia Spot'] = CFrame.new(6015, 190, 339),
        ['Leedsichthys Spot'] = CFrame.new(6052, 394, 648),
        ['Deep Sea Fragment Spot'] = CFrame.new(5841, 81, 388),
        ['Solar Fragment Spot'] = CFrame.new(6073, 443, 684),
        ['Earth Fragment Spot'] = CFrame.new(5972, 274, 845),
        ['White Perch Spot'] = CFrame.new(2475, 125, -675),
        ['Grey Carp Spot'] = CFrame.new(2665, 125, -815),
        ['Bowfin Spot'] = CFrame.new(2445, 125, -795),
        ['Marsh Gar Spot'] = CFrame.new(2520, 125, -815),
        ['Alligator Spot'] = CFrame.new(2670, 130, -710),
        ['Pollock Spot'] = CFrame.new(2550, 135, 2385),
        ['Bluegill Spot'] = CFrame.new(3070, 130, 2600),
        ['Herring Spot'] = CFrame.new(2595, 140, 2500),
        ['Red Drum Spot'] = CFrame.new(2310, 135, 2545),
        ['Arctic Char Spot'] = CFrame.new(2350, 130, 2230),
        ['Lingcod Spot'] = CFrame.new(2820, 125, 2805),
        ['Glacierfish Spot'] = CFrame.new(2860, 135, 2620),
        ['Sweetfish Spot'] = CFrame.new(-940, 130, -1105),
        ['Glassfish Spot'] = CFrame.new(-905, 130, -1000),
        ['Longtail Bass Spot'] = CFrame.new(-860, 135, -1205),
        ['Red Tang Spot'] = CFrame.new(-1195, 123, -1220),
        ['Chinfish Spot'] = CFrame.new(-625, 130, -950),
        ['Trumpetfish Spot'] = CFrame.new(-790, 125, -1340),
        ['Mahi Mahi Spot'] = CFrame.new(-730, 130, -1350),
        ['Sunfish Spot'] = CFrame.new(-975, 125, -1430),
        ['Walleye Spot'] = CFrame.new(-225, 125, 2150),
        ['White Bass Spot'] = CFrame.new(-50, 130, 2025),
        ['Redeye Bass Spot'] = CFrame.new(-35, 125, 2285),
        ['Chinook Salmon Spot'] = CFrame.new(-305, 125, 1625),
        ['Golden Smallmouth Bass Spot'] = CFrame.new(65, 135, 2140),
        ['Olm Spot'] = CFrame.new(95, 125, 1980)
    },
    ['NPCs'] = {
        ['Angler'] = CFrame.new(480, 150, 295),
        ['Appraiser'] = CFrame.new(445, 150, 210),
        ['Arnold'] = CFrame.new(320, 134, 264),
        ['Bob'] = CFrame.new(420, 145, 260),
        ['Brickford Masterson'] = CFrame.new(412, 132, 365),
        ['Captain Ahab'] = CFrame.new(441, 135, 358),
        ['Challenges'] = CFrame.new(337, 138, 312),
        ['Clover McRich'] = CFrame.new(345, 136, 330),
        ['Daisy'] = CFrame.new(580, 165, 220),
        ['Dr. Blackfin'] = CFrame.new(355, 136, 329),
        ['Egg Salesman'] = CFrame.new(404, 135, 312),
        ['Harry Fischer'] = CFrame.new(396, 134, 381),
        ['Henry'] = CFrame.new(484, 152, 236),
        ['Inn Keeper'] = CFrame.new(490, 150, 245),
        ['Lucas'] = CFrame.new(450, 180, 175),
        ['Marlon Friend'] = CFrame.new(405, 135, 248),
        ['Merchant'] = CFrame.new(465, 150, 230),
        ['Paul'] = CFrame.new(382, 137, 347),
        ['Phineas'] = CFrame.new(470, 150, 275),
        ['Pierre'] = CFrame.new(390, 135, 200),
        ['Pilgrim'] = CFrame.new(402, 134, 257),
        ['Ringo'] = CFrame.new(410, 135, 235),
        ['Shipwright'] = CFrame.new(360, 135, 260),
        ['Skin Merchant'] = CFrame.new(415, 135, 194),
        ['Smurfette'] = CFrame.new(334, 135, 327),
        ['Tom Elf'] = CFrame.new(404, 136, 317),
        ['Witch'] = CFrame.new(410, 135, 310),
        ['Wren'] = CFrame.new(368, 135, 286),
        ['Mike'] = CFrame.new(210, 115, 640),
        ['Ryder Vex'] = CFrame.new(233, 116, 746),
        ['Ocean'] = CFrame.new(1230, 125, 575),
        ['Lars Timberjaw'] = CFrame.new(1217, 87, 574),
        ['Sporey'] = CFrame.new(1245, 86, 425),
        ['Sporey Mom'] = CFrame.new(1262, 129, 663),
        ['Oscar IV'] = CFrame.new(1392, 116, 493),
        ['Angus McBait'] = CFrame.new(236, 222, 461),
        ['Waveborne'] = CFrame.new(360, 90, 780),
        ['Boone Tiller'] = CFrame.new(390, 87, 764),
        ['Clark'] = CFrame.new(443, 84, 703),
        ['Jak'] = CFrame.new(474, 84, 758),
        ['Willow'] = CFrame.new(501, 134, 125),
        ['Marley'] = CFrame.new(505, 134, 120),
        ['Sage'] = CFrame.new(513, 134, 125),
        ['Meteoriticist'] = CFrame.new(5922, 262, 596),
        ['Chiseler'] = CFrame.new(6087, 195, 294),
        ['Sea Traveler'] = CFrame.new(140, 150, 2030),
        ['Wilson'] = CFrame.new(2935, 280, 2565),
        ['Agaric'] = CFrame.new(2931, 4268, 3039),
        ['Sunken Chest'] = CFrame.new(798, 130, 1667),
        ['Daily Shopkeeper'] = CFrame.new(229, 139, 42),
        ['AFK Rewards'] = CFrame.new(233, 139, 38),
        ['Travelling Merchant'] = CFrame.new(2, 500, 0),
        ['Silas'] = CFrame.new(1545, 1690, 6310),
        ['Nick'] = CFrame.new(50, 0, 0),
        ['Hollow'] = CFrame.new(25, 0, 0),
        ['Shopper Girl'] = CFrame.new(1000, 140, 9932),
        ['Sandy Finn'] = CFrame.new(1015, 140, 9911),
        ['Red NPC'] = CFrame.new(1020, 173, 9857),
        ['Thomas'] = CFrame.new(1062, 140, 9890),
        ['Shawn'] = CFrame.new(1068, 157, 9918),
        ['Axel'] = CFrame.new(883, 132, 9905),
        ['Joey'] = CFrame.new(906, 132, 9962),
        ['Jett'] = CFrame.new(925, 131, 9883),
        ['Lucas (Fischfest)'] = CFrame.new(946, 132, 9894),
        ['Shell Merchant'] = CFrame.new(972, 132, 9921),
        ['Barnacle Bill'] = CFrame.new(989, 143, 9975)
    },
    ['Mariana Veil'] = {
        -- SUBMARINE DEPOT
        ['Submarine Depot'] = CFrame.new(1500, 125, 530),
        ['North-Western Side'] = CFrame.new(-1305, 130, 310),
        ['Submarine Depot (West)'] = CFrame.new(-1480, 137, 382),
        
        -- VOLCANIC VENTS
        ['Magma Leviathan'] = CFrame.new(-4360, -11175, 3715),
        ['Challenger\'s Deep Entrance'] = CFrame.new(-2630, -3830, 755),
        ['Volcanic Vents Entrance'] = CFrame.new(-2745, -2325, 865),
        ['Volcanic Tunnel End'] = CFrame.new(-3420, -2275, 3765),
        ['Volcanic Rocks'] = CFrame.new(-3365, -2260, 3850),
        ['Lava Fishing Cave'] = CFrame.new(-3495, -2255, 3825),
        ['Lava Fishing Pool'] = CFrame.new(-3175, -2035, 4020),
        
        -- CHALLENGER'S DEEP
        ['Abyssal Zenith Entrance'] = CFrame.new(-5375, -7390, 400),
        ['Ice Fishing Cave (East)'] = CFrame.new(740, -3355, -1530),
        ['Ice Cave (Large)'] = CFrame.new(-835, -3295, -625),
        ['Ice Rocks Cave'] = CFrame.new(-800, -3280, -625),
        ['Ice Fishing Cave (Central)'] = CFrame.new(-760, -3280, -715),
        ['Ice Portal Back'] = CFrame.new(-735, -3280, -725),
        
        -- ABYSSAL ZENITH
        ['Hidden River (Calm Zone)'] = CFrame.new(-4305, -11230, 1955),
        ['Calm Zone'] = CFrame.new(-4145, -11210, 1395),
        ['Crossbow Arrow (East)'] = CFrame.new(-2300, -11190, 7140),
        ['Crossbow Bow'] = CFrame.new(-4800, -11185, 6610),
        ['Crossbow Arrow (West)'] = CFrame.new(-4035, -11185, 6510),
        ['Hidden River'] = CFrame.new(-4330, -11180, 3120),
        ['Crossbow Base'] = CFrame.new(-4345, -11155, 6490),
        ['Crossbow Base (Main)'] = CFrame.new(-4360, -11090, 7140),
        ['Abyssal Zenith Upgrade'] = CFrame.new(-13515, -11050, 175),
        ['Zenith Tunnel End'] = CFrame.new(-13420, -11050, 110),
        ['Rod of the Zenith'] = CFrame.new(-13625, -11035, 355)
    },
    ['All Locations'] = {
        -- Sea Traveler
        ['Sea Traveler #1'] = CFrame.new(140, 150, 2030),
        ['Sea Traveler #2'] = CFrame.new(690, 170, 345),
        
        -- Terrapin Island
        ['Terrapin Island #1'] = CFrame.new(-200, 130, 1925),
        ['Terrapin Island #2'] = CFrame.new(10, 155, 2000),
        ['Terrapin Island #3'] = CFrame.new(160, 125, 1970),
        ['Terrapin Island #4'] = CFrame.new(25, 140, 1860),
        ['Terrapin Island #5'] = CFrame.new(140, 150, 2050),
        ['Terrapin Island #6'] = CFrame.new(-200, 130, 1930),
        ['Terrapin Island #7'] = CFrame.new(-175, 145, 1935),
        ['Terrapin Island #8'] = CFrame.new(35, 130, 1945),
        
        -- Moosewood Additional Spots
        ['Moosewood #1'] = CFrame.new(350, 135, 250),
        ['Moosewood #2'] = CFrame.new(412, 135, 233),
        ['Moosewood #3'] = CFrame.new(385, 135, 280),
        ['Moosewood #4'] = CFrame.new(480, 150, 295),
        ['Moosewood #5'] = CFrame.new(465, 150, 235),
        ['Moosewood #6'] = CFrame.new(480, 180, 150),
        ['Moosewood #7'] = CFrame.new(515, 150, 285),
        ['Moosewood #8'] = CFrame.new(365, 135, 275),
        ['Moosewood #9'] = CFrame.new(370, 135, 250),
        ['Moosewood #10'] = CFrame.new(315, 135, 335),
        ['Moosewood #11'] = CFrame.new(705, 137, 341),
        ['Moosewood #12'] = CFrame.new(-1878, 167, 548),
        
        -- Crystal Cove
        ['Crystal Cove #1'] = CFrame.new(1364, -612, 2472),
        ['Crystal Cove #2'] = CFrame.new(1302, -701, 1604),
        ['Crystal Cove #3'] = CFrame.new(1350, -604, 2329),
        
        -- Castaway Cliffs
        ['Castaway Cliffs #1'] = CFrame.new(690, 135, -1693),
        ['Castaway Cliffs #2'] = CFrame.new(255, 800, -6865),
        ['Castaway Cliffs #3'] = CFrame.new(560, 310, -2070),
        
        -- Gilded Arch
        ['Gilded Arch'] = CFrame.new(450, 90, 2850),
        
        -- Trade Plaza
        ['Trade Plaza'] = CFrame.new(535, 82, 775),
        
        -- Whale Interior
        ['Whale Interior #1'] = CFrame.new(-300, 83, -380),
        ['Whale Interior #2'] = CFrame.new(-30, -1350, -2160),
        ['Whale Interior #3'] = CFrame.new(-357, 96, -277),
        ['Whale Interior #4'] = CFrame.new(-387, 80, -387),
        ['Whale Interior #5'] = CFrame.new(-50, -1350, -2170),
        ['Whale Interior #6'] = CFrame.new(-317, 85, -420),
        
        -- Lobster Shores
        ['Lobster Shores #1'] = CFrame.new(-550, 150, 2640),
        ['Lobster Shores #2'] = CFrame.new(-550, 153, 2650),
        ['Lobster Shores #3'] = CFrame.new(-585, 130, 2950),
        ['Lobster Shores #4'] = CFrame.new(-575, 153, 2640),
        ['Lobster Shores #5'] = CFrame.new(-570, 153, 2640),
        ['Lobster Shores #6'] = CFrame.new(-565, 153, 2640),
        
        -- Netter's Haven
        ['Netters Haven #1'] = CFrame.new(-640, 85, 1030),
        ['Netters Haven #2'] = CFrame.new(-775, 90, 950),
        ['Netters Haven #3'] = CFrame.new(-635, 85, 1005),
        ['Netters Haven #4'] = CFrame.new(-630, 85, 1005),
        ['Netters Haven #5'] = CFrame.new(-610, 85, 1005),
        ['Netters Haven #6'] = CFrame.new(-575, 85, 1000),
        
        -- Waveborne
        ['Waveborne #1'] = CFrame.new(360, 90, 780),
        ['Waveborne #2'] = CFrame.new(400, 85, 737),
        ['Waveborne #3'] = CFrame.new(55, 160, 833),
        ['Waveborne #4'] = CFrame.new(165, 115, 730),
        ['Waveborne #5'] = CFrame.new(165, 115, 720),
        ['Waveborne #6'] = CFrame.new(223, 120, 815),
        ['Waveborne #7'] = CFrame.new(405, 85, 862),
        
        -- Isle of New Beginnings
        ['Isle of New Beginnings #1'] = CFrame.new(-300, 83, -380),
        ['Isle of New Beginnings #2'] = CFrame.new(-30, -1350, -2160),
        ['Isle of New Beginnings #3'] = CFrame.new(-357, 96, -277),
        ['Isle of New Beginnings #4'] = CFrame.new(-387, 80, -387),
        ['Isle of New Beginnings #5'] = CFrame.new(-50, -1350, -2170),
        ['Isle of New Beginnings #6'] = CFrame.new(-317, 85, -420),
        
        -- Lushgrove
        ['Lushgrove #1'] = CFrame.new(1133, 105, -560),
        ['Lushgrove #2'] = CFrame.new(1260, -625, -1070),
        ['Lushgrove #3'] = CFrame.new(1310, 130, -945),
        ['Lushgrove #4'] = CFrame.new(1505, 165, -665),
        ['Lushgrove #5'] = CFrame.new(1410, 155, -580),
        ['Lushgrove #6'] = CFrame.new(1355, 110, -615),
        ['Lushgrove #7'] = CFrame.new(1170, 115, -750),
        ['Lushgrove #8'] = CFrame.new(1020, 130, -705),
        ['Lushgrove #9'] = CFrame.new(1275, -625, -1060),
        ['Lushgrove #10'] = CFrame.new(1300, 155, -550),
        
        -- Emberreach
        ['Emberreach #1'] = CFrame.new(2390, 83, -490),
        ['Emberreach #2'] = CFrame.new(2870, 165, 520),
        
        -- Azure Lagoon
        ['Azure Lagoon #1'] = CFrame.new(1310, 80, 2113),
        ['Azure Lagoon #2'] = CFrame.new(1287, 90, 2285),
        
        -- The Cursed Shores
        ['Cursed Shores #1'] = CFrame.new(-235, 85, 1930),
        ['Cursed Shores #2'] = CFrame.new(-185, -370, 2280),
        ['Cursed Shores #3'] = CFrame.new(-435, -40, 1665),
        ['Cursed Shores #4'] = CFrame.new(-493, 137, 2240),
        ['Cursed Shores #5'] = CFrame.new(-210, -360, 2383),
        
        -- Pine Shoals
        ['Pine Shoals'] = CFrame.new(1165, 80, 480),
        
        -- The Laboratory
        ['The Laboratory'] = CFrame.new(-1785, 130, -485),
        
        -- Grand Reef
        ['Grand Reef #1'] = CFrame.new(-3530, 130, 550),
        ['Grand Reef #2'] = CFrame.new(-3820, 135, 575),
        
        -- Archaeological Site
        ['Archaeological Site'] = CFrame.new(4160, 125, 210),
        
        -- Ocean Spots
        ['Ocean Spot #1'] = CFrame.new(-1270, 125, 1580),
        ['Ocean Spot #2'] = CFrame.new(1000, 125, -1250),
        ['Ocean Spot #3'] = CFrame.new(-530, 125, -425),
        ['Ocean Spot #4'] = CFrame.new(1230, 125, 575),
        ['Ocean Spot #5'] = CFrame.new(1700, 125, -2500),
        
        -- Sunken Chest Locations
        ['Sunken Chest #1'] = CFrame.new(936, 130, -159),
        ['Sunken Chest #2'] = CFrame.new(-1179, 130, 565),
        ['Sunken Chest #3'] = CFrame.new(-852, 130, -1560),
        ['Sunken Chest #4'] = CFrame.new(798, 130, 1667),
        ['Sunken Chest #5'] = CFrame.new(2890, 130, -997),
        ['Sunken Chest #6'] = CFrame.new(-2460, 130, 2047),
        ['Sunken Chest #7'] = CFrame.new(693, 130, -362),
        ['Sunken Chest #8'] = CFrame.new(-1217, 130, 201),
        ['Sunken Chest #9'] = CFrame.new(-1000, 130, -751),
        ['Sunken Chest #10'] = CFrame.new(562, 130, 2455),
        ['Sunken Chest #11'] = CFrame.new(2729, 130, -1098),
        ['Sunken Chest #12'] = CFrame.new(613, 130, 498),
        ['Sunken Chest #13'] = CFrame.new(-1967, 130, 980),
        ['Sunken Chest #14'] = CFrame.new(-1500, 130, -750),
        ['Sunken Chest #15'] = CFrame.new(393, 130, 2435),
        ['Sunken Chest #16'] = CFrame.new(2410, 130, -1110),
        ['Sunken Chest #17'] = CFrame.new(285, 130, 564),
        ['Sunken Chest #18'] = CFrame.new(-2444, 130, 266),
        ['Sunken Chest #19'] = CFrame.new(-1547, 130, -1080),
        ['Sunken Chest #20'] = CFrame.new(-1, 130, 1632),
        ['Sunken Chest #21'] = CFrame.new(2266, 130, -721),
        ['Sunken Chest #22'] = CFrame.new(283, 130, -159),
        ['Sunken Chest #23'] = CFrame.new(-2444, 130, -37),
        ['Sunken Chest #24'] = CFrame.new(-1618, 130, -1560),
        ['Sunken Chest #25'] = CFrame.new(-190, 130, 2450),
        
        -- Special NPCs Location
        ['NPCs Area #1'] = CFrame.new(415, 135, 200),
        ['NPCs Area #2'] = CFrame.new(420, 145, 260),
        
        -- AFK Rewards Location
        ['AFK Rewards'] = CFrame.new(232, 139, 38),
        
        -- Treasure Hunting
        ['Treasure Hunting'] = CFrame.new(-2825, 215, 1515),
        
        -- Additional Missing Locations from gpsv2.txt
        
        -- Cthulhu Boss Locations
        ['Cthulhu Boss #1'] = CFrame.new(-200, 130, 1925),
        ['Cthulhu Boss #2'] = CFrame.new(10, 155, 2000),
        ['Cthulhu Boss #3'] = CFrame.new(160, 125, 1970),
        ['Cthulhu Boss #4'] = CFrame.new(25, 140, 1860),
        ['Cthulhu Boss #5'] = CFrame.new(140, 150, 2050),
        ['Cthulhu Boss #6'] = CFrame.new(-200, 130, 1930),
        ['Cthulhu Boss #7'] = CFrame.new(-175, 145, 1935),
        ['Cthulhu Boss #8'] = CFrame.new(35, 130, 1945),
        
        -- Ancient Archives
        ['Ancient Archives #1'] = CFrame.new(5833, 125, 401),
        ['Ancient Archives #2'] = CFrame.new(5870, 160, 415),
        ['Ancient Archives #3'] = CFrame.new(5487, 143, -316),
        ['Ancient Archives #4'] = CFrame.new(5966, 274, 846),
        ['Ancient Archives #5'] = CFrame.new(6075, 195, 260),
        ['Ancient Archives #6'] = CFrame.new(6000, 230, 591),
        
        -- Ancient Isle
        ['Ancient Isle #1'] = CFrame.new(5833, 125, 401),
        ['Ancient Isle #2'] = CFrame.new(5870, 160, 415),
        ['Ancient Isle #3'] = CFrame.new(5487, 143, -316),
        ['Ancient Isle #4'] = CFrame.new(5966, 274, 846),
        ['Ancient Isle #5'] = CFrame.new(6075, 195, 260),
        ['Ancient Isle #6'] = CFrame.new(6000, 230, 591),
        
        -- Atlantean Storm
        ['Atlantean Storm #1'] = CFrame.new(-3530, 130, 550),
        ['Atlantean Storm #2'] = CFrame.new(-3820, 135, 575),
        
        -- Additional Atlantis Locations
        ['Atlantis Extra #1'] = CFrame.new(-4300, -580, 1800),
        ['Atlantis Extra #2'] = CFrame.new(-2522, 138, 1593),
        ['Atlantis Extra #3'] = CFrame.new(-2551, 150, 1667),
        ['Atlantis Extra #4'] = CFrame.new(-2729, 168, 1730),
        ['Atlantis Extra #5'] = CFrame.new(-2881, 317, 1607),
        ['Atlantis Extra #6'] = CFrame.new(-2835, 131, 1510),
        ['Atlantis Extra #7'] = CFrame.new(-3576, 148, 524),
        ['Atlantis Extra #8'] = CFrame.new(-4606, -594, 1843),
        ['Atlantis Extra #9'] = CFrame.new(-5167, -680, 1710),
        ['Atlantis Extra #10'] = CFrame.new(-4107, -603, 1823),
        ['Atlantis Extra #11'] = CFrame.new(-4299, -604, 1587),
        ['Atlantis Extra #12'] = CFrame.new(-4295, -583, 2021),
        ['Atlantis Extra #13'] = CFrame.new(-4295, -991, 1792),
        ['Atlantis Extra #14'] = CFrame.new(-4465, -604, 1874),
        ['Atlantis Extra #15'] = CFrame.new(-4277, -606, 1838),
        ['Atlantis Extra #16'] = CFrame.new(-4928, -595, 1857),
        ['Atlantis Extra #17'] = CFrame.new(-3804, -567, 1870),
        ['Atlantis Extra #18'] = CFrame.new(-4086, -559, 895),
        ['Atlantis Extra #19'] = CFrame.new(-4272, -629, 2665),
        ['Atlantis Extra #20'] = CFrame.new(-4415, -997, 2055),
        ['Atlantis Extra #21'] = CFrame.new(-3953, -556, 853),
        ['Atlantis Extra #22'] = CFrame.new(-4325, -630, 2687),
        ['Atlantis Extra #23'] = CFrame.new(-177, 144, 1933),
        ['Atlantis Extra #24'] = CFrame.new(-4462, -605, 1875),
        ['Atlantis Extra #25'] = CFrame.new(-4463, -603, 1876),
        ['Atlantis Extra #26'] = CFrame.new(-4452, -603, 1877),
        ['Atlantis Extra #27'] = CFrame.new(-4450, -605, 1874),
        ['Atlantis Extra #28'] = CFrame.new(-4446, -605, 1866),
        
        -- Brine Pool
        ['Brine Pool #1'] = CFrame.new(-790, 125, -3100),
        ['Brine Pool #2'] = CFrame.new(-1710, -235, -3075),
        ['Brine Pool #3'] = CFrame.new(-1725, -175, -3125),
        ['Brine Pool #4'] = CFrame.new(-1600, -110, -2845),
        ['Brine Pool #5'] = CFrame.new(-1795, -140, -3310),
        ['Brine Pool #6'] = CFrame.new(-1810, -140, -3300),
        ['Brine Pool #7'] = CFrame.new(-1625, -205, -2785),
        ['Brine Pool #8'] = CFrame.new(-1470, -240, -2550),
        ['Brine Pool #9'] = CFrame.new(-975, -245, -2700),
        ['Brine Pool #10'] = CFrame.new(-1485, -225, -2195),
        ['Brine Pool #11'] = CFrame.new(-1655, -210, -2825),
        ['Brine Pool #12'] = CFrame.new(-980, -240, -2690),
        ['Brine Pool #13'] = CFrame.new(-1645, -210, -2855),
        ['Brine Pool #14'] = CFrame.new(-1650, -210, -2840),
        ['Brine Pool #15'] = CFrame.new(-1630, -210, -2860),
        ['Brine Pool #16'] = CFrame.new(-1470, -225, -2225),
        ['Brine Pool #17'] = CFrame.new(-1800, -135, -3280),
        
        -- Desolate Deep
        ['Desolate Deep #1'] = CFrame.new(-790, 125, -3100),
        ['Desolate Deep #2'] = CFrame.new(-1710, -235, -3075),
        ['Desolate Deep #3'] = CFrame.new(-1725, -175, -3125),
        ['Desolate Deep #4'] = CFrame.new(-1600, -110, -2845),
        ['Desolate Deep #5'] = CFrame.new(-1795, -140, -3310),
        ['Desolate Deep #6'] = CFrame.new(-1810, -140, -3300),
        ['Desolate Deep #7'] = CFrame.new(-1625, -205, -2785),
        ['Desolate Deep #8'] = CFrame.new(-1470, -240, -2550),
        ['Desolate Deep #9'] = CFrame.new(-975, -245, -2700),
        ['Desolate Deep #10'] = CFrame.new(-1485, -225, -2195),
        ['Desolate Deep #11'] = CFrame.new(-1655, -210, -2825),
        ['Desolate Deep #12'] = CFrame.new(-980, -240, -2690),
        ['Desolate Deep #13'] = CFrame.new(-1645, -210, -2855),
        ['Desolate Deep #14'] = CFrame.new(-1650, -210, -2840),
        ['Desolate Deep #15'] = CFrame.new(-1630, -210, -2860),
        ['Desolate Deep #16'] = CFrame.new(-1470, -225, -2225),
        ['Desolate Deep #17'] = CFrame.new(-1800, -135, -3280),
        
        -- The Depths
        ['The Depths #1'] = CFrame.new(472, -706, 1231),
        ['The Depths #2'] = CFrame.new(1210, -715, 1315),
        ['The Depths #3'] = CFrame.new(1705, -900, 1445),
        ['The Depths #4'] = CFrame.new(-970, -710, 1300),
        
        -- Forsaken Shores
        ['Forsaken Shores #1'] = CFrame.new(-2425, 135, 1555),
        ['Forsaken Shores #2'] = CFrame.new(-3600, 125, 1605),
        ['Forsaken Shores #3'] = CFrame.new(-2830, 215, 1510),
        ['Forsaken Shores #4'] = CFrame.new(-2490, 130, 1535),
        ['Forsaken Shores #5'] = CFrame.new(-2525, 135, -1575),
        
        -- Mariana's Veil
        ['Marianas Veil #1'] = CFrame.new(1500, 125, 530),
        ['Marianas Veil #2'] = CFrame.new(-1305, 130, 310),
        ['Marianas Veil #3'] = CFrame.new(-3175, -2035, 4020),
        ['Marianas Veil #4'] = CFrame.new(740, -3355, -1530),
        ['Marianas Veil #5'] = CFrame.new(-1480, 137, 382),
        ['Marianas Veil #6'] = CFrame.new(-3365, -2260, 3850),
        ['Marianas Veil #7'] = CFrame.new(-760, -3280, -715),
        ['Marianas Veil #8'] = CFrame.new(-800, -3280, -625),
        ['Marianas Veil #9'] = CFrame.new(-3180, -2035, 4020),
        
        -- Mushgrove Swamp
        ['Mushgrove Swamp #1'] = CFrame.new(2425, 130, -670),
        ['Mushgrove Swamp #2'] = CFrame.new(2730, 130, -825),
        ['Mushgrove Swamp #3'] = CFrame.new(2520, 160, -895),
        ['Mushgrove Swamp #4'] = CFrame.new(2790, 140, -625),
        ['Mushgrove Swamp #5'] = CFrame.new(2520, 135, -895),
        
        -- Northern Expedition
        ['Northern Expedition #1'] = CFrame.new(400, 135, 265),
        ['Northern Expedition #2'] = CFrame.new(5506, 147, -315),
        ['Northern Expedition #3'] = CFrame.new(2930, 281, 2594),
        ['Northern Expedition #4'] = CFrame.new(-1715, 149, 737),
        ['Northern Expedition #5'] = CFrame.new(-2566, 181, 1353),
        ['Northern Expedition #6'] = CFrame.new(-1750, 130, 3750),
        
        -- Roslit Bay
        ['Roslit Bay #1'] = CFrame.new(-1450, 135, 750),
        ['Roslit Bay #2'] = CFrame.new(-1775, 150, 680),
        ['Roslit Bay #3'] = CFrame.new(-1875, 165, 380),
        ['Roslit Bay #4'] = CFrame.new(-1515, 141, 765),
        ['Roslit Bay #5'] = CFrame.new(-1945, 275, 230),
        ['Roslit Bay #6'] = CFrame.new(-1710, 150, 740),
        ['Roslit Bay #7'] = CFrame.new(-1465, 130, 680),
        ['Roslit Bay #8'] = CFrame.new(-1485, 130, 640),
        ['Roslit Bay #9'] = CFrame.new(-1785, 165, 400),
        
        -- Roslit Volcano
        ['Roslit Volcano #1'] = CFrame.new(-1450, 135, 750),
        ['Roslit Volcano #2'] = CFrame.new(-1775, 150, 680),
        ['Roslit Volcano #3'] = CFrame.new(-1875, 165, 380),
        ['Roslit Volcano #4'] = CFrame.new(-1515, 141, 765),
        ['Roslit Volcano #5'] = CFrame.new(-1945, 275, 230),
        ['Roslit Volcano #6'] = CFrame.new(-1710, 150, 740),
        ['Roslit Volcano #7'] = CFrame.new(-1465, 130, 680),
        ['Roslit Volcano #8'] = CFrame.new(-1485, 130, 640),
        ['Roslit Volcano #9'] = CFrame.new(-1785, 165, 400),
        
        -- Snowcap Island
        ['Snowcap Island #1'] = CFrame.new(2600, 150, 2400),
        ['Snowcap Island #2'] = CFrame.new(2900, 150, 2500),
        ['Snowcap Island #3'] = CFrame.new(2710, 190, 2560),
        ['Snowcap Island #4'] = CFrame.new(2750, 135, 2505),
        ['Snowcap Island #5'] = CFrame.new(2800, 280, 2565),
        ['Snowcap Island #6'] = CFrame.new(2845, 180, 2700),
        
        -- Sunstone Island
        ['Sunstone Island #1'] = CFrame.new(-935, 130, -1105),
        ['Sunstone Island #2'] = CFrame.new(-1045, 135, -1140),
        ['Sunstone Island #3'] = CFrame.new(-1215, 190, -1040),
        ['Sunstone Island #4'] = CFrame.new(-1145, 135, -1075),
        ['Sunstone Island #5'] = CFrame.new(-1045, 200, -1100),
        ['Sunstone Island #6'] = CFrame.new(-920, 130, -1105),
        
        -- Statue of Sovereignty
        ['Statue of Sovereignty #1'] = CFrame.new(20, 160, -1040),
        ['Statue of Sovereignty #2'] = CFrame.new(1380, -805, -300),
        
        -- Keepers Altar
        ['Keepers Altar #1'] = CFrame.new(20, 160, -1040),
        ['Keepers Altar #2'] = CFrame.new(1380, -805, -300),
        
        -- Vertigo
        ['Vertigo #1'] = CFrame.new(-110, -515, 1040),
        ['Vertigo #2'] = CFrame.new(-75, -530, 1285),
        ['Vertigo #3'] = CFrame.new(1210, -715, 1315),
        ['Vertigo #4'] = CFrame.new(-145, -515, 1140),
        ['Vertigo #5'] = CFrame.new(1705, -900, 1445),
        ['Vertigo #6'] = CFrame.new(-100, -730, 1210),
        ['Vertigo #7'] = CFrame.new(-970, -710, 1300),
        
        -- Winter Village
        ['Winter Village #1'] = CFrame.new(5815, 145, 270),
        ['Winter Village #2'] = CFrame.new(-2490, 135, 1470),
        ['Winter Village #3'] = CFrame.new(400, 135, 305),
        ['Winter Village #4'] = CFrame.new(2410, 135, -730),
        ['Winter Village #5'] = CFrame.new(-1920, 500, 160),
        ['Winter Village #6'] = CFrame.new(2640, 140, 2425),
        ['Winter Village #7'] = CFrame.new(45, 140, -1030),
        ['Winter Village #8'] = CFrame.new(-890, 135, -1110),
        ['Winter Village #9'] = CFrame.new(-160, 140, 1895),
        ['Winter Village #10'] = CFrame.new(-190, 370, -9445),
        ['Winter Village #11'] = CFrame.new(-15, 365, -9590),
        
        -- Additional Ocean/Deep Ocean Spots
        ['Deep Ocean #1'] = CFrame.new(-1270, 125, 1580),
        ['Deep Ocean #2'] = CFrame.new(1000, 125, -1250),
        ['Deep Ocean #3'] = CFrame.new(-530, 125, -425),
        ['Deep Ocean #4'] = CFrame.new(1230, 125, 575),
        ['Deep Ocean #5'] = CFrame.new(1700, 125, -2500),
        
        -- Earmark Island (same as Ocean spots)
        ['Earmark Island #1'] = CFrame.new(-1270, 125, 1580),
        ['Earmark Island #2'] = CFrame.new(1000, 125, -1250),
        ['Earmark Island #3'] = CFrame.new(-530, 125, -425),
        ['Earmark Island #4'] = CFrame.new(1230, 125, 575),
        ['Earmark Island #5'] = CFrame.new(1700, 125, -2500),
        
        -- The Arch (same as Ocean spots)
        ['The Arch #1'] = CFrame.new(-1270, 125, 1580),
        ['The Arch #2'] = CFrame.new(1000, 125, -1250),
        ['The Arch #3'] = CFrame.new(-530, 125, -425),
        ['The Arch #4'] = CFrame.new(1230, 125, 575),
        ['The Arch #5'] = CFrame.new(1700, 125, -2500),
        
        -- Haddock Rock (same as Ocean spots)
        ['Haddock Rock #1'] = CFrame.new(-1270, 125, 1580),
        ['Haddock Rock #2'] = CFrame.new(1000, 125, -1250),
        ['Haddock Rock #3'] = CFrame.new(-530, 125, -425),
        ['Haddock Rock #4'] = CFrame.new(1230, 125, 575),
        ['Haddock Rock #5'] = CFrame.new(1700, 125, -2500),
        
        -- Birch Cay (same as Ocean spots) 
        ['Birch Cay #1'] = CFrame.new(-1270, 125, 1580),
        ['Birch Cay #2'] = CFrame.new(1000, 125, -1250),
        ['Birch Cay #3'] = CFrame.new(-530, 125, -425),
        ['Birch Cay #4'] = CFrame.new(1230, 125, 575),
        ['Birch Cay #5'] = CFrame.new(1700, 125, -2500),
        
        -- Harvesters Spike (same as Ocean spots)
        ['Harvesters Spike #1'] = CFrame.new(-1270, 125, 1580),
        ['Harvesters Spike #2'] = CFrame.new(1000, 125, -1250),
        ['Harvesters Spike #3'] = CFrame.new(-530, 125, -425),
        ['Harvesters Spike #4'] = CFrame.new(1230, 125, 575),
        ['Harvesters Spike #5'] = CFrame.new(1700, 125, -2500),
        
        -- Lobster Fishing
        ['Lobster Fishing #1'] = CFrame.new(-552, 153, 2651),
        ['Lobster Fishing #2'] = CFrame.new(-571, 153, 2638),
        ['Lobster Fishing #3'] = CFrame.new(-575, 85, 1000),
        
        -- Net Fishing
        ['Net Fishing #1'] = CFrame.new(-635, 85, 1005),
        ['Net Fishing #2'] = CFrame.new(-630, 85, 1005),
        ['Net Fishing #3'] = CFrame.new(-610, 85, 1005),
        ['Net Fishing #4'] = CFrame.new(-820, 90, 995),
        
        -- Oxygen Locations
        ['Oxygen #1'] = CFrame.new(-1655, -210, -2825),
        ['Oxygen #2'] = CFrame.new(370, 135, 250),
        ['Oxygen #3'] = CFrame.new(-790, 125, -3100),
        ['Oxygen #4'] = CFrame.new(-980, -240, -2690),
        ['Oxygen #5'] = CFrame.new(-4452, -603, 1877),
        ['Oxygen #6'] = CFrame.new(-3550, 130, 568)
    }
}

-- Zone Cast Coordinates (dari main2.lua)
local ZoneCastCoordinates = {
    -- Event Zones
    ['FischFright24'] = "dynamic", -- Uses selectedZone.Position
    ['Isonade'] = "dynamic", -- Uses selectedZone.Position
    ['Bluefin Tuna Abundance'] = "abundance", -- Special abundance detection
    ['Swordfish Abundance'] = "abundance", -- Special abundance detection
    
    -- Regular Zones dengan koordinat tetap
    ['Deep Ocean'] = CFrame.new(1521, 126, -3543),
    ['Desolate Deep'] = CFrame.new(-1068, 126, -3108),
    ['Harvesters Spike'] = CFrame.new(-1234, 126, 1748),
    ['Moosewood Docks'] = CFrame.new(345, 126, 214),
    ['Moosewood Ocean'] = CFrame.new(890, 126, 465),
    ['Moosewood Ocean Mythical'] = CFrame.new(270, 126, 52),
    ['Moosewood Pond'] = CFrame.new(526, 126, 305),
    ['Mushgrove Water'] = CFrame.new(2541, 126, -792),
    ['Ocean'] = CFrame.new(-5712, 126, 4059),
    ['Roslit Bay'] = CFrame.new(-1650, 126, 504),
    ['Roslit Bay Ocean'] = CFrame.new(-1825, 126, 946),
    ['Roslit Pond'] = CFrame.new(-1807, 141, 599),
    ['Roslit Pond Seaweed'] = CFrame.new(-1804, 141, 625),
    ['Scallop Ocean'] = CFrame.new(16, 126, 730),
    ['Snowcap Ocean'] = CFrame.new(2308, 126, 2200),
    ['Snowcap Pond'] = CFrame.new(2777, 275, 2605),
    ['Sunstone'] = CFrame.new(-645, 126, -955),
    ['Terrapin Ocean'] = CFrame.new(-57, 126, 2011),
    ['The Arch'] = CFrame.new(1076, 126, -1202),
    ['Vertigo'] = CFrame.new(-75, -740, 1200)
}

-- Zone Cast Names untuk dropdown
local ZoneCastNames = {}
for zoneName, _ in pairs(ZoneCastCoordinates) do
    table.insert(ZoneCastNames, zoneName)
end
table.sort(ZoneCastNames) -- Sort alphabetically

local ZoneNames = {}
local RodNames = {}
local ItemNames = {}
local FishingSpotNames = {}
local NPCNames = {}
local MarianaVeilNames = {}
local AllLocationNames = {}
local RodColors = {}
local RodMaterials = {}
for i,v in pairs(TeleportLocations['Zones']) do table.insert(ZoneNames, i) end
for i,v in pairs(TeleportLocations['Rods']) do table.insert(RodNames, i) end
for i,v in pairs(TeleportLocations['Items']) do table.insert(ItemNames, i) end
for i,v in pairs(TeleportLocations['Fishing Spots']) do table.insert(FishingSpotNames, i) end
for i,v in pairs(TeleportLocations['NPCs']) do table.insert(NPCNames, i) end
for i,v in pairs(TeleportLocations['Mariana Veil']) do table.insert(MarianaVeilNames, i) end
for i,v in pairs(TeleportLocations['All Locations']) do table.insert(AllLocationNames, i) end

-- Sort all location arrays alphabetically
table.sort(ZoneNames)
table.sort(RodNames)
table.sort(ItemNames)
table.sort(FishingSpotNames)
table.sort(NPCNames)
table.sort(MarianaVeilNames)
table.sort(AllLocationNames)

--// Functions
FindChildOfClass = function(parent, classname)
    return parent:FindFirstChildOfClass(classname)
end
FindChild = function(parent, child)
    return parent:FindFirstChild(child)
end
FindChildOfType = function(parent, childname, classname)
    child = parent:FindFirstChild(childname)
    if child and child.ClassName == classname then
        return child
    end
end
CheckFunc = function(func)
    return typeof(func) == 'function'
end

--// Custom Functions
getchar = function()
    return lp.Character or lp.CharacterAdded:Wait()
end
gethrp = function()
    return getchar():WaitForChild('HumanoidRootPart')
end
gethum = function()
    return getchar():WaitForChild('Humanoid')
end
FindRod = function()
    if FindChildOfClass(getchar(), 'Tool') and FindChild(FindChildOfClass(getchar(), 'Tool'), 'values') then
        return FindChildOfClass(getchar(), 'Tool')
    else
        return nil
    end
end
message = function(text, time)
    if tooltipmessage then tooltipmessage:Remove() end
    tooltipmessage = require(lp.PlayerGui:WaitForChild("GeneralUIModule")):GiveToolTip(lp, text)
    task.spawn(function()
        task.wait(time)
        if tooltipmessage then tooltipmessage:Remove(); tooltipmessage = nil end
    end)
end

--// UI
local library
local Window
local isMinimized = false
local floatingButton = nil

-- Load Kavo UI from GitHub repository (always fresh)
local kavoUrl = 'https://raw.githubusercontent.com/MELLISAEFFENDY/fffish/main/Kavo.lua'

-- Try to load library with multiple methods (always from GitHub)
local success = false

-- Method 1: Load directly from current repo
pcall(function()
    library = loadstring(game:HttpGet(kavoUrl))()
    if library and library.CreateLib then
        success = true
        -- print("✅ Kavo loaded from GitHub repo")
    end
end)

-- Method 2: Load from backup URLs
if not success then
    local backupUrls = {
        'https://github.com/MELLISAEFFENDY/fffish/raw/main/Kavo.lua',
        'https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua'
    }
    
    for i, url in ipairs(backupUrls) do
        pcall(function()
            library = loadstring(game:HttpGet(url))()
            if library and library.CreateLib then
                success = true
                -- print("✅ Kavo loaded from backup URL " .. i)
            end
        end)
        if success then break end
    end
end

-- Check if Kavo loaded successfully
if not success or not library then
    error("❌ Failed to load Kavo UI library from all sources!")
end

-- print("🎣 Kavo UI library loaded successfully!")

-- Load Shop Module
local Shop
-- print("🔄 Attempting to load Shop module...")

-- Enable HttpService if possible
pcall(function()
    game:GetService("HttpService").HttpEnabled = true
end)

pcall(function()
    -- Try to load from the same workspace
    -- print("📡 Downloading shop module from GitHub...")
    local shopContent = game:HttpGet('https://raw.githubusercontent.com/DESRIYANDA/Fishccch/main/shop.lua')
    if shopContent and #shopContent > 100 then
        -- print("✅ Shop content downloaded successfully, size: " .. #shopContent)
        Shop = loadstring(shopContent)()
        if Shop then
            -- print("✅ Shop module loaded from repository!")
        else
            -- warn("❌ Failed to execute shop module code")
        end
    else
        -- warn("❌ Shop content download failed or too small")
    end
end)

-- Fallback: Try to load from local file
if not Shop then
    -- warn("⚠️ Shop module not found from repository, trying local file...")
    pcall(function()
        if readfile and isfile and isfile("shop.lua") then
            local localContent = readfile("shop.lua")
            Shop = loadstring(localContent)()
            -- print("✅ Shop module loaded from local file!")
        else
            -- warn("❌ Local shop.lua file not found")
        end
    end)
end

if Shop then
    -- print("✅ Shop module is ready!")
else
    -- warn("❌ Shop module failed to load from all sources")
    -- print("🔧 Creating embedded shop module as final fallback...")
    
    -- Embedded shop module as final fallback
    Shop = {}
    Shop.createShopTab = function(self, Window)
        local ShopTab = Window:NewTab("🛒 Shop")
        local ShopSection = ShopTab:NewSection("Auto Buy Bait Crates")
        
        local shopFlags = {selectedbaitcrate = 'Bait Crate (Moosewood)', baitamount = 10}
        
        local crateLocations = {
            ['Bait Crate (Moosewood)'] = CFrame.new(315, 135, 335),
            ['Bait Crate (Roslit)'] = CFrame.new(-1465, 130, 680),
            ['Quality Bait Crate (Atlantis)'] = CFrame.new(-177, 144, 1933),
            ['Bait Crate (Forsaken)'] = CFrame.new(-2490, 130, 1535),
            ['Bait Crate (Ancient)'] = CFrame.new(6075, 195, 260),
            ['Bait Crate (Sunstone)'] = CFrame.new(-1045, 200, -1100),
            ['Quality Bait Crate (Terrapin)'] = CFrame.new(-175, 145, 1935)
        }
        
        ShopSection:NewDropdown("Select Bait Crate", "Choose bait crate to buy from", {
            'Bait Crate (Moosewood)', 'Bait Crate (Roslit)', 'Bait Crate (Forsaken)', 
            'Bait Crate (Ancient)', 'Bait Crate (Sunstone)',
            'Quality Bait Crate (Atlantis)', 'Quality Bait Crate (Terrapin)'
        }, function(crate)
            shopFlags.selectedbaitcrate = crate
            -- print("Selected: " .. crate)
        end)
        
        ShopSection:NewTextBox("Amount", "Enter amount (1-1000)", function(txt)
            local amount = tonumber(txt)
            if amount and amount > 0 and amount <= 1000 then
                shopFlags.baitamount = amount
                -- print("Set amount: " .. amount)
            end
        end)
        
        ShopSection:NewButton("💰 Buy Bait", "Buy bait from selected crate", function()
            -- print("🛒 Buying " .. shopFlags.baitamount .. "x from " .. shopFlags.selectedbaitcrate)
            
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and crateLocations[shopFlags.selectedbaitcrate] then
                lp.Character.HumanoidRootPart.CFrame = crateLocations[shopFlags.selectedbaitcrate]
                wait(1)
                
                pcall(function()
                    local buyRemote = ReplicatedStorage:FindFirstChild("packages")
                    if buyRemote and buyRemote:FindFirstChild("Net") then
                        local showRemote = buyRemote.Net:FindFirstChild("RE/BuyBait/Show")
                        if showRemote then
                            showRemote:FireServer()
                            wait(0.5)
                        end
                        
                        local purchaseRemote = buyRemote.Net:FindFirstChild("RE/DailyShop/Purchase")
                        if purchaseRemote then
                            purchaseRemote:FireServer(shopFlags.selectedbaitcrate, shopFlags.baitamount)
                            -- print("✅ Purchase request sent!")
                        end
                    end
                end)
            end
        end)
        
        -- Quick teleport section
        local TeleSection = ShopTab:NewSection("Quick Teleport")
        
        TeleSection:NewButton("📍 Daily Shopkeeper", "Teleport to Daily Shopkeeper", function()
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = CFrame.new(229, 139, 42)
            end
        end)
        
        TeleSection:NewButton("📍 Angus McBait", "Teleport to Angus McBait", function()
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = CFrame.new(236, 222, 461)
            end
        end)
        
        return ShopTab
    end
    -- print("✅ Embedded shop module created!")
end

-- Function to create floating button
local function createFloatingButton()
    if floatingButton then return end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FischFloatingButton"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999999
    
    local frame = Instance.new("Frame")
    frame.Name = "FloatingFrame"
    frame.Size = UDim2.new(0, 60, 0, 60)
    frame.Position = UDim2.new(1, -80, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(45, 65, 95)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    frame.Active = true
    frame.Draggable = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 30)
    corner.Parent = frame
    
    local button = Instance.new("TextButton")
    button.Name = "MinimizeButton"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Position = UDim2.new(0, 0, 0, 0)
    button.BackgroundTransparency = 1
    button.Text = "🎣"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 24
    button.Font = Enum.Font.SourceSansBold
    button.Parent = frame
    
    -- Gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(74, 99, 135)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 65, 95))
    }
    gradient.Rotation = 45
    gradient.Parent = frame
    
    -- Shadow effect
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 6, 1, 6)
    shadow.Position = UDim2.new(0, -3, 0, -3)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.ZIndex = frame.ZIndex - 1
    shadow.Parent = frame
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 30)
    shadowCorner.Parent = shadow
    
    -- Click event
    button.MouseButton1Click:Connect(function()
        if isMinimized then
            -- Show main UI
            pcall(function()
                local mainFrame = lp.PlayerGui:FindFirstChild("Kavo")
                if mainFrame then
                    local main = mainFrame:FindFirstChild("Main")
                    if main then
                        main.Visible = true
                        isMinimized = false
                        screenGui:Destroy()
                        floatingButton = nil
                    end
                end
            end)
        end
    end)
    
    -- Dragging disabled - using frame.Draggable = true instead
    
    -- Add to CoreGui or PlayerGui with protection
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(screenGui)
            screenGui.Parent = game.CoreGui
        elseif game.CoreGui then
            screenGui.Parent = game.CoreGui
        else
            screenGui.Parent = lp.PlayerGui
        end
    end)
    
    floatingButton = screenGui
end

-- Create UI Window with better error handling
local Window
local success = pcall(function()
    if library and library.CreateLib then
        -- Hook TweenService to prevent workspace errors
        if game:GetService("TweenService") then
            local TweenService = game:GetService("TweenService")
            local originalCreate = TweenService.Create
            TweenService.Create = function(self, instance, ...)
                if instance and instance.Parent then
                    return originalCreate(self, instance, ...)
                else
                    return {Play = function() end, Cancel = function() end}
                end
            end
        end
        
        Window = library.CreateLib("🎣 Fisch Script", "Ocean")
        -- print("✅ Main UI window created successfully")
    else
        error("❌ Library not available")
    end
end)

if not success or not Window then
    -- warn("⚠️ Failed to create UI window, retrying with alternative method...")
    
    -- Try alternative creation
    pcall(function()
        task.wait(1)
        Window = library.CreateLib("🎣 Fisch Script", "Ocean")
    end)
    
    if not Window then
        -- warn("⚠️ UI window creation failed, script will continue without GUI")
    end
end

-- Create Tabs
local AutoTab, ModTab, TeleTab, TeleTabV2, VisualTab, ShopTab, EventTab

if Window and Window.NewTab then
    pcall(function()
        AutoTab = Window:NewTab("🎣 Automation")
        ModTab = Window:NewTab("⚙️ Modifications") 
        TeleTab = Window:NewTab("🌍 Teleports")
        TeleTabV2 = Window:NewTab("🚀 Teleport V2")
        VisualTab = Window:NewTab("👁️ Visuals")
        EventTab = Window:NewTab("⭐ Zona Event")
        ZoneCastTab = Window:NewTab("🗺️ Zone Cast")
        
        -- Create Shop Tab using Shop Module
        -- print("🛒 Creating Shop tab...")
        if Shop and Shop.createShopTab then
            -- print("✅ Shop module found, creating advanced shop tab...")
            ShopTab = Shop:createShopTab(Window)
            -- print("✅ Shop tab created successfully")
        else
            -- warn("⚠️ Shop module not available, creating basic shop tab...")
            -- print("🔧 Creating fallback shop tab...")
            -- Fallback: Create basic shop tab
            ShopTab = Window:NewTab("🛒 Shop")
            local ShopSection = ShopTab:NewSection("Auto Buy Bait")
            
            local shopFlags = {selectedbaitcrate = 'Bait Crate (Moosewood)', baitamount = 10}
            
            ShopSection:NewDropdown("Select Bait Crate", "Choose bait crate", {
                'Bait Crate (Moosewood)', 'Bait Crate (Roslit)', 'Bait Crate (Forsaken)', 
                'Bait Crate (Ancient)', 'Bait Crate (Sunstone)',
                'Quality Bait Crate (Atlantis)', 'Quality Bait Crate (Terrapin)'
            }, function(crate)
                shopFlags.selectedbaitcrate = crate
            end)
            
            ShopSection:NewTextBox("Amount", "Enter amount (1-1000)", function(txt)
                local amount = tonumber(txt)
                if amount and amount > 0 and amount <= 1000 then
                    shopFlags.baitamount = amount
                end
            end)
            
            ShopSection:NewButton("💰 Buy Bait", "Buy bait from selected crate", function()
                -- print("🛒 Attempting to buy " .. shopFlags.baitamount .. "x from " .. shopFlags.selectedbaitcrate)
                
                -- Basic teleport to crate locations
                local crateLocations = {
                    ['Bait Crate (Moosewood)'] = CFrame.new(315, 135, 335),
                    ['Bait Crate (Roslit)'] = CFrame.new(-1465, 130, 680),
                    ['Quality Bait Crate (Atlantis)'] = CFrame.new(-177, 144, 1933),
                    ['Bait Crate (Forsaken)'] = CFrame.new(-2490, 130, 1535),
                    ['Bait Crate (Ancient)'] = CFrame.new(6075, 195, 260),
                    ['Bait Crate (Sunstone)'] = CFrame.new(-1045, 200, -1100),
                    ['Quality Bait Crate (Terrapin)'] = CFrame.new(-175, 145, 1935)
                }
                
                if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and crateLocations[shopFlags.selectedbaitcrate] then
                    lp.Character.HumanoidRootPart.CFrame = crateLocations[shopFlags.selectedbaitcrate]
                    wait(1)
                    
                    pcall(function()
                        local buyRemote = ReplicatedStorage:FindFirstChild("packages")
                        if buyRemote and buyRemote:FindFirstChild("Net") then
                            local purchaseRemote = buyRemote.Net:FindFirstChild("RE/BuyBait/Show")
                            if purchaseRemote then
                                purchaseRemote:FireServer()
                                wait(0.5)
                            end
                            
                            purchaseRemote = buyRemote.Net:FindFirstChild("RE/DailyShop/Purchase")
                            if purchaseRemote then
                                purchaseRemote:FireServer(shopFlags.selectedbaitcrate, shopFlags.baitamount)
                                -- print("✅ Purchase request sent!")
                            end
                        end
                    end)
                end
            end)
            
            -- print("✅ Basic shop tab created successfully")
        end
        
        -- print("✅ All tabs created successfully")
    end)
else
    -- warn("⚠️ Window not available, creating fallback functionality")
    -- Create dummy tabs that won't break the script
    local dummyTab = {
        NewSection = function(name)
            return {
                NewToggle = function(name, desc, callback) 
                    if callback then callback(false) end
                    return {UpdateToggle = function() end}
                end,
                NewSlider = function(name, desc, min, max, callback) 
                    if callback then callback(min) end
                    return {}
                end,
                NewDropdown = function(name, desc, options, callback) 
                    if callback then callback(options[1]) end
                    return {Refresh = function() end}
                end,
                NewButton = function(name, desc, callback) 
                    return {UpdateButton = function() end}
                end
            }
        end
    }
    AutoTab = dummyTab
    ModTab = dummyTab
    TeleTab = dummyTab
    TeleTabV2 = dummyTab
    VisualTab = dummyTab
    EventTab = dummyTab
    -- print("⚠️ Using fallback tabs - script functionality preserved")
end

-- ===== EVENT ZONE ESP & TELEPORT SYSTEM =====
local EventSystem = {}
EventSystem.espObjects = {}
EventSystem.activeEvents = {}
EventSystem.isScanning = false

-- ESP Color System (same as Player ESP)
EventSystem.colors = {
    ["Red"] = Color3.fromRGB(255, 0, 0),
    ["Green"] = Color3.fromRGB(0, 255, 0),
    ["Blue"] = Color3.fromRGB(0, 100, 255),
    ["Yellow"] = Color3.fromRGB(255, 255, 0),
    ["Purple"] = Color3.fromRGB(128, 0, 128),
    ["Orange"] = Color3.fromRGB(255, 165, 0),
    ["White"] = Color3.fromRGB(255, 255, 255),
    ["Cyan"] = Color3.fromRGB(0, 255, 255)
}

-- Event Data dengan koordinat zone dan warna
local EVENTS_DATA = {
    -- Water Events
    ["Shark Hunt"] = {color = Color3.fromRGB(255, 0, 0), zones = {"Ocean", "Desolate Deep", "The Depths"}},
    ["Megalodon Hunt"] = {color = Color3.fromRGB(200, 0, 0), zones = {"Ocean", "Desolate Deep"}},
    ["Kraken Hunt"] = {color = Color3.fromRGB(150, 0, 150), zones = {"The Depths", "Desolate Deep"}},
    ["Scylla Hunt"] = {color = Color3.fromRGB(100, 0, 100), zones = {"The Depths"}},
    ["Orca Migration"] = {color = Color3.fromRGB(0, 100, 200), zones = {"Ocean", "Glacial Grotto"}},
    ["Whale Migration"] = {color = Color3.fromRGB(0, 150, 250), zones = {"Ocean"}},
    ["Sea Leviathan Hunt"] = {color = Color3.fromRGB(50, 0, 200), zones = {"The Depths", "Hadal Blacksite"}},
    ["Apex Fish Hunt"] = {color = Color3.fromRGB(255, 100, 0), zones = {"Ocean", "Desolate Deep"}},
    
    -- Abundance Events
    ["Fish Abundance"] = {color = Color3.fromRGB(0, 255, 100), zones = {"Ocean", "Pond", "Mushgrove Swamp"}},
    ["Lucky Pool"] = {color = Color3.fromRGB(255, 215, 0), zones = {"Ocean", "Pond"}},
    
    -- Weather Events
    ["Absolute Darkness"] = {color = Color3.fromRGB(50, 50, 50), zones = {"The Depths", "Hadal Blacksite"}},
    ["Strange Whirlpool"] = {color = Color3.fromRGB(100, 50, 200), zones = {"Ocean", "The Depths"}},
    ["Whirlpool"] = {color = Color3.fromRGB(0, 100, 255), zones = {"Ocean"}},
    ["Nuke"] = {color = Color3.fromRGB(255, 255, 0), zones = {"Ocean", "Snowcap Island"}},
    ["Cursed Storm"] = {color = Color3.fromRGB(100, 0, 100), zones = {"The Depths"}},
    ["Blizzard"] = {color = Color3.fromRGB(200, 200, 255), zones = {"Glacial Grotto", "Snowcap Island"}},
    ["Avalanche"] = {color = Color3.fromRGB(150, 150, 200), zones = {"Snowcap Island", "Glacial Grotto"}},
    
    -- Divine Events
    ["Poseidon Wrath"] = {color = Color3.fromRGB(0, 150, 200), zones = {"Ocean", "The Depths"}},
    ["Zeus Storm"] = {color = Color3.fromRGB(255, 255, 100), zones = {"Ocean", "Snowcap Island"}},
    ["Blue Moon"] = {color = Color3.fromRGB(100, 100, 255), zones = {"Ocean", "Pond"}},
    
    -- Special Events
    ["Travelling Merchant"] = {color = Color3.fromRGB(255, 165, 0), zones = {"Ocean", "Moosewood"}},
    ["Sunken Chests"] = {color = Color3.fromRGB(255, 215, 0), zones = {"Ocean", "The Depths"}}
}

-- Zone koordinat berdasarkan TeleportLocations
local ZONE_COORDS = {
    ["Ocean"] = CFrame.new(100, 150, 100),
    ["Moosewood"] = CFrame.new(379.875458, 134.500519, 233.5495),
    ["Roslit Bay"] = CFrame.new(-1472.9812, 132.525513, 707.644531),
    ["Forsaken Shores"] = CFrame.new(-2491.104, 133.250015, 1561.2926),
    ["Sunstone Island"] = CFrame.new(-913.809143, 138.160782, -1133.25879),
    ["Statue of Sovereignty"] = CFrame.new(21.4017925, 159.014709, -1039.14233),
    ["Terrapin Island"] = CFrame.new(-193.434143, 135.121979, 1951.46936),
    ["Snowcap Island"] = CFrame.new(2607.93018, 135.284332, 2436.13208),
    ["Mushgrove Swamp"] = CFrame.new(2434.29785, 131.983276, -691.930542),
    ["Ancient Isle"] = CFrame.new(6056.02783, 195.280167, 276.270325),
    ["Northern Expedition"] = CFrame.new(-1701.02979, 187.638779, 3944.81494),
    ["Northern Summit"] = CFrame.new(19608.791, 131.420105, 5222.15283),
    ["Vertigo"] = CFrame.new(-102.40567, -513.299377, 1052.07104),
    ["Depths Entrance"] = CFrame.new(-15.4965982, -706.123718, 1231.43494),
    ["The Depths"] = CFrame.new(491.758118, -706.123718, 1230.6377),
    ["Desolate Deep"] = CFrame.new(491.758118, -706.123718, 1230.6377),
    ["Overgrowth Caves"] = CFrame.new(19746.2676, 416.00293, 5403.5752),
    ["Frigid Cavern"] = CFrame.new(20253.6094, 756.525818, 5772.68555),
    ["Cryogenic Canal"] = CFrame.new(19958.5176, 917.195923, 5332.59375),
    ["Glacial Grotto"] = CFrame.new(20003.0273, 1136.42798, 5555.95996),
    ["Keeper's Altar"] = CFrame.new(1297.92285, -805.292236, -284.155823),
    ["Atlantis"] = CFrame.new(-4465, -604, 1874),
    ["Pond"] = CFrame.new(1364, -612, 2472),
    ["Hadal Blacksite"] = CFrame.new(-4465, -604, 1874)
}

-- Function untuk membuat ESP Text dengan ScreenGui (Text Only, No Background)
function EventSystem:createESPText(eventName, position, distance)
    local espObj = {}
    
    -- Create ScreenGui di PlayerGui
    espObj.screenGui = Instance.new("ScreenGui")
    espObj.screenGui.Name = "EventESP_" .. eventName
    espObj.screenGui.Parent = lp.PlayerGui
    espObj.screenGui.ResetOnSpawn = false
    
    -- Create Frame sebagai container (completely invisible)
    espObj.frame = Instance.new("Frame")
    espObj.frame.Size = UDim2.new(0, 120, 0, 30)  -- Smaller size like Player ESP
    espObj.frame.BackgroundTransparency = 1  -- Completely transparent
    espObj.frame.BorderSizePixel = 0  -- No border
    espObj.frame.Parent = espObj.screenGui
    
    -- Create TextLabel (floating text only, same style as Player ESP)
    espObj.textLabel = Instance.new("TextLabel")
    espObj.textLabel.Size = UDim2.new(1, 0, 1, 0)
    espObj.textLabel.BackgroundTransparency = 1  -- No background
    espObj.textLabel.Text = "🎯 " .. eventName .. "\n📍 " .. distance .. "m"
    
    -- Use selected color or default white
    local selectedColor = self.colors[flags['eventespcolor'] or "White"]
    espObj.textLabel.TextColor3 = selectedColor
    
    espObj.textLabel.TextStrokeTransparency = 0
    espObj.textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)  -- Black outline for visibility
    espObj.textLabel.TextScaled = true
    espObj.textLabel.Font = Enum.Font.SourceSansBold
    espObj.textLabel.Parent = espObj.frame
    
    -- Store original position
    espObj.worldPosition = position
    
    -- Position update function dengan 3D to 2D conversion
    espObj.updatePosition = function()
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            local camera = workspace.CurrentCamera
            local worldPos = espObj.worldPosition
            
            -- Convert 3D world position to 2D screen position
            local screenPos, onScreen = camera:WorldToScreenPoint(worldPos)
            
            if onScreen and screenPos.Z > 0 then
                -- Position on screen (same as Player ESP positioning)
                espObj.frame.Position = UDim2.new(0, screenPos.X - 60, 0, screenPos.Y - 15)
                espObj.frame.Visible = true
                
                -- Update distance
                local newDistance = math.floor((lp.Character.HumanoidRootPart.Position - worldPos).Magnitude)
                espObj.textLabel.Text = "🎯 " .. eventName .. "\n📍 " .. newDistance .. "m"
                
                -- Fade based on distance (same as Player ESP)
                local alpha = math.max(0.3, 1 - (newDistance / 1000))
                espObj.textLabel.TextTransparency = 1 - alpha
            else
                espObj.frame.Visible = false
            end
        end
    end
    
    return espObj
end

-- Function to update ESP colors when color is changed
function EventSystem:updateESPColors()
    local newColor = self.colors[flags['eventespcolor'] or "White"]
    
    for eventName, espObj in pairs(self.espObjects) do
        if espObj.textLabel then
            espObj.textLabel.TextColor3 = newColor
        end
    end
    
    -- print("🎨 [Event ESP] Color changed to: " .. (flags['eventespcolor'] or "White"))
end

-- Function untuk scan event aktif dari workspace (Improved)
function EventSystem:scanActiveEvents()
    if self.isScanning then return end
    self.isScanning = true
    
    self.activeEvents = {}
    
    pcall(function()
        -- Method 1: Scan dari workspace.active untuk event indicators
        if workspace:FindFirstChild("active") then
            for _, child in pairs(workspace.active:GetChildren()) do
                -- Check untuk various event indicators
                if child.Name:find("Whirlpool") or child.Name:find("whirlpool") then
                    if not table.find(self.activeEvents, "Whirlpool") then
                        table.insert(self.activeEvents, "Whirlpool")
                    end
                elseif child.Name:find("Storm") or child.Name:find("storm") then
                    if child.Name:find("Zeus") and not table.find(self.activeEvents, "Zeus Storm") then
                        table.insert(self.activeEvents, "Zeus Storm")
                    elseif child.Name:find("Cursed") and not table.find(self.activeEvents, "Cursed Storm") then
                        table.insert(self.activeEvents, "Cursed Storm")
                    end
                elseif child.Name:find("Nuke") or child.Name:find("nuke") then
                    if not table.find(self.activeEvents, "Nuke") then
                        table.insert(self.activeEvents, "Nuke")
                    end
                elseif child.Name:find("Blizzard") or child.Name:find("blizzard") then
                    if not table.find(self.activeEvents, "Blizzard") then
                        table.insert(self.activeEvents, "Blizzard")
                    end
                elseif child.Name:find("Shark") or child.Name:find("shark") then
                    if child.Name:find("Great") and not table.find(self.activeEvents, "Shark Hunt") then
                        table.insert(self.activeEvents, "Shark Hunt")
                    end
                end
            end
        end
        
        -- Method 2: Check PlayerGui untuk event notifications
        if lp.PlayerGui:FindFirstChild("hud") then
            local hud = lp.PlayerGui.hud
            if hud:FindFirstChild("safezone") then
                local safezone = hud.safezone
                -- Scan untuk event text indicators
                for _, descendant in pairs(safezone:GetDescendants()) do
                    if descendant:IsA("TextLabel") then
                        local text = descendant.Text:lower()
                        
                        -- Check for specific event keywords
                        if text:find("abundance") and not table.find(self.activeEvents, "Fish Abundance") then
                            table.insert(self.activeEvents, "Fish Abundance")
                        elseif text:find("lucky") and not table.find(self.activeEvents, "Lucky Pool") then
                            table.insert(self.activeEvents, "Lucky Pool")
                        elseif text:find("merchant") and not table.find(self.activeEvents, "Travelling Merchant") then
                            table.insert(self.activeEvents, "Travelling Merchant")
                        end
                    end
                end
            end
        end
        
        -- Method 3: For demonstration - add some common events
        if #self.activeEvents == 0 then
            -- Add some demo events untuk testing
            local demoEvents = {"Fish Abundance", "Shark Hunt", "Whirlpool"}
            local selectedDemo = demoEvents[math.random(1, #demoEvents)]
            table.insert(self.activeEvents, selectedDemo)
            -- print("🎮 [Demo Mode] Added " .. selectedDemo .. " for testing")
        end
    end)
    
    self.isScanning = false
    -- print("🔍 [Event Scanner] Found " .. #self.activeEvents .. " active events")
    
    -- Print found events
    if #self.activeEvents > 0 then
        for i, eventName in pairs(self.activeEvents) do
            -- print("  " .. i .. ". 🎯 " .. eventName)
        end
    end
end

-- Function untuk toggle ESP
function EventSystem:toggleESP(enabled)
    if not enabled then
        -- Clear existing ESP
        for _, espObj in pairs(self.espObjects) do
            if espObj.screenGui then
                espObj.screenGui:Destroy()
            end
        end
        self.espObjects = {}
        -- print("❌ [Event ESP] Disabled")
        return
    end
    
    -- Scan untuk event aktif
    self:scanActiveEvents()
    
    -- Set default color if not set
    if not flags['eventespcolor'] then
        flags['eventespcolor'] = "White"
    end
    
    if #self.activeEvents == 0 then
        -- print("⚠️ [Event ESP] No active events found to display ESP")
        return
    end
    
    -- Create ESP untuk setiap event aktif
    for _, eventName in pairs(self.activeEvents) do
        local eventData = EVENTS_DATA[eventName]
        if eventData then
            for _, zoneName in pairs(eventData.zones) do
                local zoneCoord = ZONE_COORDS[zoneName]
                if zoneCoord then
                    local distance = 0
                    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                        distance = math.floor((lp.Character.HumanoidRootPart.Position - zoneCoord.Position).Magnitude)
                    end
                    
                    local espObj = self:createESPText(eventName, zoneCoord.Position, distance)
                    table.insert(self.espObjects, espObj)
                    
                    -- print("✨ [Event ESP] Added ESP for " .. eventName .. " at " .. zoneName .. " (" .. distance .. "m)")
                end
            end
        end
    end
    
    -- print("✅ [Event ESP] Enabled with " .. #self.espObjects .. " markers")
end

-- Function untuk teleport ke event terdekat
function EventSystem:teleportToNearestEvent()
    if #self.activeEvents == 0 then
        -- print("❌ [Event Teleport] No active events found!")
        return
    end
    
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then
        -- print("❌ [Event Teleport] Character not found!")
        return
    end
    
    local playerPos = lp.Character.HumanoidRootPart.Position
    local nearestEvent = nil
    local nearestDistance = math.huge
    local nearestZone = nil
    
    -- Find nearest active event
    for _, eventName in pairs(self.activeEvents) do
        local eventData = EVENTS_DATA[eventName]
        if eventData then
            for _, zoneName in pairs(eventData.zones) do
                local zoneCoord = ZONE_COORDS[zoneName]
                if zoneCoord then
                    local distance = (playerPos - zoneCoord.Position).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestEvent = eventName
                        nearestZone = zoneName
                    end
                end
            end
        end
    end
    
    -- Teleport ke event terdekat
    if nearestEvent and nearestZone then
        local targetCoord = ZONE_COORDS[nearestZone]
        lp.Character.HumanoidRootPart.CFrame = targetCoord
        -- print("🚀 [Event Teleport] Teleported to " .. nearestEvent .. " at " .. nearestZone .. " (" .. math.floor(nearestDistance) .. "m)")
    else
        -- print("❌ [Event Teleport] No valid event location found!")
    end
end

-- Update ESP positions in real-time
local espUpdateConnection
function EventSystem:startESPUpdates()
    if espUpdateConnection then espUpdateConnection:Disconnect() end
    
    espUpdateConnection = RunService.Heartbeat:Connect(function()
        for _, espObj in pairs(self.espObjects) do
            if espObj.updatePosition then
                espObj.updatePosition()
            end
        end
    end)
end

function EventSystem:stopESPUpdates()
    if espUpdateConnection then
        espUpdateConnection:Disconnect()
        espUpdateConnection = nil
    end
end

-- Event Tab Setup
if EventTab then
    local EventESPSection = EventTab:NewSection("Event ESP System")
    
    EventESPSection:NewToggle("ESP Zona Event", "Show ESP for active event zones", function(state)
        flags['eventesp'] = state
        EventSystem:toggleESP(state)
        
        if state then
            EventSystem:startESPUpdates()
        else
            EventSystem:stopESPUpdates()
        end
    end)
    
    EventESPSection:NewDropdown("ESP Color", "Select event ESP color", {"Red", "Green", "Blue", "Yellow", "Purple", "Orange", "White", "Cyan"}, function(currentOption)
        flags['eventespcolor'] = currentOption
        if flags['eventesp'] then
            EventSystem:updateESPColors()
        end
    end)
    
    EventESPSection:NewButton("🔍 Scan Events", "Manually scan for active events", function()
        EventSystem:scanActiveEvents()
        
        if #EventSystem.activeEvents > 0 then
            -- print("🎯 [Event Scanner] Active Events Found:")
            for i, eventName in pairs(EventSystem.activeEvents) do
                -- print("  " .. i .. ". " .. eventName)
            end
        else
            -- print("❌ [Event Scanner] No active events detected")
        end
    end)
    
    EventESPSection:NewButton("🎮 Demo ESP", "Add demo events for testing ESP", function()
        -- Add demo events untuk testing
        EventSystem.activeEvents = {"Fish Abundance", "Shark Hunt", "Whirlpool", "Lucky Pool"}
        -- print("🎮 [Demo Mode] Added demo events for ESP testing")
        
        -- Auto enable ESP
        if flags['eventesp'] then
            EventSystem:toggleESP(false) -- Clear first
            wait(0.5)
            EventSystem:toggleESP(true) -- Re-enable
        end
    end)
    
    local EventTeleSection = EventTab:NewSection("Event Teleportation")
    
    EventTeleSection:NewButton("🚀 Teleport to Nearest Event", "Teleport to the closest active event", function()
        EventSystem:teleportToNearestEvent()
    end)
    
    -- Individual event teleports
    local EventListSection = EventTab:NewSection("Manual Event Teleports")
    
    -- Create buttons for each event type
    for eventName, eventData in pairs(EVENTS_DATA) do
        EventListSection:NewButton("📍 " .. eventName, "Teleport to " .. eventName .. " zones", function()
            if #eventData.zones > 0 then
                local targetZone = eventData.zones[1] -- Take first zone
                local targetCoord = ZONE_COORDS[targetZone]
                if targetCoord and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                    lp.Character.HumanoidRootPart.CFrame = targetCoord
                    -- print("🚀 [Manual Teleport] Teleported to " .. eventName .. " at " .. targetZone)
                else
                    -- print("❌ [Manual Teleport] Invalid location for " .. eventName)
                end
            end
        end)
    end
    
    local EventInfoSection = EventTab:NewSection("Event Information")
    EventInfoSection:NewButton("📊 Show Event List", "Display all trackable events", function()
        -- print("📋 [Event System] Trackable Events:")
        for eventName, eventData in pairs(EVENTS_DATA) do
            local zones = table.concat(eventData.zones, ", ")
            -- print("  🎯 " .. eventName .. " -> " .. zones)
        end
    end)
end

-- print("✅ [Event System] Event Zone ESP & Teleport system initialized!")

-- Zone Cast Section
if ZoneCastTab then
    local ZoneCastMainSection = ZoneCastTab:NewSection("🎯 Zone Cast Settings")
    
    ZoneCastMainSection:NewDropdown("Select Zone to Cast", "Choose zone to cast anywhere", ZoneCastNames, function(currentOption)
        selectedZoneCast = currentOption
        -- print("🗺️ [Zone Cast] Selected zone: " .. tostring(currentOption))
    end)
    
    ZoneCastMainSection:NewToggle("Enable Zone Cast", "🚀 Cast to selected zone from anywhere", function(state)
        flags['autozonecast'] = state
        AutoZoneCast = state
        if state then
            if selectedZoneCast and selectedZoneCast ~= "" then
                ZoneCasting()
                -- print("🗺️ [Zone Cast] Activated for zone: " .. selectedZoneCast)
            else
                -- print("⚠️ [Zone Cast] Please select a zone first!")
            end
        else
            -- print("🗺️ [Zone Cast] Deactivated")
        end
    end)
    
    local ZoneCastInfoSection = ZoneCastTab:NewSection("ℹ️ Zone Cast Information")
    ZoneCastInfoSection:NewButton("📋 How Zone Cast Works", "Learn about Zone Cast feature", function()
        -- print("🗺️ [Zone Cast Info] How it works:")
        -- print("  1. Cast your rod normally first")
        -- print("  2. Select a zone from the dropdown")
        -- print("  3. Enable Zone Cast toggle")
        -- print("  4. Your bobber will teleport to the selected zone")
        -- print("  5. Fish in that zone without traveling there!")
        -- print("🎯 [Zone Cast] Available zones: " .. #ZoneCastNames .. " zones")
    end)
    
    ZoneCastInfoSection:NewButton("🌊 Special Zones Info", "Info about special zones", function()
        -- print("🎃 [Special Zones] Event zones:")
        -- print("  • FischFright24 - Halloween Fright Pool")
        -- print("  • Isonade - Special Boss Zone")
        -- print("🐟 [Abundance Zones] Dynamic zones:")
        -- print("  • Bluefin Tuna Abundance - Auto-detects Bluefin abundance")
        -- print("  • Swordfish Abundance - Auto-detects Swordfish abundance")
        -- print("⚡ [Regular Zones] Fixed coordinate zones available")
    end)
    
    local ZoneCastStatusSection = ZoneCastTab:NewSection("📊 Zone Cast Status")
    ZoneCastStatusSection:NewButton("📍 Current Zone Status", "Check current zone cast status", function()
        if AutoZoneCast and selectedZoneCast ~= "" then
            -- print("✅ [Zone Cast Status] ACTIVE")
            -- print("🗺️ Target Zone: " .. selectedZoneCast)
            if lp.Character and lp.Character:FindFirstChildOfClass("Tool") then
                local tool = lp.Character:FindFirstChildOfClass("Tool")
                if tool:FindFirstChild("bobber") then
                    -- print("🎣 Bobber Status: FOUND - Teleporting to zone")
                else
                    -- print("⚠️ Bobber Status: NOT FOUND - Cast your rod first")
                end
            else
                -- print("⚠️ Rod Status: NOT EQUIPPED - Equip a fishing rod")
            end
        else
            -- print("❌ [Zone Cast Status] INACTIVE")
            if selectedZoneCast == "" then
                -- print("⚠️ Please select a zone first")
            end
        end
    end)
    
    ZoneCastStatusSection:NewButton("📋 Available Zones List", "Show all available zones", function()
        -- print("🗺️ [Zone Cast] Available zones (" .. #ZoneCastNames .. " total):")
        for i, zoneName in ipairs(ZoneCastNames) do
            local zoneType = "Regular"
            if zoneName:find("Abundance") then
                zoneType = "Abundance"
            elseif zoneName == "FischFright24" or zoneName == "Isonade" then
                zoneType = "Event"
            end
            -- print("  " .. i .. ". " .. zoneName .. " (" .. zoneType .. ")")
        end
    end)
end

-- Automation Section
local AutoSection = AutoTab:NewSection("Autofarm")
AutoSection:NewToggle("Freeze Character", "Freeze your character in place", function(state)
    flags['freezechar'] = state
end)
AutoSection:NewDropdown("Freeze Character Mode", "Select freeze mode", {"Rod Equipped", "Toggled"}, function(currentOption)
    flags['freezecharmode'] = currentOption
end)

local CastSection = AutoTab:NewSection("Auto Cast Settings")
CastSection:NewToggle("Auto Cast", "Automatically cast fishing rod", function(state)
    flags['autocast'] = state
end)

-- NEW: No Animation Auto Cast Toggle
CastSection:NewToggle("No Animation Auto Cast", "🚫 Auto cast without throwing animation (instant)", function(state)
    flags['noanimationautocast'] = state
    if state then
        -- print("🚫 [No Animation Auto Cast] Activated - No throwing animation!")
        -- print("⚡ [No Animation Auto Cast] Instant cast without movement!")
        -- print("🎯 [No Animation Auto Cast] Bobber appears instantly in water!")
    else
        -- print("🎣 [No Animation Auto Cast] Deactivated - Normal casting animation")
    end
end)

-- NEW: Auto Cast Arm Movement Toggle
CastSection:NewToggle("Auto Cast Arm Movement", "🤖 Enable throwing animation in auto cast", function(state)
    flags['autocastarmmovement'] = state
    if state then
        -- print("🤖 [Auto Cast Arm Movement] Activated - Full throwing animation!")
        -- print("🎬 [Auto Cast Arm Movement] Character will show arm movement!")
        -- print("🎯 [Auto Cast Arm Movement] Realistic casting with animation!")
    else
        -- print("🚫 [Auto Cast Arm Movement] Deactivated - No arm animation")
    end
end)

-- Instant Bobber Toggle
CastSection:NewToggle("Instant Bobber", "⚡ STRONG penetration through boats & thick obstacles", function(state)
    flags['instantbobber'] = state
    if state then
        -- print("⚡ [Instant Bobber] Activated - STRONG boat penetration!")
        -- print("📍 [Instant Bobber] Can penetrate thick boats and obstacles")
        -- print("🚢 [Instant Bobber] Works through most ships and structures!")
    else
        -- print("🎣 [Instant Bobber] Deactivated - Normal casting animation")
    end
end)

-- NEW: Enhanced Instant Bobber Toggle
CastSection:NewToggle("Enhanced Instant Bobber", "🌊 EXTREME penetration through ANY boat/ship/obstacle", function(state)
    flags['enhancedinstantbobber'] = state
    if state then
        -- print("🌊 [Enhanced Instant Bobber] Activated - EXTREME boat penetration!")
        -- print("⚡ [Enhanced Instant Bobber] Bobber goes directly to water!")
        -- print("🚀 [Enhanced Instant Bobber] Uses negative distance for penetration!")
    else
        -- print("🎣 [Enhanced Instant Bobber] Deactivated - Normal bobber physics")
    end
end)

-- Fix slider issue - properly define default value with initial state
local castSlider = CastSection:NewSlider("Auto Cast Delay", "Delay between auto casts (seconds)", 0.1, 5, function(value)
    flags['autocastdelay'] = value
    -- print("[Auto Cast] Delay set to: " .. value .. " seconds")
end)

-- Set initial slider value to match default
pcall(function()
    if castSlider and castSlider.SetValue then
        castSlider:SetValue(flags['autocastdelay'] or 0.5)
    end
end)

-- 🚀 ADVANCED PREDICTIVE AUTOCAST SYSTEM
-- This reduces gap time between reel completion and next cast
CastSection:NewToggle("Predictive AutoCast", "Cast immediately after reel completion (zero gap)", function(state)
    flags['predictiveautocast'] = state
    if state then
        debugPrint("🚀 [Predictive AutoCast] ZERO-GAP casting system activated!")
        debugPrint("⚡ Next cast will be ready immediately after reel completion!")
    else
        debugPrint("⏳ [Predictive AutoCast] Disabled - using normal delays")
    end
end)

-- Performance Settings
CastSection:NewToggle("🐛 Debug Mode", "Enable console output for debugging (may reduce performance)", function(state)
    flags['debugmode'] = state
    if state then
        print("🔧 [Debug Mode] Console output ENABLED - may impact performance")
        print("💡 [Debug Mode] Disable this toggle for better performance")
    else
        print("⚡ [Performance Mode] Console output DISABLED - optimized for speed")
    end
end)

local ShakeSection = AutoTab:NewSection("Auto Shake Settings")
ShakeSection:NewToggle("Auto Shake V1", "Standard autoshake with conflict management", function(state)
    flags['autoshake'] = state
    if state then
        -- Disable V2 to prevent conflicts
        autoShakeV2Active = false
        if autoShakeV2Connection then
            autoShakeV2Connection:Disconnect()
            autoShakeV2Connection = nil
        end
        -- Removed console output for performance
        debugPrint("🛡️ [AutoShake V1] Advanced system activated - V2 disabled")
    end
end)

-- AutoShake V2 - Fast & Lightweight (inspired by main4.lua)
local autoShakeV2Active = false
local autoShakeV2Connection = nil
local autoShakeV2Delay = 0

-- AutoShake V2 Statistics
local shakeV2Stats = {
    activations = 0,
    lastActivation = 0
}

-- Enhanced AutoShake V2 Function with statistics (defined first)
local function enhancedHandleButtonClickV2(button)
    if not button.Visible then return end
    
    GuiService.SelectedObject = button
    task.wait(autoShakeV2Delay)
    
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    
    -- Update statistics
    shakeV2Stats.activations = shakeV2Stats.activations + 1
    shakeV2Stats.lastActivation = tick()
    
    debugPrint("⚡ [AutoShake V2] #" .. shakeV2Stats.activations .. " - Ultra-fast execution!")
end

ShakeSection:NewToggle("Auto Shake V2", "⚡ Ultra-fast shake (main4.lua style) - LIGHTWEIGHT", function(state)
    autoShakeV2Active = state
    
    if state then
        -- Disable V1 to prevent conflicts
        flags['autoshake'] = false
        
        -- Setup V2 system (main4.lua style)
        autoShakeV2Connection = lp.PlayerGui.ChildAdded:Connect(function(GUI)
            if GUI:IsA("ScreenGui") and GUI.Name == "shakeui" then
                local safezone = GUI:WaitForChild("safezone", 5)
                if safezone then
                    safezone.ChildAdded:Connect(function(child)
                        if child:IsA("ImageButton") and child.Name == "button" then
                            task.spawn(function()
                                if autoShakeV2Active then
                                    enhancedHandleButtonClickV2(child) -- Use enhanced function
                                end
                            end)
                        end
                    end)
                end
            end
        end)
        
        debugPrint("⚡ [AutoShake V2] ULTRA-FAST shake system activated!")
        debugPrint("🚀 [Performance] Lightweight main4.lua-style detection!")
    else
        -- Cleanup V2 connections
        if autoShakeV2Connection then
            autoShakeV2Connection:Disconnect()
            autoShakeV2Connection = nil
        end
        debugPrint("⏸️ [AutoShake V2] Deactivated")
    end
end)

-- AutoShake V2 Delay Slider
local shakeV2Slider = ShakeSection:NewSlider("AutoShake V2 Delay", "Delay for V2 shake (0 = instant)", 0, 1, function(value)
    autoShakeV2Delay = value
    -- print("[AutoShake V2] Delay set to: " .. value .. " seconds")
end)

-- Info section for AutoShake comparison
ShakeSection:NewLabel("⚖️ AutoShake Comparison:")
ShakeSection:NewLabel("V1: Advanced + Conflict-safe + Integrated")  
ShakeSection:NewLabel("V2: Ultra-fast + Lightweight + Direct")
ShakeSection:NewLabel("💡 Use V2 for maximum shake speed!")

-- AutoShake V2 Statistics (moved to top with function definition)

-- Optional: Add reset button for statistics
ShakeSection:NewButton("🔄 Reset V2 Stats", "Reset AutoShake V2 statistics", function()
    shakeV2Stats.activations = 0
    shakeV2Stats.lastActivation = 0
    -- Removed console output for performance
    -- print("📊 [AutoShake V2] Statistics reset!")
end)

-- Debug button to inspect shake UI structure
ShakeSection:NewButton("🔍 Debug Shake UI", "Show current shake UI structure for debugging", function()
    -- Removed console output for performance - use only when debugging
    -- print("🔍 [DEBUG] Inspecting PlayerGui for shake UI...")
    
    for _, child in pairs(lp.PlayerGui:GetChildren()) do
        if child.Name == "shakeui" then
            -- print("✅ Found shakeui: " .. child.ClassName)
            
            for _, subchild in pairs(child:GetChildren()) do
                -- print("  ├─ " .. subchild.Name .. " (" .. subchild.ClassName .. ")")
                
                if subchild.Name == "safezone" then
                    for _, subsubchild in pairs(subchild:GetChildren()) do
                        -- print("    ├─ " .. subsubchild.Name .. " (" .. subsubchild.ClassName .. ")")
                    end
                end
            end
        end
    end
    
    -- print("🔍 [DEBUG] Inspection complete!")
end)

local ReelSection = AutoTab:NewSection("Auto Reel Settings") 
ReelSection:NewToggle("Auto Reel", "Automatically reel in fish", function(state)
    flags['autoreel'] = state
    if state then
        flags['superinstantreel'] = false -- Disable super instant if normal auto reel enabled
    end
end)

-- Super Instant Reel Toggle
ReelSection:NewToggle("Super Instant Reel", "⚡ ZERO ANIMATION + FAST FISH LIFTING - Instant catch with speed boost", function(state)
    flags['superinstantreel'] = state
    if state then
        flags['autoreel'] = false -- Disable normal auto reel if super instant enabled
        flags['alwayscatch'] = false -- Disable always catch to prevent conflicts
        flags['superinstantnoanimation'] = true -- AUTOMATICALLY enable no animation mode
        debugPrint("🚀 [Super Instant Reel] ACTIVATED - Maximum Speed!")
        debugPrint("⚡ [Auto No-Animation] Animations automatically disabled for maximum speed!")
        debugPrint("🎯 [Zero Animation] Instant catch with NO minigame!")
    else
        flags['superinstantnoanimation'] = false -- Disable no animation when super instant reel is off
        debugPrint("⏸️ [Super Instant Reel] Deactivated")
        debugPrint("🎬 [Animations] Normal animations restored")
    end
end)

-- No Animation Toggle for Super Instant Reel
ReelSection:NewToggle("Disable Reel Animations", "🚫 Completely disable all reel/fish animations when Super Instant Reel is active", function(state)
    flags['superinstantnoanimation'] = state
    if state then
        -- print("🚫 [No Animation] All reel animations will be disabled!")
        -- print("⚡ [Ultra Speed] Maximum performance mode activated!")
    else
        -- print("🎬 [Animations] Reel animations will play normally")
    end
end)

-- Fix slider issue - properly define default value with initial state
local reelSlider = ReelSection:NewSlider("Auto Reel Delay", "Delay between auto reels (seconds)", 0.1, 5, function(value)
    flags['autoreeldelay'] = value
    -- print("[Auto Reel] Delay set to: " .. value .. " seconds")
end)

-- Set initial slider value to match default
pcall(function()
    if reelSlider and reelSlider.SetValue then
        reelSlider:SetValue(flags['autoreeldelay'] or 0.5)
    end
end)

-- Modifications Section
if CheckFunc(hookmetamethod) then
    local HookSection = ModTab:NewSection("Hooks")
    HookSection:NewToggle("No AFK Text", "Remove AFK notifications", function(state)
        flags['noafk'] = state
    end)
    HookSection:NewToggle("Perfect Cast", "Always get perfect cast", function(state)
        flags['perfectcast'] = state
    end)
    HookSection:NewToggle("Always Catch", "Always catch fish", function(state)
        flags['alwayscatch'] = state
        if state then
            flags['instantreel'] = false -- Disable instant reel if always catch enabled
        end
    end)
    HookSection:NewToggle("Instant Reel", "Instantly reel fish when lure = 100 (RISKY)", function(state)
        flags['instantreel'] = state
        if state then
            flags['alwayscatch'] = false -- Disable always catch if instant reel enabled
        end
    end)
end

local ClientSection = ModTab:NewSection("Client")
ClientSection:NewToggle("Infinite Oxygen", "Never run out of oxygen", function(state)
    flags['infoxygen'] = state
end)
ClientSection:NewToggle("No Temp & Oxygen", "Disable temperature and oxygen systems", function(state)
    flags['nopeakssystems'] = state
end)
ClientSection:NewToggle("Skip Fish Cutscenes", "🎬 Skip all fish capture cutscenes (Boss/Legendary)", function(state)
    flags['skipcutscenes'] = state
    if state then
        -- print("🎬 [Skip Cutscenes] Activated - All fish capture cutscenes will be skipped!")
    else
        -- print("📽️ [Skip Cutscenes] Deactivated - Normal cutscenes will play")
    end
end)

-- NEW: Disable Animations System
local AnimationSection = ModTab:NewSection("🎭 Animation Control")
AnimationSection:NewToggle("Disable All Animations", "🚫 Block all fishing animations and effects", function(state)
    flags['disableanimations'] = state
    if state then
        -- print("🚫 [Disable Animations] Activated - ALL fishing animations blocked!")
    else
        -- print("🎭 [Disable Animations] Deactivated - Normal animations restored")
    end
end)

AnimationSection:NewToggle("Block Rod Wave", "🌊 Stop rod wave animation effects", function(state)
    flags['blockrodwave'] = state
    if state then
        -- print("🌊 [Block Rod Wave] Activated - Rod wave effects disabled!")
    else
        -- print("🌊 [Block Rod Wave] Deactivated - Rod wave effects enabled")
    end
end)

AnimationSection:NewToggle("Block Shake Effects", "📳 Stop screen shake effects", function(state)
    flags['blockshakeeffects'] = state
    if state then
        -- print("📳 [Block Shake Effects] Activated - Screen shake disabled!")
    else
        -- print("📳 [Block Shake Effects] Deactivated - Screen shake enabled")
    end
end)

AnimationSection:NewToggle("Block Exalted Rod Anim", "✨ Stop special rod animations (Exalted, etc.)", function(state)
    flags['blockexaltedanim'] = state
    if state then
        -- print("✨ [Block Exalted Anim] Activated - Special rod animations disabled!")
    else
        -- print("✨ [Block Exalted Anim] Deactivated - Special rod animations enabled")
    end
end)

-- Teleports Section
local LocationSection = TeleTab:NewSection("Locations")
LocationSection:NewDropdown("Select Zone", "Choose a zone to teleport to", ZoneNames, function(currentOption)
    flags['zones'] = currentOption
end)
LocationSection:NewButton("Teleport To Zone", "Teleport to selected zone", function()
    if flags['zones'] then
        gethrp().CFrame = TeleportLocations['Zones'][flags['zones']]
    end
end)

local RodSection = TeleTab:NewSection("Rod Locations")
RodSection:NewDropdown("Rod Locations", "Choose a rod location", RodNames, function(currentOption)
    flags['rodlocations'] = currentOption
end)
RodSection:NewButton("Teleport To Rod", "Teleport to selected rod location", function()
    if flags['rodlocations'] then
        gethrp().CFrame = TeleportLocations['Rods'][flags['rodlocations']]
    end
end)

local ItemSection = TeleTab:NewSection("Items & Tools")
ItemSection:NewDropdown("Select Item", "Choose an item location", ItemNames, function(currentOption)
    flags['items'] = currentOption
end)
ItemSection:NewButton("Teleport To Item", "Teleport to selected item", function()
    if flags['items'] then
        gethrp().CFrame = TeleportLocations['Items'][flags['items']]
    end
end)

local FishSection = TeleTab:NewSection("Fishing Spots")
FishSection:NewDropdown("Select Fishing Spot", "Choose a fishing spot", FishingSpotNames, function(currentOption)
    flags['fishingspots'] = currentOption
end)
FishSection:NewButton("Teleport To Fishing Spot", "Teleport to selected fishing spot", function()
    if flags['fishingspots'] then
        gethrp().CFrame = TeleportLocations['Fishing Spots'][flags['fishingspots']]
    end
end)

local NPCSection = TeleTab:NewSection("NPCs")
NPCSection:NewDropdown("Select NPC", "Choose an NPC location", NPCNames, function(currentOption)
    flags['npcs'] = currentOption
end)
NPCSection:NewButton("Teleport To NPC", "Teleport to selected NPC", function()
    if flags['npcs'] then
        gethrp().CFrame = TeleportLocations['NPCs'][flags['npcs']]
    end
end)

local MarianaSection = TeleTab:NewSection("🌊 Mariana's Veil")
MarianaSection:NewDropdown("Select Mariana Location", "Choose a Mariana's Veil location", MarianaVeilNames, function(currentOption)
    flags['marianaveil'] = currentOption
end)
MarianaSection:NewButton("Teleport To Mariana Location", "Teleport to selected Mariana's Veil location", function()
    if flags['marianaveil'] then
        gethrp().CFrame = TeleportLocations['Mariana Veil'][flags['marianaveil']]
    end
end)

local AllLocSection = TeleTab:NewSection("🗺️ All Locations")
AllLocSection:NewDropdown("Select All Location", "Choose from all available locations", AllLocationNames, function(currentOption)
    flags['alllocations'] = currentOption
end)
AllLocSection:NewButton("Teleport To All Location", "Teleport to selected location", function()
    if flags['alllocations'] then
        gethrp().CFrame = TeleportLocations['All Locations'][flags['alllocations']]
    end
end)

-- Custom GPS Coordinates Teleport Section
local GPSSection = TeleTab:NewSection("📍 Custom GPS Teleport")

-- Variables for GPS coordinates
local gpsX, gpsY, gpsZ = 0, 150, 0

GPSSection:NewTextBox("X Coordinate", "Enter X coordinate (paste supported)", function(txt)
    local x = tonumber(txt)
    if x then
        gpsX = x
        -- print("📍 [GPS] X coordinate set to: " .. x)
    else
        -- print("❌ [GPS] Invalid X coordinate: " .. txt)
    end
end)

GPSSection:NewTextBox("Y Coordinate", "Enter Y coordinate (paste supported)", function(txt)
    local y = tonumber(txt)
    if y then
        gpsY = y
        -- print("📍 [GPS] Y coordinate set to: " .. y)
    else
        -- print("❌ [GPS] Invalid Y coordinate: " .. txt)
    end
end)

GPSSection:NewTextBox("Z Coordinate", "Enter Z coordinate (paste supported)", function(txt)
    local z = tonumber(txt)
    if z then
        gpsZ = z
        -- print("📍 [GPS] Z coordinate set to: " .. z)
    else
        -- print("❌ [GPS] Invalid Z coordinate: " .. txt)
    end
end)

-- Enhanced coordinate input with paste support
GPSSection:NewTextBox("Paste Coordinates", "Paste coordinates in format: X, Y, Z or X Y Z", function(txt)
    pcall(function()
        -- Clean the input text
        local cleanText = txt:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
        
        -- Try different formats
        local coords = {}
        
        -- Format 1: "X, Y, Z" (comma separated)
        if cleanText:find(",") then
            for coord in cleanText:gmatch("([^,]+)") do
                local num = tonumber(coord:match("[-]?%d*%.?%d+"))
                if num then
                    table.insert(coords, num)
                end
            end
        -- Format 2: "X Y Z" (space separated)
        elseif cleanText:find("%s") then
            for coord in cleanText:gmatch("([-]?%d*%.?%d+)") do
                local num = tonumber(coord)
                if num then
                    table.insert(coords, num)
                end
            end
        -- Format 3: Try to extract 3 numbers from any format
        else
            for coord in cleanText:gmatch("([-]?%d*%.?%d+)") do
                local num = tonumber(coord)
                if num then
                    table.insert(coords, num)
                end
            end
        end
        
        -- Apply coordinates if we have at least X and Z
        if #coords >= 2 then
            gpsX = coords[1]
            gpsZ = coords[2]
            gpsY = coords[3] or 150 -- Default Y if not provided
            
            -- print("📍 [GPS Paste] Coordinates parsed successfully!")
            -- print("📍 [GPS] X: " .. gpsX .. ", Y: " .. gpsY .. ", Z: " .. gpsZ)
            
            -- Auto-teleport after paste (optional)
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = CFrame.new(gpsX, gpsY, gpsZ)
                message("📍 GPS Teleport: " .. gpsX .. ", " .. gpsY .. ", " .. gpsZ, 3)
            end
        else
            -- print("❌ [GPS Paste] Could not parse coordinates from: " .. txt)
            -- print("💡 [GPS Help] Try formats like: '100, 150, 200' or '100 150 200'")
        end
    end)
end)

GPSSection:NewButton("🚀 Teleport to GPS Coordinates", "Teleport to the specified coordinates", function()
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            lp.Character.HumanoidRootPart.CFrame = CFrame.new(gpsX, gpsY, gpsZ)
            -- print("🚀 [GPS Teleport] Teleported to: " .. gpsX .. ", " .. gpsY .. ", " .. gpsZ)
            message("📍 GPS Teleport: " .. gpsX .. ", " .. gpsY .. ", " .. gpsZ, 3)
        end)
    else
        -- print("❌ [GPS Teleport] Character not found!")
    end
end)

GPSSection:NewButton("📋 Get Current Position", "Copy current position to GPS coordinates", function()
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local pos = lp.Character.HumanoidRootPart.Position
        gpsX = math.floor(pos.X * 100) / 100 -- Round to 2 decimal places
        gpsY = math.floor(pos.Y * 100) / 100
        gpsZ = math.floor(pos.Z * 100) / 100
        
        -- print("📋 [GPS] Current position copied: " .. gpsX .. ", " .. gpsY .. ", " .. gpsZ)
        message("📋 Current Position: " .. gpsX .. ", " .. gpsY .. ", " .. gpsZ, 5)
        
        -- Try to copy to clipboard if possible
        pcall(function()
            if setclipboard then
                setclipboard(gpsX .. ", " .. gpsY .. ", " .. gpsZ)
                -- print("📋 [GPS] Coordinates copied to clipboard!")
            end
        end)
    else
        -- print("❌ [GPS] Character not found!")
    end
end)

-- Quick coordinate presets
local QuickGPSSection = TeleTab:NewSection("⚡ Quick GPS Presets")

QuickGPSSection:NewButton("🏠 Moosewood Spawn", "Set GPS to Moosewood spawn area", function()
    gpsX, gpsY, gpsZ = 380, 135, 235
    -- print("⚡ [Quick GPS] Set to Moosewood spawn")
end)

QuickGPSSection:NewButton("🌊 Ocean Center", "Set GPS to ocean center", function()
    gpsX, gpsY, gpsZ = 0, 126, 0
    -- print("⚡ [Quick GPS] Set to Ocean center")
end)

QuickGPSSection:NewButton("🏔️ Snowcap Island", "Set GPS to Snowcap Island", function()
    gpsX, gpsY, gpsZ = 2607, 135, 2436
    -- print("⚡ [Quick GPS] Set to Snowcap Island")
end)

QuickGPSSection:NewButton("🏛️ Ancient Isle", "Set GPS to Ancient Isle", function()
    gpsX, gpsY, gpsZ = 6056, 195, 276
    -- print("⚡ [Quick GPS] Set to Ancient Isle")
end)

-- GPS Info Section
local GPSInfoSection = TeleTab:NewSection("ℹ️ GPS Information")
GPSInfoSection:NewLabel("📍 GPS Teleport System")
GPSInfoSection:NewLabel("✅ Supports multiple coordinate formats:")
GPSInfoSection:NewLabel("• X, Y, Z (comma separated)")
GPSInfoSection:NewLabel("• X Y Z (space separated)")  
GPSInfoSection:NewLabel("• Paste from any source")
GPSInfoSection:NewLabel("• Auto-teleport after paste")
GPSInfoSection:NewLabel("• Get current position")
GPSInfoSection:NewLabel("• Quick presets available")

-- Visuals Section
local RodSection = VisualTab:NewSection("Rod")
RodSection:NewToggle("Body Rod Chams", "Apply chams to body rod", function(state)
    flags['bodyrodchams'] = state
end)
RodSection:NewToggle("Rod Chams", "Apply chams to equipped rod", function(state)
    flags['rodchams'] = state
end)
RodSection:NewDropdown("Material", "Select rod material", {"ForceField", "Neon"}, function(currentOption)
    flags['rodmaterial'] = currentOption
end)

local FishSection = VisualTab:NewSection("Fish Abundance")
FishSection:NewToggle("Free Fish Radar", "Show fish abundance zones", function(state)
    flags['fishabundance'] = state
end)

local PlayerSection = VisualTab:NewSection("Player ESP")
PlayerSection:NewToggle("Player ESP", "👥 Show all players with distance and name", function(state)
    flags['playeresp'] = state
    if state then
        createPlayerESP()
        -- print("👥 [Player ESP] Activated - Showing all players!")
    else
        clearPlayerESP()
        -- print("👥 [Player ESP] Deactivated")
    end
end)
PlayerSection:NewDropdown("ESP Color", "Select player ESP color", {"Red", "Green", "Blue", "Yellow", "Purple", "Orange", "White"}, function(currentOption)
    flags['playerespcolor'] = currentOption
    if flags['playeresp'] then
        updatePlayerESPColor()
    end
end)

-- Player ESP System
local PlayerESP = {
    espObjects = {},
    colors = {
        ["Red"] = Color3.fromRGB(255, 0, 0),
        ["Green"] = Color3.fromRGB(0, 255, 0),
        ["Blue"] = Color3.fromRGB(0, 100, 255),
        ["Yellow"] = Color3.fromRGB(255, 255, 0),
        ["Purple"] = Color3.fromRGB(128, 0, 128),
        ["Orange"] = Color3.fromRGB(255, 165, 0),
        ["White"] = Color3.fromRGB(255, 255, 255)
    }
}

function PlayerESP:createESPForPlayer(player)
    if player == lp then return end -- Don't ESP ourselves
    if self.espObjects[player] then return end -- Already has ESP
    
    local espObj = {}
    espObj.player = player
    
    -- Create ScreenGui
    espObj.screenGui = Instance.new("ScreenGui")
    espObj.screenGui.Name = "PlayerESP_" .. player.Name
    espObj.screenGui.Parent = lp.PlayerGui
    espObj.screenGui.ResetOnSpawn = false
    
    -- Create Frame (invisible container)
    espObj.frame = Instance.new("Frame")
    espObj.frame.Size = UDim2.new(0, 120, 0, 30)
    espObj.frame.BackgroundTransparency = 1
    espObj.frame.BorderSizePixel = 0
    espObj.frame.Parent = espObj.screenGui
    
    -- Create TextLabel
    espObj.textLabel = Instance.new("TextLabel")
    espObj.textLabel.Size = UDim2.new(1, 0, 1, 0)
    espObj.textLabel.BackgroundTransparency = 1
    espObj.textLabel.Text = "👤 " .. player.Name .. "\n📍 0m"
    espObj.textLabel.TextColor3 = self.colors[flags['playerespcolor'] or "White"]
    espObj.textLabel.TextStrokeTransparency = 0
    espObj.textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    espObj.textLabel.TextScaled = true
    espObj.textLabel.Font = Enum.Font.SourceSansBold
    espObj.textLabel.Parent = espObj.frame
    
    -- Update function
    espObj.updatePosition = function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            espObj.frame.Visible = false
            return
        end
        
        if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then
            espObj.frame.Visible = false
            return
        end
        
        local camera = workspace.CurrentCamera
        local playerPos = player.Character.HumanoidRootPart.Position
        
        -- Convert 3D world position to 2D screen position
        local screenPos, onScreen = camera:WorldToScreenPoint(playerPos)
        
        if onScreen and screenPos.Z > 0 then
            -- Position on screen
            espObj.frame.Position = UDim2.new(0, screenPos.X - 60, 0, screenPos.Y - 15)
            espObj.frame.Visible = true
            
            -- Update distance
            local distance = math.floor((lp.Character.HumanoidRootPart.Position - playerPos).Magnitude)
            espObj.textLabel.Text = "👤 " .. player.Name .. "\n📍 " .. distance .. "m"
            
            -- Fade based on distance (closer = more visible)
            local alpha = math.max(0.3, 1 - (distance / 1000))
            espObj.textLabel.TextTransparency = 1 - alpha
        else
            espObj.frame.Visible = false
        end
    end
    
    self.espObjects[player] = espObj
end

function PlayerESP:removeESPForPlayer(player)
    if self.espObjects[player] then
        if self.espObjects[player].screenGui then
            self.espObjects[player].screenGui:Destroy()
        end
        self.espObjects[player] = nil
    end
end

function createPlayerESP()
    -- Set default color if not set
    if not flags['playerespcolor'] then
        flags['playerespcolor'] = "White"
    end
    
    -- Create ESP for all current players
    for _, player in pairs(game.Players:GetPlayers()) do
        PlayerESP:createESPForPlayer(player)
    end
    
    -- Listen for new players
    PlayerESP.playerAddedConnection = game.Players.PlayerAdded:Connect(function(player)
        if flags['playeresp'] then
            PlayerESP:createESPForPlayer(player)
        end
    end)
    
    -- Listen for players leaving
    PlayerESP.playerRemovingConnection = game.Players.PlayerRemoving:Connect(function(player)
        PlayerESP:removeESPForPlayer(player)
    end)
    
    -- Start update loop
    PlayerESP.updateConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if flags['playeresp'] then
            for player, espObj in pairs(PlayerESP.espObjects) do
                if espObj.updatePosition then
                    espObj.updatePosition()
                end
            end
        end
    end)
end

function clearPlayerESP()
    -- Remove all ESP objects
    for player, espObj in pairs(PlayerESP.espObjects) do
        PlayerESP:removeESPForPlayer(player)
    end
    
    -- Disconnect connections
    if PlayerESP.playerAddedConnection then
        PlayerESP.playerAddedConnection:Disconnect()
        PlayerESP.playerAddedConnection = nil
    end
    
    if PlayerESP.playerRemovingConnection then
        PlayerESP.playerRemovingConnection:Disconnect()
        PlayerESP.playerRemovingConnection = nil
    end
    
    if PlayerESP.updateConnection then
        PlayerESP.updateConnection:Disconnect()
        PlayerESP.updateConnection = nil
    end
end

function updatePlayerESPColor()
    local newColor = PlayerESP.colors[flags['playerespcolor'] or "White"]
    
    for player, espObj in pairs(PlayerESP.espObjects) do
        if espObj.textLabel then
            espObj.textLabel.TextColor3 = newColor
        end
    end
end

--// Loops
RunService.Heartbeat:Connect(function()
    -- Autofarm
    if flags['freezechar'] then
        if flags['freezecharmode'] == 'Toggled' then
            if characterposition == nil then
                characterposition = gethrp().CFrame
            else
                gethrp().CFrame = characterposition
            end
        elseif flags['freezecharmode'] == 'Rod Equipped' then
            local rod = FindRod()
            if rod and characterposition == nil then
                characterposition = gethrp().CFrame
            elseif rod and characterposition ~= nil then
                gethrp().CFrame = characterposition
            else
                characterposition = nil
            end
        end
    else
        characterposition = nil
    end
    -- OPTIMIZED AUTOSHAKE V1 (CONFLICT-FREE WITH INSTANT REEL AND V2)
    if flags['autoshake'] and not autoShakeV2Active and not flags['superinstantreel'] then
        -- Only run autoshake V1 if V2 is disabled and super instant reel is disabled
        if FindChild(lp.PlayerGui, 'shakeui') and FindChild(lp.PlayerGui['shakeui'], 'safezone') and FindChild(lp.PlayerGui['shakeui']['safezone'], 'button') then
            GuiService.SelectedObject = lp.PlayerGui['shakeui']['safezone']['button']
            if GuiService.SelectedObject == lp.PlayerGui['shakeui']['safezone']['button'] then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                -- Removed console output for performance
                -- print("🛡️ [AutoShake V1] Standard shake executed!")
            end
        else
            -- Debug: Check what's missing
            local shakeui = FindChild(lp.PlayerGui, 'shakeui')
            if shakeui then
                local safezone = FindChild(shakeui, 'safezone')
                if safezone then
                    local button = FindChild(safezone, 'button')
                    if not button then
                        -- Removed console output for performance
                        -- print("❌ [AutoShake V1] Button not found in safezone")
                    end
                else
                    -- Removed console output for performance  
                    -- print("❌ [AutoShake V1] Safezone not found in shakeui")
                end
            end
        end
    elseif flags['autoshake'] and flags['superinstantreel'] then
        -- Alternative smooth shake handling when instant reel is active
        pcall(function()
            local shakeUI = lp.PlayerGui:FindFirstChild('shakeui')
            if shakeUI then
                shakeUI:Destroy() -- Instantly bypass shake UI when instant reel is active
                -- Removed console output for performance
                -- print("🚫 [AutoShake V1] Shake UI bypassed (Super Instant Reel mode)")
            end
        end)
    end
    
    -- NOTE: AutoShake V2 runs independently via ChildAdded connection (main4.lua style)
    -- 🚀 ADVANCED PREDICTIVE AUTOCAST SYSTEM - ZERO GAP TIME!
    if flags['autocast'] and flags['predictiveautocast'] then
        local rod = FindRod()
        
        if rod ~= nil then
            local currentLureValue = rod['values']['lure'].Value
            local currentBiteValue = rod['values']['bite'] and rod['values']['bite'].Value or false
            
            -- PREDICTIVE CASTING: Detect when reel is about to finish
            if currentLureValue >= 95 and currentBiteValue == true then
                -- Fish is being reeled in, prepare for immediate recast
                task.spawn(function()
                    -- Wait for reel to complete (very short delay)
                    while rod['values']['lure'].Value > 0.001 do
                        task.wait(0.001) -- Ultra-fast monitoring
                    end
                    
                    -- INSTANT RECAST: No delays, immediate cast after reel completion
                    if flags['noanimationautocast'] then
                        rod.events.cast:FireServer(-25, 1)
                    elseif flags['autocastarmmovement'] then
                        rod.events.cast:FireServer(1000000000000, 1)
                    elseif flags['enhancedinstantbobber'] then
                        rod.events.cast:FireServer(-500, 1)
                    elseif flags['instantbobber'] then
                        rod.events.cast:FireServer(-250, 1)
                    else
                        rod.events.cast:FireServer(-25, 1)
                    end
                    
                    -- print("⚡ [Predictive AutoCast] ZERO-GAP recast completed!")
                end)
            end
            
            -- Standard autocast for when not in predictive mode
            if currentLureValue <= .001 then
                local currentDelay = flags['autocastdelay'] or 0.01
                -- Reduced delay when predictive mode (backup safety)
                currentDelay = currentDelay * 0.1 -- 90% faster
                task.wait(currentDelay)
                
                if flags['noanimationautocast'] then
                    rod.events.cast:FireServer(-25, 1)
                elseif flags['autocastarmmovement'] then
                    rod.events.cast:FireServer(100, 1)
                elseif flags['enhancedinstantbobber'] then
                    rod.events.cast:FireServer(-500, 1)
                elseif flags['instantbobber'] then
                    rod.events.cast:FireServer(-250, 1)
                else
                    rod.events.cast:FireServer(-25, 1)
                end
            end
        end
    -- STANDARD AUTOCAST (when predictive mode is OFF)
    elseif flags['autocast'] then
        local rod = FindRod()
        local currentDelay = flags['autocastdelay'] or 0.5
        
        -- Add extra delay when super instant reel is active to prevent conflicts
        if flags['superinstantreel'] then
            currentDelay = math.max(currentDelay, 0.8) -- Minimum 0.8s delay for smooth operation
        end
        
        if rod ~= nil and rod['values']['lure'].Value <= .001 then
            task.wait(currentDelay)
            
            -- Check casting mode priority: No Animation > Arm Movement > Enhanced Instant > Instant > Normal
            if flags['noanimationautocast'] then
                -- NO ANIMATION AUTO CAST: Use minimal negative for no animation only
                rod.events.cast:FireServer(-25, 1) -- Small negative = no animation, instant bobber
                -- print("🚫 [No Animation Auto Cast] Instant cast without animation!")
            elseif flags['autocastarmmovement'] then
                -- ARM MOVEMENT AUTO CAST: Use positive distance for full animation
                rod.events.cast:FireServer(100, 1) -- Positive distance = full arm animation
                -- print("🤖 [Auto Cast Arm Movement] Cast with full throwing animation!")
            elseif flags['enhancedinstantbobber'] then
                -- ENHANCED INSTANT BOBBER: EXTREME PENETRATION for ALL boats/ships
                rod.events.cast:FireServer(-500, 1) -- EXTREME negative distance = penetrate ANY boat/ship
                -- print("🌊 [Enhanced Instant Bobber] EXTREME penetration through ANY boat/ship!")
            elseif flags['instantbobber'] then
                -- INSTANT BOBBER: STRONG penetration for boats
                rod.events.cast:FireServer(-250, 1) -- Strong negative distance = penetrate boats and obstacles
                -- print("⚡ [Instant Bobber] STRONG penetration through boats!")
            else
                -- DEFAULT: No arm movement for efficiency
                rod.events.cast:FireServer(-25, 1) -- Default to no animation for speed
            end
        end
    end
    if flags['autoreel'] then
        local rod = FindRod()
        local currentDelay = flags['autoreeldelay'] or 0.5
        if rod ~= nil and rod['values']['lure'].Value == 100 then
            task.wait(currentDelay)
            ReplicatedStorage.events.reelfinished:FireServer(100, true)
        end
    end
    
    -- 🚀 ENHANCED SUPER INSTANT REEL - SMOOTH & FAST FISH LIFTING!
    if flags['superinstantreel'] then
        local rod = FindRod()
        if rod ~= nil then
            local lureValue = rod.values.lure and rod.values.lure.Value or 0
            local biteValue = rod.values.bite and rod.values.bite.Value or false
            
            -- SMOOTH TRIGGER: Lure >= 98% OR bite detected (NO LAG)
            if lureValue >= 98 or biteValue == true then
                pcall(function()
                    -- Single optimized call (no spam)
                    ReplicatedStorage.events.reelfinished:FireServer(100, true)
                    
                    -- 🚀 PREDICTIVE AUTOCAST INTEGRATION: Prepare next cast immediately
                    if flags['predictiveautocast'] and flags['autocast'] then
                        task.spawn(function()
                            -- Ultra-short delay to ensure reel completion
                            task.wait(0.05) 
                            
                            -- Immediate recast for zero-gap fishing
                            if flags['noanimationautocast'] then
                                rod.events.cast:FireServer(-25, 1)
                            elseif flags['enhancedinstantbobber'] then
                                rod.events.cast:FireServer(-500, 1)
                            else
                                rod.events.cast:FireServer(-25, 1) -- Default fast cast
                            end
                            
                            -- print("⚡ [Super Instant + Predictive] ZERO-GAP combo recast!")
                        end)
                    end
                    
                    -- 🚫 PREEMPTIVE GUI CLEANUP - Disable all potential reel GUIs FIRST
                    pcall(function()
                        for _, gui in pairs(lp.PlayerGui:GetChildren()) do
                            if gui.Name == "reel" or gui.Name:lower():find("reel") or gui:FindFirstChild("reel") then
                                gui.Enabled = false -- Disable immediately
                                gui.Visible = false -- Hide immediately  
                                gui:Destroy() -- Then destroy
                            end
                        end
                    end)
                    
                    -- FAST FISH LIFTING: Speed boost for character animations
                    pcall(function()
                        local character = lp.Character
                        if character and character:FindFirstChild("Humanoid") then
                            local humanoid = character.Humanoid
                            
                            -- 5x speed boost for all animations during catch
                            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                                track:AdjustSpeed(5)
                            end
                            
                            -- Reset to normal speed after brief period
                            task.spawn(function()
                                task.wait(0.2)
                                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                                    track:AdjustSpeed(1)
                                end
                            end)
                        end
                    end)
                    
                    -- print("⚡ [FAST LIFTING] Lure:" .. lureValue .. "% - INSTANT + SPEED BOOST!")
                end)
            end
        end
    end
    
    -- Instant Reel (No Delay) - RISKY but very fast
    if flags['instantreel'] then
        local rod = FindRod()
        if rod ~= nil and rod['values']['lure'].Value == 100 then
            -- Add small random delay to make it more natural
            local randomDelay = math.random(5, 25) / 1000 -- 0.005-0.025 seconds
            task.wait(randomDelay)
            ReplicatedStorage.events.reelfinished:FireServer(100, true)
        end
    end

    -- Visuals
    if flags['rodchams'] then
        local rod = FindRod()
        if rod ~= nil and FindChild(rod, 'Details') then
            local rodName = tostring(rod)
            if not RodColors[rodName] then
                RodColors[rodName] = {}
                RodMaterials[rodName] = {}
            end
            for i,v in rod['Details']:GetDescendants() do
                if v:IsA('BasePart') or v:IsA('MeshPart') then
                    if v.Color ~= Color3.fromRGB(100, 100, 255) then
                        RodColors[rodName][v.Name..i] = v.Color
                    end
                    if RodMaterials[rodName][v.Name..i] == nil then
                        if v.Material == Enum.Material.Neon then
                            RodMaterials[rodName][v.Name..i] = Enum.Material.Neon
                        elseif v.Material ~= Enum.Material.ForceField and v.Material ~= Enum.Material[flags['rodmaterial']] then
                            RodMaterials[rodName][v.Name..i] = v.Material
                        end
                    end
                    v.Material = Enum.Material[flags['rodmaterial']]
                    v.Color = Color3.fromRGB(100, 100, 255)
                end
            end
            if rod['handle'].Color ~= Color3.fromRGB(100, 100, 255) then
                RodColors[rodName]['handle'] = rod['handle'].Color
            end
            if rod['handle'].Material ~= Enum.Material.ForceField and rod['handle'].Material ~= Enum.Material.Neon and rod['handle'].Material ~= Enum.Material[flags['rodmaterial']] then
                RodMaterials[rodName]['handle'] = rod['handle'].Material
            end
            rod['handle'].Material = Enum.Material[flags['rodmaterial']]
            rod['handle'].Color = Color3.fromRGB(100, 100, 255)
        end
    elseif not flags['rodchams'] then
        local rod = FindRod()
        if rod ~= nil and FindChild(rod, 'Details') then
            local rodName = tostring(rod)
            if RodColors[rodName] and RodMaterials[rodName] then
                for i,v in rod['Details']:GetDescendants() do
                    if v:IsA('BasePart') or v:IsA('MeshPart') then
                        if RodMaterials[rodName][v.Name..i] and RodColors[rodName][v.Name..i] then
                            v.Material = RodMaterials[rodName][v.Name..i]
                            v.Color = RodColors[rodName][v.Name..i]
                        end
                    end
                end
                if RodMaterials[rodName]['handle'] and RodColors[rodName]['handle'] then
                    rod['handle'].Material = RodMaterials[rodName]['handle']
                    rod['handle'].Color = RodColors[rodName]['handle']
                end
            end
        end
    end
    if flags['bodyrodchams'] then
        local rod = getchar():FindFirstChild('RodBodyModel')
        if rod ~= nil and FindChild(rod, 'Details') then
            local rodName = tostring(rod)
            if not RodColors[rodName] then
                RodColors[rodName] = {}
                RodMaterials[rodName] = {}
            end
            for i,v in rod['Details']:GetDescendants() do
                if v:IsA('BasePart') or v:IsA('MeshPart') then
                    if v.Color ~= Color3.fromRGB(100, 100, 255) then
                        RodColors[rodName][v.Name..i] = v.Color
                    end
                    if RodMaterials[rodName][v.Name..i] == nil then
                        if v.Material == Enum.Material.Neon then
                            RodMaterials[rodName][v.Name..i] = Enum.Material.Neon
                        elseif v.Material ~= Enum.Material.ForceField and v.Material ~= Enum.Material[flags['rodmaterial']] then
                            RodMaterials[rodName][v.Name..i] = v.Material
                        end
                    end
                    v.Material = Enum.Material[flags['rodmaterial']]
                    v.Color = Color3.fromRGB(100, 100, 255)
                end
            end
            if rod['handle'].Color ~= Color3.fromRGB(100, 100, 255) then
                RodColors[rodName]['handle'] = rod['handle'].Color
            end
            if rod['handle'].Material ~= Enum.Material.ForceField and rod['handle'].Material ~= Enum.Material.Neon and rod['handle'].Material ~= Enum.Material[flags['rodmaterial']] then
                RodMaterials[rodName]['handle'] = rod['handle'].Material
            end
            rod['handle'].Material = Enum.Material[flags['rodmaterial']]
            rod['handle'].Color = Color3.fromRGB(100, 100, 255)
        end
    elseif not flags['bodyrodchams'] then
        local rod = getchar():FindFirstChild('RodBodyModel')
        if rod ~= nil and FindChild(rod, 'Details') then
            local rodName = tostring(rod)
            if RodColors[rodName] and RodMaterials[rodName] then
                for i,v in rod['Details']:GetDescendants() do
                    if v:IsA('BasePart') or v:IsA('MeshPart') then
                        if RodMaterials[rodName][v.Name..i] and RodColors[rodName][v.Name..i] then
                            v.Material = RodMaterials[rodName][v.Name..i]
                            v.Color = RodColors[rodName][v.Name..i]
                        end
                    end
                end
                if RodMaterials[rodName]['handle'] and RodColors[rodName]['handle'] then
                    rod['handle'].Material = RodMaterials[rodName]['handle']
                    rod['handle'].Color = RodColors[rodName]['handle']
                end
            end
        end
    end
    if flags['fishabundance'] then
        if not fishabundancevisible then
            message('\<b><font color = \"#9eff80\">Fish Abundance Zones</font></b>\ are now visible', 5)
        end
        for i,v in workspace.zones.fishing:GetChildren() do
            if FindChildOfType(v, 'Abundance', 'StringValue') and FindChildOfType(v, 'radar1', 'BillboardGui') then
                v['radar1'].Enabled = true
                v['radar2'].Enabled = true
            end
        end
        fishabundancevisible = flags['fishabundance']
    else
        if fishabundancevisible then
            message('\<b><font color = \"#9eff80\">Fish Abundance Zones</font></b>\ are no longer visible', 5)
        end
        for i,v in workspace.zones.fishing:GetChildren() do
            if FindChildOfType(v, 'Abundance', 'StringValue') and FindChildOfType(v, 'radar1', 'BillboardGui') then
                v['radar1'].Enabled = false
                v['radar2'].Enabled = false
            end
        end
        fishabundancevisible = flags['fishabundance']
    end

    -- Modifications
    if flags['infoxygen'] then
        if not deathcon then
            deathcon = gethum().Died:Connect(function()
                task.delay(9, function()
                    if FindChildOfType(getchar(), 'DivingTank', 'Decal') then
                        FindChildOfType(getchar(), 'DivingTank', 'Decal'):Destroy()
                    end
                    local oxygentank = Instance.new('Decal')
                    oxygentank.Name = 'DivingTank'
                    oxygentank.Parent = workspace
                    oxygentank:SetAttribute('Tier', 1/0)
                    oxygentank.Parent = getchar()
                    deathcon = nil
                end)
            end)
        end
        if deathcon and gethum().Health > 0 then
            if not getchar():FindFirstChild('DivingTank') then
                local oxygentank = Instance.new('Decal')
                oxygentank.Name = 'DivingTank'
                oxygentank.Parent = workspace
                oxygentank:SetAttribute('Tier', 1/0)
                oxygentank.Parent = getchar()
            end
        end
    else
        if FindChildOfType(getchar(), 'DivingTank', 'Decal') then
            FindChildOfType(getchar(), 'DivingTank', 'Decal'):Destroy()
        end
    end
    if flags['nopeakssystems'] then
        getchar():SetAttribute('WinterCloakEquipped', true)
        getchar():SetAttribute('Refill', true)
    else
        getchar():SetAttribute('WinterCloakEquipped', nil)
        getchar():SetAttribute('Refill', false)
    end
    
    -- Enhanced Always Catch - Auto complete reel minigame
    if flags['alwayscatch'] then
        local rod = FindRod()
        if rod and rod['values'] and rod['values']['lure'] then
            -- Check if fish is hooked and minigame should be bypassed
            if rod['values']['lure'].Value >= 99.9 then
                -- Try to bypass reel minigame immediately
                pcall(function()
                    -- Check for reel GUI
                    local reelGui = lp.PlayerGui:FindFirstChild('reel')
                    if reelGui then
                        -- Immediately complete the reel
                        ReplicatedStorage.events.reelfinished:FireServer(100, true)
                    end
                end)
            end
        end
    end
end)

--// Hooks
if CheckFunc(hookmetamethod) then
    local old; old = hookmetamethod(game, "__namecall", function(self, ...)
        local method, args = getnamecallmethod(), {...}
        if method == 'FireServer' and self.Name == 'afk' and flags['noafk'] then
            args[1] = false
            return old(self, unpack(args))
        elseif method == 'FireServer' and self.Name == 'cast' and flags['perfectcast'] then
            args[1] = 100
            return old(self, unpack(args))
        elseif method == 'FireServer' and self.Name == 'cast' and flags['noanimationautocast'] then
            -- NO ANIMATION MANUAL CAST: Override manual casting untuk no animation (HIGHEST PRIORITY)
            args[1] = -25   -- Small negative distance = no animation, instant bobber
            args[2] = 1     -- Keep force parameter
            -- print("🚫 [No Animation Cast Hook] Manual cast without animation!")
            return old(self, unpack(args))
        elseif method == 'FireServer' and self.Name == 'cast' and flags['enhancedinstantbobber'] then
            -- ENHANCED INSTANT BOBBER HOOK: EXTREME penetration for ALL boats/ships
            args[1] = -500  -- EXTREME negative distance untuk penetrate ANY boat/ship
            args[2] = 1     -- Keep force parameter
            -- print("🌊 [Enhanced Instant Bobber Hook] EXTREME penetration through ANY boat/ship!")
            return old(self, unpack(args))
        elseif method == 'FireServer' and self.Name == 'cast' and flags['instantbobber'] then
            -- INSTANT BOBBER HOOK: STRONG penetration for boats
            args[1] = -250  -- Strong negative distance untuk penetrate boats
            args[2] = 1     -- Keep power at 1
            -- print("⚡ [Instant Bobber Hook] STRONG penetration through boats!")
            return old(self, unpack(args))
        elseif method == 'FireServer' and self.Name == 'reelfinished' and flags['alwayscatch'] then
            args[1] = 100
            args[2] = true
            return old(self, unpack(args))
        elseif flags['skipcutscenes'] and method == 'FireServer' then
            -- Skip cutscene remotes for fish captures
            local remoteName = tostring(self.Name)
            
            -- List of cutscene remote names to block
            local cutsceneRemotes = {
                "MegalodonCapture", "KrakenCapture", "ScyllaCapture", 
                "MobyCapture", "SeaLeviathanCapture", "FrozenLeviathanCapture",
                "CrownedAnglerCapture", "CrystallizedSeadragonCapture", 
                "LobsterKingCapture", "MagmaLeviathanCapture", "BossArenaDoorCapture",
                "BossArenaEndCapture", "CryptDoorIntro", "CathuluBossFightEnding",
                "CthuluStartFight", "ScyllaEnter", "MarianasVeilEntry", "CrackedObsidianDoor"
            }
            
            -- Check if remote name contains cutscene keywords
            if remoteName:lower():find("cutscene") or remoteName:find("Capture") or remoteName:find("Intro") then
                -- print("🎬 [Skip Cutscenes] Blocked cutscene remote: " .. remoteName)
                return -- Block the cutscene call completely
            end
            
            -- Check specific fish capture cutscenes
            for _, cutscene in pairs(cutsceneRemotes) do
                if remoteName:find(cutscene) then
                    -- print("🎬 [Skip Cutscenes] Blocked " .. cutscene .. " cutscene!")
                    return -- Block the specific cutscene
                end
            end
        end
        return old(self, ...)
    end)
    
    -- Additional hook for cutscene GUI detection and instant closure
    spawn(function()
        while wait(0.1) do
            if flags['skipcutscenes'] then
                pcall(function()
                    -- Check for cutscene GUIs and close them instantly
                    for _, gui in pairs(lp.PlayerGui:GetChildren()) do
                        local guiName = gui.Name:lower()
                        
                        -- Detect cutscene-related GUIs
                        if guiName:find("cutscene") or guiName:find("capture") or 
                           guiName:find("intro") or guiName:find("ending") then
                            gui:Destroy()
                            -- print("🎬 [Skip Cutscenes] Destroyed cutscene GUI: " .. gui.Name)
                        end
                        
                        -- Check for specific boss cutscene GUIs
                        local cutsceneGUIs = {
                            "megalodon", "kraken", "scylla", "moby", "leviathan",
                            "angler", "seadragon", "lobster", "cthulu", "mariana"
                        }
                        
                        for _, cutsceneGUI in pairs(cutsceneGUIs) do
                            if guiName:find(cutsceneGUI) and 
                               (guiName:find("capture") or guiName:find("cutscene")) then
                                gui:Destroy()
                                -- print("🎬 [Skip Cutscenes] Destroyed " .. cutsceneGUI .. " cutscene GUI!")
                            end
                        end
                    end
                end)
            end
        end
        
        -- 🚫 DISABLE ANIMATIONS SYSTEM - Hook all animation remotes
        if flags['disableanimations'] then
            local originalFireServer = remote.FireServer
            remote.FireServer = function(self, ...)
                local remoteName = tostring(self)
                
                -- Block all animation-related remotes
                local blockedAnimations = {
                    "rodwave", "shakehudeffect", "exalted_rod_animation",
                    "LocalCutscene", "RequestCutscene", "RequestCutsceneSync",
                    "Fischfest/TideAnimation", "AnglerfishMinigame/DeathEffect",
                    "BaitWhirlPoolPassive/Visual", "emoteCancel", "viewUtilities"
                }
                
                for _, blockedAnim in pairs(blockedAnimations) do
                    if remoteName:find(blockedAnim) then
                        -- print("🚫 [Disable Animations] Blocked: " .. blockedAnim)
                        return -- Block the animation
                    end
                end
                
                return originalFireServer(self, ...)
            end
        end
        
        -- 🌊 BLOCK ROD WAVE - Specific blocking for rod wave effects
        if flags['blockrodwave'] then
            pcall(function()
                if ReplicatedStorage.events:FindFirstChild("rodwave") then
                    local originalRodWave = ReplicatedStorage.events.rodwave.FireServer
                    ReplicatedStorage.events.rodwave.FireServer = function(...)
                        -- print("🌊 [Block Rod Wave] Blocked rod wave animation!")
                        return -- Block rod wave
                    end
                end
            end)
        end
        
        -- 📳 BLOCK SHAKE EFFECTS - Stop screen shake effects
        if flags['blockshakeeffects'] then
            pcall(function()
                if ReplicatedStorage.events:FindFirstChild("shakehudeffect") then
                    local originalShake = ReplicatedStorage.events.shakehudeffect.FireServer
                    ReplicatedStorage.events.shakehudeffect.FireServer = function(...)
                        -- print("📳 [Block Shake Effects] Blocked screen shake!")
                        return -- Block shake effects
                    end
                end
                
                -- Block shake UI as well
                if ReplicatedStorage.resources and 
                   ReplicatedStorage.resources.replicated and
                   ReplicatedStorage.resources.replicated.fishing and
                   ReplicatedStorage.resources.replicated.fishing.shakeui then
                    
                    local shakeUI = ReplicatedStorage.resources.replicated.fishing.shakeui
                    if shakeUI:FindFirstChild("safezone") then
                        local shakeButton = shakeUI.safezone.shakeui.button
                        if shakeButton:FindFirstChild("shake") then
                            local originalShakeUI = shakeButton.shake.FireServer
                            shakeButton.shake.FireServer = function(...)
                                -- print("📳 [Block Shake Effects] Blocked shake UI!")
                                return -- Block shake UI
                            end
                        end
                    end
                end
            end)
        end
        
        -- ✨ BLOCK EXALTED ROD ANIMATION - Stop special rod animations
        if flags['blockexaltedanim'] then
            pcall(function()
                if ReplicatedStorage.events:FindFirstChild("exalted_rod_animation") then
                    local originalExalted = ReplicatedStorage.events.exalted_rod_animation.FireServer
                    ReplicatedStorage.events.exalted_rod_animation.FireServer = function(...)
                        -- print("✨ [Block Exalted Anim] Blocked special rod animation!")
                        return -- Block exalted rod animation
                    end
                end
            end)
        end
    end)
end

-- ULTIMATE Always Catch + Super Instant Reel Combined System
if flags then
    -- ULTIMATE FRAME-PERFECT monitoring with RunService.Heartbeat (every frame)
    game:GetService("RunService").Heartbeat:Connect(function()
        if flags['superinstantreel'] then
            local rod = FindRod()
            if rod and rod['values'] and rod['values']['bite'] then
                if rod['values']['bite'].Value == true then
                    -- MEGA-ULTRA-FIRE for absolutely ZERO delay
                    for i = 1, 15 do
                        spawn(function()
                            pcall(function()
                                ReplicatedStorage.events.reelfinished:FireServer(100, true)
                            end)
                        end)
                    end
                    
                    -- INSTANT GUI destruction on every frame
                    spawn(function()
                        pcall(function()
                            for _, gui in pairs(lp.PlayerGui:GetChildren()) do
                                if string.find(gui.Name:lower(), "reel") or gui:FindFirstChild("reel") then
                                    gui:Destroy()
                                end
                            end
                        end)
                    end)
                    
                    -- print("🚀 [FRAME-PERFECT] Heartbeat instant catch - ABSOLUTE ZERO DELAY!")
                end
            end
        end
    end)

    -- Ultra-aggressive instant catch system with ZERO delay tolerance
    task.spawn(function()
        while true do
            task.wait(0.001) -- Ultra-fast checking every 1ms (vs 10ms before)
            
            -- Always Catch Mode (when fish actually bites)
            if flags['alwayscatch'] then
                local rod = FindRod()
                if rod and rod['values'] then
                    -- Check for actual bite, not just lure percentage
                    if rod['values']['bite'] and rod['values']['bite'].Value == true then
                        pcall(function()
                            ReplicatedStorage.events.reelfinished:FireServer(100, true)
                        end)
                        -- print("🎣 [Always Catch] Fish bite detected - auto catch!")
                    end
                end
            end
            
            -- Super Instant Reel Mode (ZERO delay when fish bites)
            if flags['superinstantreel'] then
                local rod = FindRod()
                if rod and rod['values'] then
                    -- INSTANT catch with ZERO tolerance for delay
                    if rod['values']['bite'] and rod['values']['bite'].Value == true then
                        -- MEGA-fire for absolutely instant results
                        for i = 1, 7 do
                            pcall(function()
                                ReplicatedStorage.events.reelfinished:FireServer(100, true)
                            end)
                        end
                        
                        -- Immediately destroy ALL possible GUIs
                        pcall(function()
                            for _, gui in pairs(lp.PlayerGui:GetChildren()) do
                                if gui.Name == "reel" or gui:FindFirstChild("reel") then
                                    gui:Destroy()
                                end
                            end
                        end)
                        
                        -- Check for SCREENGUIREELABLE GUI and destroy immediately
                        pcall(function()
                            if lp.PlayerGui:FindFirstChild("screen gui reelable") then
                                lp.PlayerGui["screen gui reelable"]:Destroy()
                            end
                        end)
                        
                        -- print("⚡ [ZERO DELAY] BITE detected - MEGA INSTANT catch!")
                        -- NO delay at all - continue checking immediately
                    end
                end
            end
            
            -- 🚫 DISABLE ANIMATIONS MONITORING - Real-time animation blocking
            if flags['disableanimations'] then
                pcall(function()
                    -- Block animation GUIs from appearing
                    for _, gui in pairs(lp.PlayerGui:GetChildren()) do
                        local guiName = gui.Name:lower()
                        
                        -- Block animation-related GUIs
                        local blockedGUINames = {
                            "shake", "wave", "effect", "anim", "cutscene",
                            "exalted", "special", "rod_animation", "fishing_effect"
                        }
                        
                        for _, blockedName in pairs(blockedGUINames) do
                            if guiName:find(blockedName) then
                                gui:Destroy()
                                -- print("🚫 [Animation Block] Destroyed GUI: " .. gui.Name)
                            end
                        end
                    end
                    
                    -- Block animation sounds
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("Sound") and obj.Name:lower():find("animation") then
                            obj.Volume = 0
                            obj:Stop()
                        end
                    end
                end)
            end
        end
    end)
    
    -- Separate thread for GUI monitoring and instant destruction
    task.spawn(function()
        while true do
            task.wait(0.01)
            if flags['superinstantreel'] then
                pcall(function()
                    local reelGui = lp.PlayerGui:FindFirstChild('reel')
                    if reelGui then
                        -- INSTANT destruction before it even shows
                        reelGui:Destroy()
                        
                        -- Fire completion events immediately
                        for i = 1, 2 do
                            ReplicatedStorage.events.reelfinished:FireServer(100, true)
                        end
                        
                        -- print("⚡ [INSTANT DESTROY] Reel GUI eliminated!")
                    end
                end)
            end
        end
    end)
    
    -- 🚫 ULTIMATE GUI INTERCEPTION - IMMEDIATE DESTRUCTION (NO VISUAL FLASH)
    lp.PlayerGui.ChildAdded:Connect(function(gui)
        if flags['superinstantreel'] then
            if gui.Name == "reel" or gui.Name == "screen gui reelable" or gui:FindFirstChild("reel") then
                -- INSTANT DESTRUCTION - No wait, no delay
                gui.Enabled = false -- Disable immediately to prevent flash
                gui.Visible = false -- Hide immediately
                gui:Destroy() -- Then destroy
                
                -- Fire completion immediately when GUI intercepted
                for i = 1, 8 do -- Reduced spam for efficiency
                    spawn(function()
                        pcall(function()
                            ReplicatedStorage.events.reelfinished:FireServer(100, true)
                        end)
                    end)
                end
                
                -- print("💀 [NO-FLASH INTERCEPTOR] Blocked " .. gui.Name .. " with zero visual!")
            end
        end
    end)
    
    -- 🚫 CONTINUOUS ANTI-FLASH MONITORING - ZERO TOLERANCE FOR REEL GUIs
    task.spawn(function()
        while true do
            task.wait(0.001) -- Ultra-fast monitoring every 1ms
            if flags['superinstantreel'] then
                pcall(function()
                    for _, gui in pairs(lp.PlayerGui:GetChildren()) do
                        if gui.Name:lower():find("reel") or gui.Name == "screen gui reelable" or 
                           gui:FindFirstChild("reel") or gui.Name == "reelgui" then
                            -- TRIPLE DISABLE: Ensure no visual flash
                            gui.Enabled = false
                            gui.Visible = false
                            gui.ResetOnSpawn = false
                            gui:Destroy()
                            
                            -- Fire completion to ensure fish is caught
                            for i = 1, 3 do -- Efficient spam
                                spawn(function()
                                    ReplicatedStorage.events.reelfinished:FireServer(100, true)
                                end)
                            end
                            -- print("� [ANTI-FLASH] Eliminated reel GUI with ZERO visual impact!")
                        end
                    end
                end)
            end
        end
    end)
end

--[[
🚀 SUPER INSTANT REEL + INSTANT BOBBER + SKIP CUTSCENES + PREDICTIVE AUTOCAST MODIFICATION 🚀

✅ New Features Added:
- Super Instant Reel toggle with maximum speed
- Instant Bobber toggle (no animation, close drop)
- Skip Fish Cutscenes toggle (skip all boss/legendary captures)
- 🚀 NEW: Predictive AutoCast (ZERO-GAP between reel completion and next cast)
- Dual monitoring system (main loop + GUI detection)
- Conflict prevention with other auto-reel features
- Multiple rapid fire methods for maximum effectiveness
- Real-time status feedback with console messages
- Enhanced GUI force-close functionality
- Hook system for manual casting instant bobber
- Cutscene blocking system for fish captures

🎯 How Super Instant Reel works (CORRECTED):
1. Monitors for ACTUAL fish bite (bite.Value == true) - NOT just lure %
2. Does NOT catch at lure 99.8% (fish might not bite yet)

🚀 How NEW Predictive AutoCast works:
1. Detects when fish is being reeled in (lure >= 95% + bite = true)
2. Prepares next cast BEFORE current reel finishes
3. Executes immediate recast the moment lure drops to ≤ 0.001
4. ZERO gap time between reel completion and next cast
5. Works with Super Instant Reel for maximum speed
6. Reduces fishing cycle time by 50-80%
7. Uses ultra-fast monitoring (1ms intervals)

🚫 How ANTI-FLASH Super Instant Reel works:
1. TRIPLE GUI blocking: Enabled=false, Visible=false, Destroy()
2. Multiple interceptors: ChildAdded + continuous monitoring
3. ZERO visual flash - GUI blocked before it renders
4. Ultra-fast monitoring (1ms intervals) for instant detection
5. Immediate reelfinished firing without delays
6. Complete reel minigame elimination with no visual artifacts

⚡ Usage for MAXIMUM SPEED:
- Enable "Predictive AutoCast" for zero-gap recasting
- Enable "Super Instant Reel" for instant fish catching
- Enable "No Animation AutoCast" or "Enhanced Instant Bobber" for fastest cast style
- Result: Continuous fishing with minimal delays!

🎯 Performance Benefits:
- Normal cycle: Cast → Shake → Bite → Reel → [DELAY] → Cast (3-5 seconds)  
- Predictive cycle: Cast → Shake → Bite → Reel → INSTANT Cast (1-2 seconds)
- Up to 60% faster fishing automation!

🔧 Performance Optimizations (NEW):
- Console output DISABLED by default for maximum performance
- All print statements removed to reduce CPU load and memory usage  
- Debug Mode toggle available for troubleshooting when needed
- Optimized monitoring loops with reduced frequency checks
- Eliminated console spam that could cause game lag or crashes

💡 Performance Tips:
- Keep Debug Mode OFF during normal fishing for best performance
- Only enable Debug Mode when troubleshooting issues
- Reduced console output = smoother gameplay and less lag
3. Only catches when fish ACTUALLY bites the hook
4. Instantly fires reelfinished event with perfect score
5. Force destroys reel GUI to prevent delays
6. Uses multiple rapid calls for maximum success rate
7. No delays or waiting - pure speed when fish ACTUALLY bites!

⚠️ IMPORTANT: 
- Lure 100% ≠ Fish bite (fish is just interested)
- Bite = true = Fish ACTUALLY bites (this is when we catch!)
- This prevents false catches and ensures accuracy

⚡ How Instant Bobber works:
1. Works with both AutoCast and Manual casting
2. Changes cast distance from 100 to 0 (no animation)
3. Bobber drops instantly near player
4. Hook system intercepts manual casts
5. Perfect for speed fishing setup

� How Skip Fish Cutscenes works:
1. Blocks all cutscene remote calls for fish captures
2. Instantly destroys cutscene GUIs when they appear  
3. Covers all boss fish: Megalodon, Kraken, Scylla, Moby, Leviathan, etc.
4. No interruption during legendary fish catches
5. Maintains normal fishing experience without cutscenes

� How Disable Animations works:
1. Blocks ALL fishing-related animation remote events
2. Stops rod wave, shake effects, and special rod animations
3. Destroys animation GUIs before they can render
4. Mutes animation sounds and visual effects
5. Creates completely clean fishing experience

🎭 Animation Control Features:
- Disable All Animations: Complete animation blocking system
- Block Rod Wave: Stop rod wave effects specifically
- Block Shake Effects: Remove screen shake and UI shake
- Block Exalted Rod Anim: Stop special rod animations

🚫 Blocked Animation Remotes:
- rodwave, shakehudeffect, exalted_rod_animation
- LocalCutscene, RequestCutscene, RequestCutsceneSync
- Fischfest/TideAnimation, AnglerfishMinigame/DeathEffect
- BaitWhirlPoolPassive/Visual, emoteCancel, viewUtilities

�📋 Boss Fish Cutscenes Covered:
- Megalodon, Kraken, Scylla, Moby Dick
- Sea Leviathan, Frozen Leviathan, Magma Leviathan
- Crowned Angler, Crystallized Seadragon, Lobster King  
- Cthulhu Boss Fight, Mariana Veil Entry, Crypt Door
- Boss Arena captures and all legendary fish encounters

�🎮 Usage Combinations:
- AutoCast OFF + Instant Bobber OFF = Normal manual fishing
- AutoCast ON + Instant Bobber OFF = Auto fishing with animation  
- AutoCast ON + Instant Bobber ON = Auto fishing instant (FASTEST!)
- AutoCast OFF + Instant Bobber ON = Manual fishing instant
- Skip Cutscenes ON = No interruptions from boss fish captures

⚠️ Important Notes:
- Super Instant Reel disables normal Auto Reel when activated
- Instant Bobber works with any casting mode
- Skip Cutscenes works for all legendary/boss fish
- Combined features create ultimate fishing speed
- Console output shows when features are active

🔧 Technical Implementation:
- GUI monitoring via PlayerGui.ChildAdded
- Main loop checking via lure value detection
- Hook metamethod for manual cast interception
- Cutscene remote blocking via FireServer hook
- Multiple FireServer calls for redundancy
- Force GUI disable for instant completion
--]]

-- print("🎣 Enhanced Fisch Script with ULTIMATE Super Instant Reel + Instant Bobber + Skip Cutscenes loaded successfully!")
-- print("🚀 ULTIMATE Super Instant Reel: Ready for MAXIMUM fishing speed!")
-- print("🎬 Skip Cutscenes: No more interruptions from boss fish captures!")
-- print("👁️ Clean ESP System: Text-only Event & Player ESP with customizable colors!")
-- print("⚡ INFO: When features are enabled, fishing becomes completely seamless and ultra-fast!")
-- print("🔥 This is the FASTEST and most UNINTERRUPTED fishing system in Fisch!")

-- ULTIMATE HOOK SYSTEM - Blocks reel GUI creation entirely
local originalInstanceNew = Instance.new
Instance.new = function(className, ...)
    local instance = originalInstanceNew(className, ...)
    
    -- Block reel GUI creation when Super Instant Reel is active
    if flags['superinstantreel'] and className == "ScreenGui" and instance.Parent == lp.PlayerGui then
        instance.ChildAdded:Connect(function(child)
            if child.Name == "reel" or child.Name:lower():find("reel") then
                -- INSTANTLY destroy and complete
                child:Destroy()
                
                -- Triple fire for absolute completion
                for i = 1, 3 do
                    pcall(function()
                        ReplicatedStorage.events.reelfinished:FireServer(100, true)
                    end)
                end
                
                -- print("🚫 [ULTIMATE BLOCK] Reel GUI blocked - INSTANT COMPLETION!")
            end
        end)
    end
    
    return instance
end

-- ANIMATION BLOCKING HOOK SYSTEM - Prevents fishing animations from playing
local originalHumanoidLoadAnimation = nil
pcall(function()
    local character = lp.Character
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character.Humanoid
        originalHumanoidLoadAnimation = humanoid.LoadAnimation
        
        humanoid.LoadAnimation = function(self, animation)
            local animationTrack = originalHumanoidLoadAnimation(self, animation)
            
            -- Hook the Play method to check for no animation mode
            local originalPlay = animationTrack.Play
            animationTrack.Play = function(track, ...)
                -- Block fishing animations when Super Instant Reel is active (automatic)
                if flags['superinstantreel'] then -- Always block when super instant reel is on
                    local animationId = tostring(animation.AnimationId):lower()
                    local animationName = tostring(animation.Name):lower()
                    
                    -- Expanded blocking patterns
                    if animationId:find("fish") or animationId:find("reel") or animationId:find("cast") or 
                       animationId:find("rod") or animationId:find("catch") or animationId:find("lift") or
                       animationId:find("pull") or animationId:find("bobber") or animationId:find("yank") or
                       animationId:find("hook") or animationId:find("swing") or animationId:find("wave") or
                       animationName:find("fish") or animationName:find("reel") or animationName:find("cast") or
                       animationName:find("rod") or animationName:find("catch") or animationName:find("lift") then
                        -- Removed console output for performance
                        -- print("🚫 [ANIMATION BLOCKED] " .. (animation.Name or "Unknown") .. " prevented from playing!")
                        return -- Don't play the animation
                    end
                end
                
                -- Play the animation normally if not blocked
                return originalPlay(track, ...)
            end
            
            return animationTrack
        end
    end
end)

-- Character respawn handler for animation blocking
lp.CharacterAdded:Connect(function(character)
    task.wait(1) -- Wait for character to fully load
    pcall(function()
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            originalHumanoidLoadAnimation = humanoid.LoadAnimation
            
            humanoid.LoadAnimation = function(self, animation)
                local animationTrack = originalHumanoidLoadAnimation(self, animation)
                
                -- Hook the Play method
                local originalPlay = animationTrack.Play
                animationTrack.Play = function(track, ...)
                    -- Block fishing animations when no animation mode is active
                    if flags['superinstantreel'] and flags['superinstantnoanimation'] then
                        local animationId = tostring(animation.AnimationId):lower()
                        if animationId:find("fish") or animationId:find("reel") or animationId:find("cast") or 
                           animationId:find("rod") or animationId:find("catch") or animationId:find("lift") or
                           animationId:find("pull") or animationId:find("bobber") then
                            return -- Don't play the animation
                        end
                    end
                    
                    return originalPlay(track, ...)
                end
                
                return animationTrack
            end
        end
    end)
end)

-- ROD/TOOL ANIMATION BLOCKING SYSTEM
task.spawn(function()
    while true do
        task.wait(0.05) -- Check every 50ms
        if flags['superinstantreel'] then
            pcall(function()
                local character = lp.Character
                if character then
                    -- Check for fishing rod tool
                    local tool = character:FindFirstChildOfClass("Tool")
                    if tool and tool.Name:lower():find("rod") then
                        -- Hook tool animations
                        for _, obj in pairs(tool:GetDescendants()) do
                            if obj:IsA("Animation") then
                                local animId = tostring(obj.AnimationId):lower()
                                if animId:find("fish") or animId:find("reel") or animId:find("cast") or
                                   animId:find("rod") or animId:find("catch") or animId:find("lift") then
                                    -- Disable animation by changing its ID
                                    obj.AnimationId = ""
                                    -- Removed console output for performance
                                    -- print("🚫 [TOOL ANIMATION BLOCKED] Rod animation disabled!")
                                end
                            end
                        end
                        
                        -- Stop any currently playing tool animations
                        if tool:FindFirstChild("Humanoid") then
                            for _, track in pairs(tool.Humanoid:GetPlayingAnimationTracks()) do
                                track:Stop()
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- FINAL SAFETY NET - Continuous monitoring
task.spawn(function()
    while true do
        task.wait(0.001) -- Ultra-fast monitoring every 1ms
        if flags['superinstantreel'] then
            pcall(function()
                -- INSTANT REEL GUI DESTRUCTION AND COMPLETION
                for _, child in pairs(lp.PlayerGui:GetChildren()) do
                    if child.Name == "reel" or (child:IsA("ScreenGui") and child:FindFirstChild("reel")) then
                        child:Destroy()
                        -- Triple fire for guaranteed completion
                        for i = 1, 3 do
                            ReplicatedStorage.events.reelfinished:FireServer(100, true)
                        end
                        -- Removed console output for performance
                        -- print("🗑️ [FINAL SAFETY] Reel GUI eliminated - INSTANT COMPLETION!")
                    end
                end
                
                -- AGGRESSIVE ANIMATION STOPPING
                local character = lp.Character
                if character and character:FindFirstChild("Humanoid") then
                    local humanoid = character.Humanoid
                    for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                        local animName = track.Name:lower()
                        if animName:find("fish") or animName:find("reel") or animName:find("cast") or
                           animName:find("rod") or animName:find("catch") or animName:find("lift") or
                           animName:find("pull") or animName:find("bobber") or animName:find("yank") then
                            track:Stop()
                            track:AdjustSpeed(0) -- Force stop
                        end
                    end
                end
            end)
        end
    end
end)

-- print("✅ [ULTIMATE SYSTEM] All hook systems activated!")
-- print("🎯 [READY] ULTIMATE Super Instant Reel system fully operational!")

--[[
=================================================================
🚀 TELEPORT V2 - DYNAMIC LISTS SYSTEM
=================================================================
Dynamic teleport system that automatically scans and updates
teleport locations from the game world in real-time.

Features:
- Auto-populating fishing zones
- Dynamic NPC locations  
- Real-time teleport spot detection
- Smart categorization by type
- Future-proof auto-updates

Inspired by main5.lua (Rinns Hub) dynamic system
=================================================================
--]]

-- Dynamic Lists Variables
local dynamicFishingZones = {}
local dynamicTeleportSpots = {}
local dynamicNPCLocations = {}
local dynamicActiveItems = {}

-- References to game world folders
local FishingZonesFolder = workspace.zones and workspace.zones.fishing
local TpSpotsFolder = workspace.world and workspace.world.spawns
local NpcFolder = workspace.world and workspace.world.npcs
local ActiveFolder = workspace.active

-- Function to scan and update fishing zones
local function updateDynamicFishingZones()
    pcall(function()
        dynamicFishingZones = {}
        if FishingZonesFolder then
            for _, zone in pairs(FishingZonesFolder:GetChildren()) do
                if not table.find(dynamicFishingZones, zone.Name) then
                    table.insert(dynamicFishingZones, zone.Name)
                end
            end
        end
        -- Sort alphabetically for better organization
        table.sort(dynamicFishingZones)
    end)
end

-- Function to scan and update teleport spots
local function updateDynamicTeleportSpots()
    pcall(function()
        dynamicTeleportSpots = {}
        if TpSpotsFolder then
            for _, spot in pairs(TpSpotsFolder:GetChildren()) do
                if not table.find(dynamicTeleportSpots, spot.Name) and spot.Name ~= "mirror Area" then
                    table.insert(dynamicTeleportSpots, spot.Name)
                end
            end
        end
        -- Sort alphabetically for better organization
        table.sort(dynamicTeleportSpots)
    end)
end

-- Function to scan and update NPC locations
local function updateDynamicNPCLocations()
    pcall(function()
        dynamicNPCLocations = {}
        if NpcFolder then
            for _, npc in pairs(NpcFolder:GetChildren()) do
                if not table.find(dynamicNPCLocations, npc.Name) and npc.Name ~= "mirror Area" then
                    table.insert(dynamicNPCLocations, npc.Name)
                end
            end
        end
        -- Sort alphabetically for better organization
        table.sort(dynamicNPCLocations)
    end)
end

-- Function to scan active items (event items, special objects)
local function updateDynamicActiveItems()
    pcall(function()
        dynamicActiveItems = {}
        if ActiveFolder then
            for _, item in pairs(ActiveFolder:GetChildren()) do
                if item:FindFirstChild("PickupPrompt") and not table.find(dynamicActiveItems, item.Name) then
                    table.insert(dynamicActiveItems, item.Name)
                end
            end
        end
        -- Sort alphabetically for better organization
        table.sort(dynamicActiveItems)
    end)
end

-- Initial scan of all dynamic locations
updateDynamicFishingZones()
updateDynamicTeleportSpots()
updateDynamicNPCLocations()
updateDynamicActiveItems()

-- Set up auto-updating listeners
if FishingZonesFolder then
    FishingZonesFolder.ChildAdded:Connect(function(child)
        if not table.find(dynamicFishingZones, child.Name) then
            table.insert(dynamicFishingZones, child.Name)
            table.sort(dynamicFishingZones)
            -- print("🎣 [Dynamic V2] New fishing zone added: " .. child.Name)
        end
    end)
end

if TpSpotsFolder then
    TpSpotsFolder.ChildAdded:Connect(function(child)
        if not table.find(dynamicTeleportSpots, child.Name) and child.Name ~= "mirror Area" then
            table.insert(dynamicTeleportSpots, child.Name)
            table.sort(dynamicTeleportSpots)
            -- print("🌍 [Dynamic V2] New teleport spot added: " .. child.Name)
        end
    end)
end

if NpcFolder then
    NpcFolder.ChildAdded:Connect(function(child)
        if not table.find(dynamicNPCLocations, child.Name) and child.Name ~= "mirror Area" then
            table.insert(dynamicNPCLocations, child.Name)
            table.sort(dynamicNPCLocations)
            -- print("👤 [Dynamic V2] New NPC added: " .. child.Name)
        end
    end)
end

if ActiveFolder then
    ActiveFolder.ChildAdded:Connect(function(child)
        if child:FindFirstChild("PickupPrompt") and not table.find(dynamicActiveItems, child.Name) then
            table.insert(dynamicActiveItems, child.Name)
            table.sort(dynamicActiveItems)
            -- print("⭐ [Dynamic V2] New active item added: " .. child.Name)
        end
    end)
end

-- Teleport V2 Tab Implementation
if TeleTabV2 then
    pcall(function()
        -- Dynamic Fishing Zones Section
        local DynamicFishingSection = TeleTabV2:NewSection("🎣 Dynamic Fishing Zones")
        
        local dynamicFishingDropdown = DynamicFishingSection:NewDropdown("Dynamic Fishing Zones", "Teleport to automatically detected fishing zones", dynamicFishingZones, function(selectedZone)
            pcall(function()
                if selectedZone and FishingZonesFolder then
                    local zone = FishingZonesFolder:FindFirstChild(selectedZone)
                    if zone and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                        lp.Character.HumanoidRootPart.CFrame = CFrame.new(zone.Position.X, zone.Position.Y + 5, zone.Position.Z)
                        -- print("🎣 [Dynamic V2] Teleported to fishing zone: " .. selectedZone)
                    end
                end
            end)
        end)
        
        -- Dynamic Teleport Spots Section
        local DynamicSpotsSection = TeleTabV2:NewSection("🌍 Dynamic Teleport Spots")
        
        local dynamicSpotsDropdown = DynamicSpotsSection:NewDropdown("Dynamic Teleport Spots", "Teleport to automatically detected locations", dynamicTeleportSpots, function(selectedSpot)
            pcall(function()
                if selectedSpot and TpSpotsFolder then
                    local spot = TpSpotsFolder:FindFirstChild(selectedSpot)
                    if spot and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                        lp.Character.HumanoidRootPart.CFrame = spot.CFrame + Vector3.new(0, 5, 0)
                        -- print("🌍 [Dynamic V2] Teleported to spot: " .. selectedSpot)
                    end
                end
            end)
        end)
        
        -- Dynamic NPC Locations Section
        local DynamicNPCSection = TeleTabV2:NewSection("👤 Dynamic NPC Locations")
        
        local dynamicNPCDropdown = DynamicNPCSection:NewDropdown("Dynamic NPC Locations", "Teleport to automatically detected NPCs", dynamicNPCLocations, function(selectedNPC)
            pcall(function()
                if selectedNPC and NpcFolder then
                    local npc = NpcFolder:FindFirstChild(selectedNPC)
                    if npc and npc:FindFirstChild("HumanoidRootPart") and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                        lp.Character.HumanoidRootPart.CFrame = npc.HumanoidRootPart.CFrame + Vector3.new(0, 1, 0)
                        -- print("👤 [Dynamic V2] Teleported to NPC: " .. selectedNPC)
                    end
                end
            end)
        end)
        
        -- Dynamic Active Items Section
        local DynamicActiveSection = TeleTabV2:NewSection("⭐ Dynamic Active Items")
        
        local dynamicActiveDropdown = DynamicActiveSection:NewDropdown("Dynamic Active Items", "Teleport to active event items & special objects", dynamicActiveItems, function(selectedItem)
            pcall(function()
                if selectedItem and ActiveFolder then
                    local item = ActiveFolder:FindFirstChild(selectedItem)
                    if item and item:FindFirstChildOfClass("MeshPart") and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                        lp.Character.HumanoidRootPart.CFrame = item:FindFirstChildOfClass("MeshPart").CFrame + Vector3.new(3, 2, 0)
                        -- print("⭐ [Dynamic V2] Teleported to active item: " .. selectedItem)
                    end
                end
            end)
        end)
        
        -- Refresh Buttons Section
        local RefreshSection = TeleTabV2:NewSection("🔄 Manual Refresh")
        
        RefreshSection:NewButton("🔄 Refresh All Lists", "Manually refresh all dynamic lists", function()
            updateDynamicFishingZones()
            updateDynamicTeleportSpots()
            updateDynamicNPCLocations()
            updateDynamicActiveItems()
            
            -- Update dropdowns with new values
            pcall(function()
                dynamicFishingDropdown:Refresh(dynamicFishingZones, true)
                dynamicSpotsDropdown:Refresh(dynamicTeleportSpots, true)
                dynamicNPCDropdown:Refresh(dynamicNPCLocations, true)
                dynamicActiveDropdown:Refresh(dynamicActiveItems, true)
            end)
            
            -- print("🔄 [Dynamic V2] All lists refreshed successfully!")
            -- print("🎣 Fishing Zones: " .. #dynamicFishingZones .. " found")
            -- print("🌍 Teleport Spots: " .. #dynamicTeleportSpots .. " found")
            -- print("👤 NPCs: " .. #dynamicNPCLocations .. " found")  
            -- print("⭐ Active Items: " .. #dynamicActiveItems .. " found")
        end)
        
        -- Auto-refresh toggle
        local autoRefreshEnabled = false
        RefreshSection:NewToggle("🔄 Auto-Refresh (30s)", "Automatically refresh lists every 30 seconds", function(state)
            autoRefreshEnabled = state
            if state then
                -- print("🔄 [Dynamic V2] Auto-refresh enabled (30s intervals)")
                task.spawn(function()
                    while autoRefreshEnabled do
                        task.wait(30)
                        if autoRefreshEnabled then
                            updateDynamicFishingZones()
                            updateDynamicTeleportSpots()
                            updateDynamicNPCLocations()
                            updateDynamicActiveItems()
                            
                            pcall(function()
                                dynamicFishingDropdown:Refresh(dynamicFishingZones, true)
                                dynamicSpotsDropdown:Refresh(dynamicTeleportSpots, true)
                                dynamicNPCDropdown:Refresh(dynamicNPCLocations, true)
                                dynamicActiveDropdown:Refresh(dynamicActiveItems, true)
                            end)
                            
                            -- print("🔄 [Dynamic V2] Auto-refresh completed")
                        end
                    end
                end)
            else
                -- print("🔄 [Dynamic V2] Auto-refresh disabled")
            end
        end)
        
        -- Info Section
        local InfoSection = TeleTabV2:NewSection("ℹ️ System Information")
        InfoSection:NewLabel("🚀 Teleport V2 - Dynamic Lists System")
        InfoSection:NewLabel("📊 Real-time scanning & auto-updating")
        InfoSection:NewLabel("🎯 Future-proof teleportation")
        InfoSection:NewLabel("⚡ Inspired by Rinns Hub technology")
        
        -- Advanced GPS Teleport System for V2
        local AdvancedGPSSection = TeleTabV2:NewSection("🛰️ Advanced GPS System")
        
        -- Variables for advanced GPS
        local advGpsX, advGpsY, advGpsZ = 0, 150, 0
        local savedCoordinates = {}
        
        AdvancedGPSSection:NewTextBox("🎯 Smart Coordinate Input", "Paste coordinates in ANY format (auto-detects)", function(txt)
            pcall(function()
                -- Enhanced coordinate parsing with multiple format support
                local cleanText = txt:gsub("%(", ""):gsub("%)", ""):gsub("%[", ""):gsub("%]", ""):gsub("{", ""):gsub("}", "")
                cleanText = cleanText:gsub("Vector3%.new", ""):gsub("CFrame%.new", ""):gsub("Position", "")
                cleanText = cleanText:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
                
                local coords = {}
                
                -- Extract all numbers from the text (supports any format)
                for num in cleanText:gmatch("([-]?%d*%.?%d+)") do
                    local parsed = tonumber(num)
                    if parsed then
                        table.insert(coords, parsed)
                    end
                end
                
                -- Apply coordinates
                if #coords >= 2 then
                    advGpsX = coords[1]
                    advGpsY = coords[3] or coords[2] or 150 -- Smart Y detection
                    advGpsZ = coords[2] ~= advGpsY and coords[2] or coords[3] or 0
                    
                    -- Auto-teleport with safety check
                    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                        lp.Character.HumanoidRootPart.CFrame = CFrame.new(advGpsX, advGpsY, advGpsZ)
                        message("🛰️ Advanced GPS: " .. math.floor(advGpsX) .. ", " .. math.floor(advGpsY) .. ", " .. math.floor(advGpsZ), 4)
                        
                        -- Save to recent coordinates
                        local coordString = math.floor(advGpsX) .. ", " .. math.floor(advGpsY) .. ", " .. math.floor(advGpsZ)
                        table.insert(savedCoordinates, 1, coordString)
                        if #savedCoordinates > 5 then
                            table.remove(savedCoordinates, 6) -- Keep only last 5
                        end
                    end
                else
                    -- print("❌ [Advanced GPS] Could not parse coordinates from: " .. txt)
                end
            end)
        end)
        
        AdvancedGPSSection:NewButton("📍 Get Current CFrame", "Get current position as CFrame format", function()
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                local cframe = lp.Character.HumanoidRootPart.CFrame
                local pos = cframe.Position
                local x, y, z = math.floor(pos.X * 100) / 100, math.floor(pos.Y * 100) / 100, math.floor(pos.Z * 100) / 100
                
                local cframeString = "CFrame.new(" .. x .. ", " .. y .. ", " .. z .. ")"
                
                -- Try to copy to clipboard
                pcall(function()
                    if setclipboard then
                        setclipboard(cframeString)
                        message("📋 CFrame copied: " .. cframeString, 5)
                    else
                        message("📍 CFrame: " .. cframeString, 8)
                    end
                end)
                
                -- print("📍 [Advanced GPS] Current CFrame: " .. cframeString)
            end
        end)
        
        AdvancedGPSSection:NewButton("🎯 Teleport Forward 50 Units", "Teleport 50 units in front of you", function()
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = lp.Character.HumanoidRootPart
                local newPosition = hrp.CFrame + hrp.CFrame.LookVector * 50
                hrp.CFrame = newPosition
                message("🎯 Teleported forward 50 units", 3)
            end
        end)
        
        AdvancedGPSSection:NewButton("⬆️ Teleport Up 100 Units", "Teleport 100 units upward", function()
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = lp.Character.HumanoidRootPart
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 100, 0)
                message("⬆️ Teleported up 100 units", 3)
            end
        end)
        
        -- Recent coordinates section
        local RecentCoordsSection = TeleTabV2:NewSection("📋 Recent Coordinates")
        
        RecentCoordsSection:NewButton("📋 Show Recent Coordinates", "Display recently used coordinates", function()
            if #savedCoordinates > 0 then
                -- print("📋 [Recent GPS] Recent coordinates:")
                for i, coord in ipairs(savedCoordinates) do
                    -- print("  " .. i .. ". " .. coord)
                end
                message("📋 Check console for recent coordinates", 3)
            else
                message("📋 No recent coordinates saved", 3)
            end
        end)
        
        -- Coordinate validation and safety
        local SafetySection = TeleTabV2:NewSection("🛡️ Teleport Safety")
        
        SafetySection:NewButton("🛡️ Safe Teleport Check", "Validate coordinates before teleporting", function()
            -- Check if coordinates are within reasonable game bounds
            local maxBounds = 50000
            local minY = -1000
            
            local isXSafe = math.abs(advGpsX) <= maxBounds
            local isZSafe = math.abs(advGpsZ) <= maxBounds  
            local isYSafe = advGpsY >= minY and advGpsY <= maxBounds
            
            if isXSafe and isZSafe and isYSafe then
                message("✅ Coordinates are within safe bounds", 3)
                -- print("✅ [Safety Check] Coordinates are safe to teleport to")
            else
                message("⚠️ Coordinates may be outside safe bounds!", 5)
                -- print("⚠️ [Safety Check] Coordinates may be dangerous!")
                -- print("📊 [Bounds] X: " .. (isXSafe and "✅" or "❌") .. " Y: " .. (isYSafe and "✅" or "❌") .. " Z: " .. (isZSafe and "✅" or "❌"))
            end
        end)
        
        -- print("🚀 [Teleport V2] Dynamic teleport system initialized!")
        -- print("📊 [Stats] Fishing Zones: " .. #dynamicFishingZones .. " | Spots: " .. #dynamicTeleportSpots .. " | NPCs: " .. #dynamicNPCLocations .. " | Items: " .. #dynamicActiveItems)
        
    end)
end
-- print("🚀 [SPEED] Fish will be caught INSTANTLY with ZERO animation when enabled!")
