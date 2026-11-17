--!native
--!optimize 2
--[[
    ULTIMATE LUMBER TYCOON 2 SCRIPT HUB (V4.0 ENTERPRISE)
    Target Environment: Roblox Luau / Delta Executor & Standard Luau Sandboxes
    Target PlaceId: 13822889 (Lumber Tycoon 2)
    Architecture: Modular Single-File Build (Compat, State, Databases, Core Engines, Custom UI)
]]

--------------------------------------------------------------------------------
-- 1. SERVICES & DELTA EXECUTOR COMPATIBILITY LAYER
--------------------------------------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

local Compat = {}
do
    function Compat.GetGuiParent(): Instance
        local ok, hui = pcall(function()
            return type(gethui) == "function" and gethui() or nil
        end)
        if ok and hui then return hui end

        local okCore, _ = pcall(function()
            return CoreGui.Name
        end)
        if okCore then return CoreGui end

        return LocalPlayer:WaitForChild("PlayerGui")
    end

    Compat.HasFileSystem = (
        type(writefile) == "function"
        and type(readfile) == "function"
        and type(isfile) == "function"
    )

    function Compat.WriteFile(path: string, data: string): boolean
        if not Compat.HasFileSystem then return false end
        local ok = pcall(function()
            if type(makefolder) == "function" and type(isfolder) == "function" then
                if not isfolder("LT2_UltimateHub") then
                    makefolder("LT2_UltimateHub")
                end
            end
            writefile(path, data)
        end)
        return ok
    end

    function Compat.ReadFile(path: string): string?
        if not Compat.HasFileSystem then return nil end
        local ok, content = pcall(function()
            if isfile(path) then
                return readfile(path)
            end
            return nil
        end)
        return ok and content or nil
    end
end

--------------------------------------------------------------------------------
-- 2. VERIFIED DATABASES (WOODS, ITEMS, LOCATIONS, BLUEPRINTS)
--------------------------------------------------------------------------------
local Databases = {}

Databases.WoodTypes = {
    { Name = "Generic", Display = "Generic (Oak)", Category = "Standard", Biome = "Main Biome", ValueRank = 1 },
    { Name = "Birch", Display = "Birch", Category = "Standard", Biome = "Main / Tropics", ValueRank = 2 },
    { Name = "Cherry", Display = "Cherry", Category = "Standard", Biome = "Cherry Meadow", ValueRank = 3 },
    { Name = "Walnut", Display = "Walnut", Category = "Standard", Biome = "Main / Mountains", ValueRank = 4 },
    { Name = "Fir", Display = "Fir", Category = "Standard", Biome = "Taiga", ValueRank = 5 },
    { Name = "Pine", Display = "Pine", Category = "Standard", Biome = "Taiga", ValueRank = 5 },
    { Name = "Koa", Display = "Koa", Category = "Standard", Biome = "Tropics", ValueRank = 6 },
    { Name = "Palm", Display = "Palm", Category = "Island", Biome = "Palm Island", ValueRank = 7 },
    { Name = "Lava", Display = "Lava (Volcano)", Category = "Hazard", Biome = "Volcano", ValueRank = 8 },
    { Name = "Volcano", Display = "Volcano (Alt Tag)", Category = "Hazard", Biome = "Volcano", ValueRank = 8 },
    { Name = "GreenSwampy", Display = "Zombie (GreenSwampy)", Category = "Swamp", Biome = "Swamp", ValueRank = 9 },
    { Name = "GoldSwampy", Display = "Gold (GoldSwampy)", Category = "Swamp", Biome = "Swamp", ValueRank = 10 },
    { Name = "CaveCrawler", Display = "Cave Crawler (Blue)", Category = "Cave", Biome = "Maze Cave", ValueRank = 11 },
    { Name = "Frost", Display = "Frost", Category = "Mountain", Biome = "Taiga Peak", ValueRank = 12 },
    { Name = "SnowGlow", Display = "SnowGlow", Category = "Special", Biome = "Snow Biome", ValueRank = 13 },
    { Name = "LoneCave", Display = "Phantom (LoneCave)", Category = "EndTimes", Biome = "Lone Cave", ValueRank = 14 },
    { Name = "Spooky", Display = "Spooky", Category = "Event", Biome = "Random Spawn", ValueRank = 15 },
    { Name = "SpookyNeon", Display = "Sinister (SpookyNeon)", Category = "Event", Biome = "Random Spawn", ValueRank = 16 },
    { Name = "BlueSpruce", Display = "Blue Spruce", Category = "Event", Biome = "Winter Event", ValueRank = 12 },
}

Databases.WoodLookup = {}
for _, w in ipairs(Databases.WoodTypes) do
    Databases.WoodLookup[w.Name] = w
end

Databases.KnownItems = {
    -- Axes
    Axes = {
        "BasicHatchet", "PlainAxe", "SteelAxe", "HardenedAxe", "SilverAxe",
        "Rukiryaxe", "BetaAxe", "AlphaAxe", "FireAxe", "EndTimesAxe",
        "CandyCaneAxe", "Beesaxe", "ChickenAxe", "AmberAxe", "ManyAxe",
        "GingerbreadAxe", "RustyAxe", "OvergrownAxe", "CaveAxe", "FrostAxe", "BluesteelAxe"
    },
    -- Sawmills & Processing
    Processing = {
        "Sawmill", "Sawmill2", "Sawmill3", "Sawmill4", "Sawmill4L",
        "ChopSaw", "LogSweeper", "WoodChecker", "StraightConveyor",
        "TiltConveyor", "TightTurnConveyor", "ConveyorFunnel", "ConveyorSwitch"
    },
    -- Vehicles
    Vehicles = {
        "UtilityTruck", "UtilityTruck2", "Pickup1", "SmallTrailer", "Trailer2", "Hauler"
    },
    -- Logic & Utility
    LogicAndUtility = {
        "WorkLight", "Wire", "Button0", "Switch0", "Lever0", "Laser",
        "LaserReceiver", "SignalSustain", "Hatch", "GateXOR", "GateAND",
        "GateOR", "GateNOT", "ClockSwitch", "PressurePlate", "BagOfSand",
        "CanOfWorms", "Dynamite", "LightBulb", "Eye1", "Pumpkin", "Turkey"
    }
}

Databases.Locations = {
    -- Shops
    ["Wood R Us"] = CFrame.new(265, 5, 57),
    ["Land Store"] = CFrame.new(258, 5, -99),
    ["Boxed Cars"] = CFrame.new(509, 5.2, -1463),
    ["Fancy Furnishings"] = CFrame.new(491, 13, -1720),
    ["Link's Logic"] = CFrame.new(4607, 9, -798),
    ["Fine Arts Shop"] = CFrame.new(5207, -156, 719),
    ["Bob's Shack"] = CFrame.new(260, 10, -2542),
    -- Biomes & Trees
    ["SpawnPoint"] = CFrame.new(155, 5, 74),
    ["Volcano (Lava Wood)"] = CFrame.new(-1585, 625, 1140),
    ["Swamp (Zombie/Gold)"] = CFrame.new(-1209, 138, -801),
    ["Palm Island"] = CFrame.new(2549, 5, -42),
    ["Cave (CaveCrawler)"] = CFrame.new(3581, -177, 430),
    ["Taiga Peak (Frost Wood)"] = CFrame.new(1452, 415, 3220),
    ["Cherry Meadow"] = CFrame.new(220, 62, 1305),
    ["Tropics (Koa Wood)"] = CFrame.new(4950, 12, -550),
    ["Bridge Toll Booth"] = CFrame.new(112, 15, -977),
    ["Strange Man (Power)"] = CFrame.new(1061, 20, 1131),
    ["Shrine of Sight"] = CFrame.new(-1600, 205, 919),
    ["End Times (LoneCave)"] = CFrame.new(113, -212, -951),
}

Databases.AutoBuildPresets = {
    ["Starter Cabin (3x3)"] = {
        Description = "Compact 3x3 enclosed cabin with doorway, walls, and flat roof.",
        Blocks = {
            -- Floor (Section: Floor)
            { Section = "Floor", Offset = Vector3.new(-4, 0, -4), Size = Vector3.new(4, 1, 4) },
            { Section = "Floor", Offset = Vector3.new(0, 0, -4),  Size = Vector3.new(4, 1, 4) },
            { Section = "Floor", Offset = Vector3.new(4, 0, -4),  Size = Vector3.new(4, 1, 4) },
            { Section = "Floor", Offset = Vector3.new(-4, 0, 0),  Size = Vector3.new(4, 1, 4) },
            { Section = "Floor", Offset = Vector3.new(0, 0, 0),   Size = Vector3.new(4, 1, 4) },
            { Section = "Floor", Offset = Vector3.new(4, 0, 0),   Size = Vector3.new(4, 1, 4) },
            { Section = "Floor", Offset = Vector3.new(-4, 0, 4),  Size = Vector3.new(4, 1, 4) },
            { Section = "Floor", Offset = Vector3.new(0, 0, 4),   Size = Vector3.new(4, 1, 4) },
            { Section = "Floor", Offset = Vector3.new(4, 0, 4),   Size = Vector3.new(4, 1, 4) },
            -- Corner Pillars (Section: Trim)
            { Section = "Trim", Offset = Vector3.new(-5.5, 4.5, -5.5), Size = Vector3.new(1, 8, 1) },
            { Section = "Trim", Offset = Vector3.new(5.5, 4.5, -5.5),  Size = Vector3.new(1, 8, 1) },
            { Section = "Trim", Offset = Vector3.new(-5.5, 4.5, 5.5),  Size = Vector3.new(1, 8, 1) },
            { Section = "Trim", Offset = Vector3.new(5.5, 4.5, 5.5),   Size = Vector3.new(1, 8, 1) },
            -- Walls (Section: Walls)
            { Section = "Walls", Offset = Vector3.new(0, 4.5, -5.5), Size = Vector3.new(10, 8, 1) },
            { Section = "Walls", Offset = Vector3.new(-5.5, 4.5, 0), Size = Vector3.new(1, 8, 10) },
            { Section = "Walls", Offset = Vector3.new(5.5, 4.5, 0),  Size = Vector3.new(1, 8, 10) },
            -- Roof (Section: Roof)
            { Section = "Roof", Offset = Vector3.new(0, 9, 0), Size = Vector3.new(12, 1, 12) },
        }
    },
    ["Sawmill Factory Platform (5x5)"] = {
        Description = "Heavy industrial platform with trim border for sawmill arrays.",
        Blocks = (function()
            local list = {}
            for x = -2, 2 do
                for z = -2, 2 do
                    local isEdge = (math.abs(x) == 2 or math.abs(z) == 2)
                    table.insert(list, {
                        Section = isEdge and "Trim" or "Floor",
                        Offset = Vector3.new(x * 4, 0, z * 4),
                        Size = Vector3.new(4, 1, 4)
                    })
                end
            end
            return list
        end)()
    },
    ["Watchtower Pillar"] = {
        Description = "Elevated 3-tier observation tower with alternating walls and trim.",
        Blocks = {
            { Section = "Floor", Offset = Vector3.new(0, 0, 0), Size = Vector3.new(8, 1, 8) },
            { Section = "Trim",  Offset = Vector3.new(-3.5, 6, -3.5), Size = Vector3.new(1, 12, 1) },
            { Section = "Trim",  Offset = Vector3.new(3.5, 6, -3.5),  Size = Vector3.new(1, 12, 1) },
            { Section = "Trim",  Offset = Vector3.new(-3.5, 6, 3.5),  Size = Vector3.new(1, 12, 1) },
            { Section = "Trim",  Offset = Vector3.new(3.5, 6, 3.5),   Size = Vector3.new(1, 12, 1) },
            { Section = "Walls", Offset = Vector3.new(0, 12.5, 0),    Size = Vector3.new(8, 1, 8) },
            { Section = "Roof",  Offset = Vector3.new(0, 18, 0),      Size = Vector3.new(10, 1, 10) },
        }
    }
}

--------------------------------------------------------------------------------
-- 3. GLOBAL CONFIGURATION, STATE & CONNECTION MANAGER
--------------------------------------------------------------------------------
local ConfigPath = "LT2_UltimateHub/config_v4.json"

local DefaultSettings = {
    WalkSpeed = 16,
    JumpPower = 50,
    FlySpeed = 75,
    WaterWalk = false,
    FreeLandVisual = false,
    UIScale = 1.0,
    AccentColor = { R = 16, G = 185, B = 129 }, -- Emerald Green
    NotificationsEnabled = true,
    DebugMode = false,
    SavedLocations = {},
    AutoBuildMaterials = {
        Floor = "Generic",
        Walls = "Birch",
        Roof = "Walnut",
        Trim = "Cherry"
    },
    AutoBuildGridSpacing = 4,
    AutoBuildRotation = 0,
    SelectedWoodTypes = { ["Generic"] = true },
    WoodMinVolume = 1,
    WoodQuantityLimit = 25,
}

local State = {
    Settings = table.clone(DefaultSettings),
    Flags = {
        SpeedEnabled = false,
        JumpEnabled = false,
        FlyEnabled = false,
        NoclipEnabled = false,
        Spectating = false,
        AutoSawmill = false,
        AutoCleanLogs = false,
        AutoBuildRunning = false,
        AutoBuildPaused = false,
        EmergencyStop = false,
    },
    ReturnPosition = nil :: CFrame?,
    SelectedPlayerName = "",
    SelectedItemCategory = "All",
    SelectedItemInstances = {} :: { [Model]: boolean },
    SelectedTreeClass = "Generic",
    SelectedBlueprintPreset = "Starter Cabin (3x3)",
    PreviewFolder = nil :: Folder?,
    Connections = {} :: { [string]: RBXScriptConnection },
}

local function BindConnection(key: string, conn: RBXScriptConnection)
    if State.Connections[key] then
        State.Connections[key]:Disconnect()
    end
    State.Connections[key] = conn
end

local function UnbindConnection(key: string)
    if State.Connections[key] then
        State.Connections[key]:Disconnect()
        State.Connections[key] = nil
    end
end

local function CleanupAllConnections()
    for key, conn in pairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
        State.Connections[key] = nil
    end
end

local Notify: (title: string, message: string, duration: number?) -> () = function() end

local function LogDebug(msg: string)
    if State.Settings.DebugMode then
        warn("[LT2-HUB DEBUG]: " .. tostring(msg))
    end
end

local function SaveConfiguration()
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(State.Settings)
    end)
    if ok and encoded then
        if Compat.WriteFile(ConfigPath, encoded) then
            Notify("Settings Saved", "Saved configuration to " .. ConfigPath, 3)
        else
            Notify("Save Notice", "Executor filesystem unavailable; kept in session memory.", 3)
        end
    end
end

local function LoadConfiguration()
    local raw = Compat.ReadFile(ConfigPath)
    if not raw then return false end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if ok and type(decoded) == "table" then
        for k, v in pairs(decoded) do
            State.Settings[k] = v
        end
        return true
    end
    return false
end

LoadConfiguration()

--------------------------------------------------------------------------------
-- 4. CORE GAME INTERACTION ENGINE (REMOTES, DRAGGING, TELEPORT, PLOTS)
--------------------------------------------------------------------------------
local Engine = {}

function Engine.GetCharacter(): (Model?, BasePart?, Humanoid?)
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    local hum = char:FindFirstChildOfClass("Humanoid")
    return char, hrp, hum
end

function Engine.GetClientIsDraggingRemote(): RemoteEvent?
    local interaction = ReplicatedStorage:FindFirstChild("Interaction")
    if interaction then
        return interaction:FindFirstChild("ClientIsDragging") :: RemoteEvent?
    end
    return nil
end

function Engine.GetPlaceStructureRemote(): RemoteEvent?
    local placeFolder = ReplicatedStorage:FindFirstChild("PlaceStructure")
    if placeFolder then
        return placeFolder:FindFirstChild("ClientPlacedStructure") :: RemoteEvent?
    end
    return nil
end

function Engine.TeleportCharacter(targetCFrame: CFrame)
    local char, hrp, hum = Engine.GetCharacter()
    if not char or not hrp then return false end

    State.ReturnPosition = hrp.CFrame

    if hum and hum.SeatPart then
        hum.Sit = false
        task.wait(0.08)
    end

    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    char:PivotTo(targetCFrame + Vector3.new(0, 3.2, 0))
    return true
end

function Engine.GetPlayerPlot(targetPlayer: Player?): (Model?, BasePart?)
    local p = targetPlayer or LocalPlayer
    local props = Workspace:FindFirstChild("Properties")
    if not props then return nil, nil end

    for _, plot in ipairs(props:GetChildren()) do
        local ownerVal = plot:FindFirstChild("Owner") :: ObjectValue?
        if ownerVal and ownerVal.Value == p then
            local origin = plot:FindFirstChild("OriginSquare") :: BasePart?
            return plot :: Model, origin
        end
    end
    return nil, nil
end

function Engine.GetFreePlot(): (Model?, BasePart?)
    local props = Workspace:FindFirstChild("Properties")
    if not props then return nil, nil end

    for _, plot in ipairs(props:GetChildren()) do
        local ownerVal = plot:FindFirstChild("Owner") :: ObjectValue?
        if ownerVal and ownerVal.Value == nil then
            local origin = plot:FindFirstChild("OriginSquare") :: BasePart?
            return plot :: Model, origin
        end
    end
    return nil, nil
end

function Engine.ZeroModelVelocity(model: Model)
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("BasePart") then
            desc.AssemblyLinearVelocity = Vector3.zero
            desc.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

-- Safely moves an unanchored model using LT2's ClientIsDragging ownership remote
function Engine.TeleportModel(model: Model, targetCFrame: CFrame, returnPlayer: boolean?): boolean
    if State.Flags.EmergencyStop then return false end
    if not model or not model.Parent then return false end

    local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not primary or primary.Anchored then
        return false
    end

    local char, hrp, _ = Engine.GetCharacter()
    if not char or not hrp then return false end

    local savedPos = hrp.CFrame
    local dragRemote = Engine.GetClientIsDraggingRemote()

    -- Step near the object if it is far to acquire physics authority cleanly
    local dist = (hrp.Position - primary.Position).Magnitude
    if dist > 28 then
        char:PivotTo(primary.CFrame * CFrame.new(0, 4, 3))
        hrp.AssemblyLinearVelocity = Vector3.zero
        task.wait(0.06)
    end

    for _ = 1, 3 do
        if dragRemote then
            pcall(function()
                dragRemote:FireServer(model)
            end)
        end
        Engine.ZeroModelVelocity(model)
        model:PivotTo(targetCFrame)
        Engine.ZeroModelVelocity(model)
        task.wait(0.03)
    end

    if returnPlayer and savedPos then
        char:PivotTo(savedPos)
        hrp.AssemblyLinearVelocity = Vector3.zero
    end

    return true
end

--------------------------------------------------------------------------------
-- 5. WOOD, TREE & ITEM SCANNING ENGINE
--------------------------------------------------------------------------------
function Engine.GetModelVolume(model: Model): number
    local totalVol = 0
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            totalVol += (part.Size.X * part.Size.Y * part.Size.Z)
        end
    end
    return math.floor(totalVol * 10) / 10
end

-- Scans both Workspace.LogModels and Workspace.PlayerModels for cut wood/planks
function Engine.ScanLooseWood(filterClasses: { [string]: boolean }?, ownedOnly: boolean?): { { Model: Model, TreeClass: string, Volume: number, IsPlank: boolean, OwnerName: string } }
    local results = {}
    local containers = {
        Workspace:FindFirstChild("LogModels"),
        Workspace:FindFirstChild("PlayerModels")
    }

    for _, container in ipairs(containers) do
        if container then
            for _, obj in ipairs(container:GetChildren()) do
                if obj:IsA("Model") then
                    local treeClassVal = obj:FindFirstChild("TreeClass") :: StringValue?
                    if treeClassVal and type(treeClassVal.Value) == "string" then
                        local tClass = treeClassVal.Value
                        if not filterClasses or filterClasses[tClass] then
                            local ownerObj = obj:FindFirstChild("Owner") :: ObjectValue?
                            local ownerPlayer = ownerObj and ownerObj.Value
                            local ownerName = ownerPlayer and tostring(ownerPlayer.Name) or "Unclaimed"

                            if not ownedOnly or (ownerPlayer == LocalPlayer or ownerPlayer == nil) then
                                local vol = Engine.GetModelVolume(obj)
                                if vol >= (State.Settings.WoodMinVolume or 0) then
                                    local isPlank = (container.Name == "PlayerModels" and obj:FindFirstChild("WoodSection") ~= nil)
                                    table.insert(results, {
                                        Model = obj,
                                        TreeClass = tClass,
                                        Volume = vol,
                                        IsPlank = isPlank,
                                        OwnerName = ownerName
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return results
end

-- Scans all TreeRegions for living trees
function Engine.ScanLivingTrees(targetTreeClass: string?): { { Model: Model, TreeClass: string, Trunk: BasePart, Mass: number } }
    local trees = {}
    for _, region in ipairs(Workspace:GetChildren()) do
        if region.Name == "TreeRegion" then
            for _, tree in ipairs(region:GetChildren()) do
                if tree:IsA("Model") then
                    local tc = tree:FindFirstChild("TreeClass") :: StringValue?
                    if tc and (not targetTreeClass or targetTreeClass == "All" or tc.Value == targetTreeClass) then
                        local trunk: BasePart? = nil
                        local sectionCount = 0
                        for _, child in ipairs(tree:GetChildren()) do
                            if child.Name == "WoodSection" and child:IsA("BasePart") then
                                sectionCount += 1
                                local idVal = child:FindFirstChild("ID") :: IntValue?
                                if idVal and idVal.Value == 1 then
                                    trunk = child
                                elseif not trunk then
                                    trunk = child
                                end
                            end
                        end
                        if trunk and sectionCount >= 2 then
                            table.insert(trees, {
                                Model = tree,
                                TreeClass = tc.Value,
                                Trunk = trunk,
                                Mass = sectionCount
                            })
                        end
                    end
                end
            end
        end
    end
    table.sort(trees, function(a, b) return a.Mass > b.Mass end)
    return trees
end

-- Scans Workspace.PlayerModels for non-wood items
function Engine.ScanWorldItems(searchQuery: string?, ownedByMeOnly: boolean?): { { Model: Model, ItemName: string, Owner: string, Distance: number, Position: Vector3 } }
    local list = {}
    local playerModels = Workspace:FindFirstChild("PlayerModels")
    if not playerModels then return list end

    local _, hrp, _ = Engine.GetCharacter()
    local myPos = hrp and hrp.Position or Vector3.zero
    local q = searchQuery and string.lower(searchQuery) or ""

    for _, model in ipairs(playerModels:GetChildren()) do
        if model:IsA("Model") and not model:FindFirstChild("TreeClass") then
            local itemNameVal = model:FindFirstChild("ItemName") :: StringValue?
            local bpTypeVal = model:FindFirstChild("BlueprintType") :: StringValue?
            local nameStr = (itemNameVal and tostring(itemNameVal.Value))
                or (bpTypeVal and ("Blueprint: " .. tostring(bpTypeVal.Value)))
                or model.Name

            local ownerObj = model:FindFirstChild("Owner") :: ObjectValue?
            local ownerVal = ownerObj and ownerObj.Value
            local isMine = (ownerVal == LocalPlayer)

            if not ownedByMeOnly or isMine then
                if q == "" or string.find(string.lower(nameStr), q, 1, true) then
                    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                    if part and not part.Anchored then
                        local dist = math.floor((part.Position - myPos).Magnitude)
                        table.insert(list, {
                            Model = model,
                            ItemName = nameStr,
                            Owner = ownerVal and tostring(ownerVal) or "None",
                            Distance = dist,
                            Position = part.Position
                        })
                    end
                end
            end
        end
    end

    table.sort(list, function(a, b) return a.Distance < b.Distance end)
    return list
end

-- Finds the player's Sawmill on their plot
function Engine.FindPlayerSawmill(): (Model?, BasePart?)
    local playerModels = Workspace:FindFirstChild("PlayerModels")
    if not playerModels then return nil, nil end

    for _, model in ipairs(playerModels:GetChildren()) do
        local owner = model:FindFirstChild("Owner") :: ObjectValue?
        local itemName = model:FindFirstChild("ItemName") :: StringValue?
        local nameCheck = (itemName and tostring(itemName.Value)) or model.Name
        if owner and owner.Value == LocalPlayer and string.find(string.lower(nameCheck), "sawmill", 1, true) then
            local intake = model:FindFirstChild("Particles")
                or model:FindFirstChild("In")
                or model.PrimaryPart
                or model:FindFirstChildWhichIsA("BasePart")
            if intake and intake:IsA("BasePart") then
                return model, intake
            end
        end
    end
    return nil, nil
end

--------------------------------------------------------------------------------
-- 6. TREE HARVEST & BRING SYSTEM (LEGITIMATE MECHANIC IMPLEMENTATION)
--------------------------------------------------------------------------------
function Engine.GetEquippedOrBackpackAxe(): Tool?
    local char = LocalPlayer.Character
    if char then
        local eq = char:FindFirstChildOfClass("Tool")
        if eq and (eq:FindFirstChild("ToolName") or eq:FindFirstChild("CuttingTool")) then
            return eq
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                return tool
            end
        end
    end
    return nil
end

function Engine.HarvestAndBringTree(treeClass: string)
    task.spawn(function()
        State.Flags.EmergencyStop = false
        local trees = Engine.ScanLivingTrees(treeClass)
        if #trees == 0 then
            Notify("Tree Finder", "No living trees of class '" .. treeClass .. "' found in TreeRegions.", 4)
            return
        end

        local target = trees[1]
        local _, hrp, hum = Engine.GetCharacter()
        if not hrp or not hum then return end

        local savedReturn = hrp.CFrame
        local _, plotOrigin = Engine.GetPlayerPlot(LocalPlayer)
        local dropCFrame = plotOrigin and (plotOrigin.CFrame * CFrame.new(0, 8, 0)) or savedReturn

        Notify("Bring Tree", "Teleporting to " .. treeClass .. " tree (" .. target.Mass .. " sections)...", 3)
        Engine.TeleportCharacter(target.Trunk.CFrame * CFrame.new(0, 2, 4))
        task.wait(0.25)

        local axe = Engine.GetEquippedOrBackpackAxe()
        if axe and axe.Parent ~= LocalPlayer.Character then
            hum:EquipTool(axe)
            task.wait(0.15)
        end

        -- Check if tree has CutEvent or requires physical tool activation
        local cutEvent = target.Model:FindFirstChild("CutEvent") :: RemoteEvent?
        local startTime = os.clock()

        Notify("Bring Tree", "Attempting to fell trunk section...", 3)
        while target.Model.Parent and target.Trunk.Parent and (os.clock() - startTime < 8) do
            if State.Flags.EmergencyStop then
                Notify("Bring Tree", "Aborted by Emergency Stop.", 3)
                return
            end
            if axe then
                pcall(function() axe:Activate() end)
            end
            if cutEvent then
                -- Attempt standard LT2 cut event notification if supported by equipped axe
                pcall(function()
                    cutEvent:FireServer({
                        tool = axe,
                        faceVector = Vector3.new(1, 0, 0),
                        height = 0.3,
                        sectionId = 1,
                        thickness = 1,
                        cooldown = 0.1,
                        breed = target.TreeClass
                    })
                end)
            end
            task.wait(0.15)
        end

        -- Collect newly spawned logs in Workspace.LogModels matching treeClass near the trunk
        task.wait(0.35)
        local logModels = Workspace:FindFirstChild("LogModels")
        local broughtCount = 0
        if logModels then
            for _, log in ipairs(logModels:GetChildren()) do
                if log:IsA("Model") then
                    local tc = log:FindFirstChild("TreeClass") :: StringValue?
                    local part = log.PrimaryPart or log:FindFirstChildWhichIsA("BasePart")
                    if tc and tc.Value == treeClass and part and not part.Anchored then
                        if (part.Position - target.Trunk.Position).Magnitude < 65 then
                            Engine.TeleportModel(log, dropCFrame * CFrame.new(broughtCount * 3, 2, 0), false)
                            broughtCount += 1
                        end
                    end
                end
            end
        end

        Engine.TeleportCharacter(savedReturn)
        if broughtCount > 0 then
            Notify("Bring Tree Complete", "Delivered " .. broughtCount .. " felled log assembly(s) to destination!", 4)
        else
            Notify("Tree Notice", "Teleported to tree. Swing your axe manually if server-side axe cooldown blocked auto-cut, then click 'Recall Cut Logs'.", 5)
        end
    end)
end

--------------------------------------------------------------------------------
-- 7. MULTI-MATERIAL AUTO-BUILD ENGINE (WITH HOLOGRAM PREVIEW & ROLLBACK)
--------------------------------------------------------------------------------
local AutoBuilder = {}
AutoBuilder.PlacedHistory = {} :: { { Model: Model, OriginalCFrame: CFrame } }

function AutoBuilder.ClearPreview()
    if State.PreviewFolder then
        State.PreviewFolder:Destroy()
        State.PreviewFolder = nil
    end
end

function AutoBuilder.GetBuildOriginCFrame(): CFrame
    local _, plotOrigin = Engine.GetPlayerPlot(LocalPlayer)
    local baseCF: CFrame
    if plotOrigin then
        baseCF = plotOrigin.CFrame * CFrame.new(0, 1.5, 0)
    else
        local _, hrp, _ = Engine.GetCharacter()
        baseCF = hrp and (hrp.CFrame * CFrame.new(0, -2.5, -12)) or CFrame.new(0, 10, 0)
    end
    local rotRad = math.rad(State.Settings.AutoBuildRotation or 0)
    return baseCF * CFrame.Angles(0, rotRad, 0)
end

function AutoBuilder.RenderPreview(presetName: string)
    AutoBuilder.ClearPreview()
    local preset = Databases.AutoBuildPresets[presetName]
    if not preset then return end

    local folder = Instance.new("Folder")
    folder.Name = "LT2_AutoBuildPreview"
    folder.Parent = Workspace
    State.PreviewFolder = folder

    local originCF = AutoBuilder.GetBuildOriginCFrame()
    local sectionColors = {
        Floor = Color3.fromRGB(52, 211, 153),
        Walls = Color3.fromRGB(96, 165, 250),
        Roof  = Color3.fromRGB(251, 191, 36),
        Trim  = Color3.fromRGB(244, 114, 182),
    }

    for idx, block in ipairs(preset.Blocks) do
        local p = Instance.new("Part")
        p.Name = "Preview_" .. block.Section .. "_" .. idx
        p.Anchored = true
        p.CanCollide = false
        p.CastShadow = false
        p.Transparency = 0.55
        p.Material = Enum.Material.Neon
        p.Color = sectionColors[block.Section] or Color3.fromRGB(255, 255, 255)
        p.Size = block.Size
        p.CFrame = originCF * CFrame.new(block.Offset)
        p.Parent = folder
    end
    Notify("Preview Active", "Rendered " .. #preset.Blocks .. " hologram blocks for '" .. presetName .. "'.", 3)
end

function AutoBuilder.ExecuteBuild(presetName: string, progressCallback: (text: string, pct: number) -> ())
    if State.Flags.AutoBuildRunning then
        Notify("Auto Build", "Build is already in progress!", 3)
        return
    end

    local preset = Databases.AutoBuildPresets[presetName]
    if not preset then return end

    task.spawn(function()
        State.Flags.AutoBuildRunning = true
        State.Flags.AutoBuildPaused = false
        State.Flags.EmergencyStop = false
        table.clear(AutoBuilder.PlacedHistory)

        local originCF = AutoBuilder.GetBuildOriginCFrame()
        local allLooseWood = Engine.ScanLooseWood(nil, true)
        local usedModels: { [Model]: boolean } = {}
        local placeRemote = Engine.GetPlaceStructureRemote()

        -- Also index any unbuilt blueprints owned by the player
        local playerBlueprints: { Model } = {}
        local pm = Workspace:FindFirstChild("PlayerModels")
        if pm then
            for _, m in ipairs(pm:GetChildren()) do
                local owner = m:FindFirstChild("Owner") :: ObjectValue?
                if owner and owner.Value == LocalPlayer and m:FindFirstChild("BlueprintType") then
                    table.insert(playerBlueprints, m)
                end
            end
        end

        local totalBlocks = #preset.Blocks
        Notify("Auto Build Started", "Constructing '" .. presetName .. "' (" .. totalBlocks .. " structural nodes).", 4)

        for i, block in ipairs(preset.Blocks) do
            if State.Flags.EmergencyStop or not State.Flags.AutoBuildRunning then
                progressCallback("Cancelled at step " .. i .. "/" .. totalBlocks, 0)
                break
            end

            while State.Flags.AutoBuildPaused and State.Flags.AutoBuildRunning and not State.Flags.EmergencyStop do
                progressCallback("Paused (" .. i .. "/" .. totalBlocks .. ")", i / totalBlocks)
                task.wait(0.2)
            end

            local desiredWood = State.Settings.AutoBuildMaterials[block.Section] or "Generic"
            local targetCF = originCF * CFrame.new(block.Offset)

            progressCallback(
                string.format("Step %d/%d [%s -> %s]", i, totalBlocks, block.Section, desiredWood),
                i / totalBlocks
            )

            -- Find an available wood plank/log matching desiredWood first, or fallback to any owned plank
            local chosenWood: Model? = nil
            for _, wEntry in ipairs(allLooseWood) do
                if not usedModels[wEntry.Model] and wEntry.Model.Parent and wEntry.TreeClass == desiredWood then
                    chosenWood = wEntry.Model
                    break
                end
            end
            if not chosenWood then
                for _, wEntry in ipairs(allLooseWood) do
                    if not usedModels[wEntry.Model] and wEntry.Model.Parent then
                        chosenWood = wEntry.Model
                        break
                    end
                end
            end

            -- If player has an unbuilt blueprint in PlayerModels, align it to the target block and feed wood
            local bpModel = playerBlueprints[i]
            if bpModel and bpModel.Parent then
                local origBP = (bpModel.PrimaryPart or bpModel:FindFirstChildWhichIsA("BasePart")).CFrame
                Engine.TeleportModel(bpModel, targetCF, false)
                table.insert(AutoBuilder.PlacedHistory, { Model = bpModel, OriginalCFrame = origBP })
            end

            if chosenWood then
                usedModels[chosenWood] = true
                local primary = chosenWood.PrimaryPart or chosenWood:FindFirstChildWhichIsA("BasePart")
                if primary then
                    table.insert(AutoBuilder.PlacedHistory, { Model = chosenWood, OriginalCFrame = primary.CFrame })
                    Engine.TeleportModel(chosenWood, targetCF, false)
                end
            end

            -- Attempt legitimate structure placement event if player has structure placement unlocked
            if placeRemote then
                pcall(function()
                    placeRemote:FireServer("Wall1", targetCF, LocalPlayer, desiredWood, bpModel, false)
                end)
            end

            task.wait(0.12)
        end

        State.Flags.AutoBuildRunning = false
        progressCallback("Build Complete (" .. totalBlocks .. " sections processed)", 1)
        Notify("Auto Build Finished", "Finished multi-material assembly for " .. presetName, 4)
    end)
end

function AutoBuilder.RollbackLastBuild()
    if #AutoBuilder.PlacedHistory == 0 then
        Notify("Rollback", "No recorded build placements to undo.", 3)
        return
    end
    task.spawn(function()
        Notify("Rollback", "Reverting " .. #AutoBuilder.PlacedHistory .. " placed components...", 3)
        for i = #AutoBuilder.PlacedHistory, 1, -1 do
            local entry = AutoBuilder.PlacedHistory[i]
            if entry.Model and entry.Model.Parent then
                Engine.TeleportModel(entry.Model, entry.OriginalCFrame, false)
            end
        end
        table.clear(AutoBuilder.PlacedHistory)
        Notify("Rollback Complete", "Restored items to their prior positions.", 3)
    end)
end

--------------------------------------------------------------------------------
-- 8. PLAYER MOVEMENT, FLY, NOCLIP & WORLD MODIFIERS
--------------------------------------------------------------------------------
local Movement = {}

function Movement.UpdateStats()
    local _, _, hum = Engine.GetCharacter()
    if not hum then return end
    if State.Flags.SpeedEnabled then
        hum.WalkSpeed = State.Settings.WalkSpeed
    end
    if State.Flags.JumpEnabled then
        hum.UseJumpPower = true
        hum.JumpPower = State.Settings.JumpPower
    end
end

function Movement.SetFly(enabled: boolean)
    State.Flags.FlyEnabled = enabled
    UnbindConnection("FlyLoop")

    local _, hrp, hum = Engine.GetCharacter()
    if hrp then
        local oldBV = hrp:FindFirstChild("LT2_FlyVelocity")
        if oldBV then oldBV:Destroy() end
        local oldBG = hrp:FindFirstChild("LT2_FlyGyro")
        if oldBG then oldBG:Destroy() end
    end
    if hum then
        hum.PlatformStand = false
    end

    if not enabled then return end

    BindConnection("FlyLoop", RunService.RenderStepped:Connect(function()
        if not State.Flags.FlyEnabled or State.Flags.EmergencyStop then return end
        local _, root, humanoid = Engine.GetCharacter()
        if not root or not humanoid then return end

        local cam = Workspace.CurrentCamera
        if not cam then return end

        local bv = root:FindFirstChild("LT2_FlyVelocity") :: BodyVelocity?
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = "LT2_FlyVelocity"
            bv.MaxForce = Vector3.new(1e8, 1e8, 1e8)
            bv.Parent = root
        end

        local bg = root:FindFirstChild("LT2_FlyGyro") :: BodyGyro?
        if not bg then
            bg = Instance.new("BodyGyro")
            bg.Name = "LT2_FlyGyro"
            bg.MaxTorque = Vector3.new(1e8, 1e8, 1e8)
            bg.P = 9000
            bg.Parent = root
        end

        humanoid.PlatformStand = true
        bg.CFrame = cam.CFrame

        local moveVec = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVec -= Vector3.new(0, 1, 0) end

        if moveVec.Magnitude > 0 then
            bv.Velocity = moveVec.Unit * (State.Settings.FlySpeed or 75)
        else
            bv.Velocity = Vector3.zero
        end
    end))
end

function Movement.SetNoclip(enabled: boolean)
    State.Flags.NoclipEnabled = enabled
    UnbindConnection("NoclipLoop")
    if not enabled then return end

    BindConnection("NoclipLoop", RunService.Stepped:Connect(function()
        if not State.Flags.NoclipEnabled or State.Flags.EmergencyStop then return end
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end))
end

function Movement.SetWaterWalk(enabled: boolean)
    State.Settings.WaterWalk = enabled
    local water = Workspace:FindFirstChild("Water")
    if water then
        for _, p in ipairs(water:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = enabled
            end
        end
    end
end

--------------------------------------------------------------------------------
-- 9. PREMIUM CUSTOM DARK UI ENGINE (ALL REQUIRED WIDGETS BUILT-IN)
--------------------------------------------------------------------------------
local GuiParent = Compat.GetGuiParent()
local ExistingGui = GuiParent:FindFirstChild("LT2_UltimateHub_V4")
if ExistingGui then ExistingGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LT2_UltimateHub_V4"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = GuiParent

local UIScaleObj = Instance.new("UIScale")
UIScaleObj.Scale = State.Settings.UIScale or 1.0
UIScaleObj.Parent = ScreenGui

local Theme = {
    BgPrimary = Color3.fromRGB(14, 16, 22),
    BgSecondary = Color3.fromRGB(20, 23, 31),
    BgCard = Color3.fromRGB(26, 30, 40),
    BgInput = Color3.fromRGB(18, 20, 27),
    Border = Color3.fromRGB(42, 48, 62),
    TextPrimary = Color3.fromRGB(240, 244, 250),
    TextSecondary = Color3.fromRGB(156, 163, 175),
    Accent = Color3.fromRGB(State.Settings.AccentColor.R, State.Settings.AccentColor.G, State.Settings.AccentColor.B),
    Danger = Color3.fromRGB(239, 68, 68),
    Warning = Color3.fromRGB(245, 158, 11),
}

local AccentSubscribers: { { Instance: Instance, Prop: string } } = {}
local function BindAccent(inst: Instance, prop: string)
    inst[prop] = Theme.Accent
    table.insert(AccentSubscribers, { Instance = inst, Prop = prop })
end

local function SetAccentColor(color: Color3)
    Theme.Accent = color
    State.Settings.AccentColor = {
        R = math.floor(color.R * 255),
        G = math.floor(color.G * 255),
        B = math.floor(color.B * 255)
    }
    for _, sub in ipairs(AccentSubscribers) do
        if sub.Instance and sub.Instance.Parent then
            sub.Instance[sub.Prop] = color
        end
    end
end

local function Corner(parent: Instance, radius: number): UICorner
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function Stroke(parent: Instance, color: Color3?, thickness: number?): UIStroke
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

-- Notification Container
local NotifHolder = Instance.new("Frame")
NotifHolder.Name = "Notifications"
NotifHolder.AnchorPoint = Vector2.new(1, 1)
NotifHolder.Position = UDim2.new(1, -20, 1, -20)
NotifHolder.Size = UDim2.new(0, 310, 1, -40)
NotifHolder.BackgroundTransparency = 1
NotifHolder.Parent = ScreenGui

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.Padding = UDim.new(0, 8)
NotifLayout.Parent = NotifHolder

Notify = function(title: string, message: string, duration: number?)
    if not State.Settings.NotificationsEnabled then return end
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 64)
    card.BackgroundColor3 = Theme.BgCard
    card.BackgroundTransparency = 0.05
    card.Parent = NotifHolder
    Corner(card, 8)
    Stroke(card, Theme.Border, 1)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 1, -12)
    bar.Position = UDim2.new(0, 6, 0, 6)
    bar.BorderSizePixel = 0
    bar.Parent = card
    BindAccent(bar, "BackgroundColor3")
    Corner(bar, 2)

    local tLbl = Instance.new("TextLabel")
    tLbl.Size = UDim2.new(1, -24, 0, 20)
    tLbl.Position = UDim2.new(0, 18, 0, 6)
    tLbl.BackgroundTransparency = 1
    tLbl.Font = Enum.Font.GothamBold
    tLbl.TextSize = 13
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.TextColor3 = Theme.TextPrimary
    tLbl.Text = title
    tLbl.Parent = card

    local mLbl = Instance.new("TextLabel")
    mLbl.Size = UDim2.new(1, -24, 0, 32)
    mLbl.Position = UDim2.new(0, 18, 0, 26)
    mLbl.BackgroundTransparency = 1
    mLbl.Font = Enum.Font.Gotham
    mLbl.TextSize = 12
    mLbl.TextWrapped = true
    mLbl.TextXAlignment = Enum.TextXAlignment.Left
    mLbl.TextYAlignment = Enum.TextYAlignment.Top
    mLbl.TextColor3 = Theme.TextSecondary
    mLbl.Text = message
    mLbl.Parent = card

    task.delay(duration or 3.5, function()
        if card and card.Parent then
            local tw = TweenService:Create(card, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
            tw:Play()
            tw.Completed:Wait()
            if card then card:Destroy() end
        end
    end)
end

-- Floating Reopen Pill (Visible when UI is minimized/closed)
local ReopenBtn = Instance.new("TextButton")
ReopenBtn.Name = "ReopenButton"
ReopenBtn.Size = UDim2.new(0, 160, 0, 36)
ReopenBtn.Position = UDim2.new(0.5, -80, 0, 14)
ReopenBtn.BackgroundColor3 = Theme.BgPrimary
ReopenBtn.Font = Enum.Font.GothamBold
ReopenBtn.TextSize = 13
ReopenBtn.TextColor3 = Theme.TextPrimary
ReopenBtn.Text = "Open LT2 Hub [RightShift]"
ReopenBtn.Visible = false
ReopenBtn.Parent = ScreenGui
Corner(ReopenBtn, 18)
Stroke(ReopenBtn, Theme.Accent, 1.5)

-- Main Window
local MainWin = Instance.new("Frame")
MainWin.Name = "MainWindow"
MainWin.Size = UDim2.new(0, 820, 0, 520)
MainWin.Position = UDim2.new(0.5, -410, 0.5, -260)
MainWin.BackgroundColor3 = Theme.BgPrimary
MainWin.BorderSizePixel = 0
MainWin.Parent = ScreenGui
Corner(MainWin, 10)
Stroke(MainWin, Theme.Border, 1)

-- Top Header Bar (Draggable)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 44)
TopBar.BackgroundColor3 = Theme.BgSecondary
TopBar.BorderSizePixel = 0
TopBar.Parent = MainWin
Corner(TopBar, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 320, 1, 0)
TitleLabel.Position = UDim2.new(0, 16, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextColor3 = Theme.TextPrimary
TitleLabel.Text = "LUMBER TYCOON 2 — ULTIMATE HUB"
TitleLabel.Parent = TopBar

local StatusBadge = Instance.new("TextLabel")
StatusBadge.Size = UDim2.new(0, 150, 0, 24)
StatusBadge.Position = UDim2.new(0, 310, 0.5, -12)
StatusBadge.BackgroundColor3 = Theme.BgCard
StatusBadge.Font = Enum.Font.GothamMedium
StatusBadge.TextSize = 11
StatusBadge.TextColor3 = Theme.TextSecondary
StatusBadge.Text = "Status: Ready"
StatusBadge.Parent = TopBar
Corner(StatusBadge, 6)
Stroke(StatusBadge, Theme.Border, 1)

local function SetStatus(text: string)
    StatusBadge.Text = "Status: " .. text
end

-- Emergency Stop Button in TopBar
local PanicBtn = Instance.new("TextButton")
PanicBtn.Size = UDim2.new(0, 110, 0, 26)
PanicBtn.Position = UDim2.new(1, -205, 0.5, -13)
PanicBtn.BackgroundColor3 = Theme.Danger
PanicBtn.Font = Enum.Font.GothamBold
PanicBtn.TextSize = 11
PanicBtn.TextColor3 = Color3.new(1, 1, 1)
PanicBtn.Text = "EMERGENCY STOP"
PanicBtn.Parent = TopBar
Corner(PanicBtn, 6)

PanicBtn.MouseButton1Click:Connect(function()
    State.Flags.EmergencyStop = true
    State.Flags.AutoBuildRunning = false
    State.Flags.AutoSawmill = false
    State.Flags.AutoCleanLogs = false
    Movement.SetFly(false)
    Movement.SetNoclip(false)
    SetStatus("EMERGENCY STOPPED")
    Notify("Emergency Stop", "All active automation loops, builds, and physics overrides halted.", 4)
end)

-- Minimize & Maximize Buttons
local IsCompact = false
local CompactBtn = Instance.new("TextButton")
CompactBtn.Size = UDim2.new(0, 32, 0, 26)
CompactBtn.Position = UDim2.new(1, -84, 0.5, -13)
CompactBtn.BackgroundColor3 = Theme.BgCard
CompactBtn.Font = Enum.Font.GothamBold
CompactBtn.TextSize = 13
CompactBtn.TextColor3 = Theme.TextPrimary
CompactBtn.Text = "□"
CompactBtn.Parent = TopBar
Corner(CompactBtn, 6)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 26)
MinBtn.Position = UDim2.new(1, -44, 0.5, -13)
MinBtn.BackgroundColor3 = Theme.BgCard
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.TextColor3 = Theme.TextPrimary
MinBtn.Text = "—"
MinBtn.Parent = TopBar
Corner(MinBtn, 6)

MinBtn.MouseButton1Click:Connect(function()
    MainWin.Visible = false
    ReopenBtn.Visible = true
end)

ReopenBtn.MouseButton1Click:Connect(function()
    MainWin.Visible = true
    ReopenBtn.Visible = false
end)

CompactBtn.MouseButton1Click:Connect(function()
    IsCompact = not IsCompact
    local targetSize = IsCompact and UDim2.new(0, 680, 0, 420) or UDim2.new(0, 820, 0, 520)
    TweenService:Create(MainWin, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Size = targetSize }):Play()
end)

-- Dragging Logic for MainWin
do
    local dragging = false
    local dragStart = Vector2.zero
    local startPos = UDim2.new()

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainWin.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainWin.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Left Sidebar Navigation
local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 175, 1, -56)
Sidebar.Position = UDim2.new(0, 8, 0, 50)
Sidebar.BackgroundColor3 = Theme.BgSecondary
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 2
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.Parent = MainWin
Corner(Sidebar, 8)
Stroke(Sidebar, Theme.Border, 1)

local SidePadding = Instance.new("UIPadding")
SidePadding.PaddingTop = UDim.new(0, 8)
SidePadding.PaddingBottom = UDim.new(0, 8)
SidePadding.PaddingLeft = UDim.new(0, 8)
SidePadding.PaddingRight = UDim.new(0, 8)
SidePadding.Parent = Sidebar

local SideLayout = Instance.new("UIListLayout")
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Padding = UDim.new(0, 6)
SideLayout.Parent = Sidebar

-- Right Content Container (With Global Filter Search Bar)
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -199, 1, -56)
ContentArea.Position = UDim2.new(0, 191, 0, 50)
ContentArea.BackgroundColor3 = Theme.BgSecondary
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainWin
Corner(ContentArea, 8)
Stroke(ContentArea, Theme.Border, 1)

local GlobalSearchBox = Instance.new("TextBox")
GlobalSearchBox.Name = "GlobalSearch"
GlobalSearchBox.Size = UDim2.new(1, -20, 0, 32)
GlobalSearchBox.Position = UDim2.new(0, 10, 0, 10)
GlobalSearchBox.BackgroundColor3 = Theme.BgInput
GlobalSearchBox.Font = Enum.Font.Gotham
GlobalSearchBox.TextSize = 12
GlobalSearchBox.TextColor3 = Theme.TextPrimary
GlobalSearchBox.PlaceholderColor3 = Theme.TextSecondary
GlobalSearchBox.PlaceholderText = "Search controls in current tab..."
GlobalSearchBox.Text = ""
GlobalSearchBox.ClearTextOnFocus = false
GlobalSearchBox.Parent = ContentArea
Corner(GlobalSearchBox, 6)
Stroke(GlobalSearchBox, Theme.Border, 1)

local PagesHolder = Instance.new("Frame")
PagesHolder.Name = "PagesHolder"
PagesHolder.Size = UDim2.new(1, -16, 1, -54)
PagesHolder.Position = UDim2.new(0, 8, 0, 48)
PagesHolder.BackgroundTransparency = 1
PagesHolder.Parent = ContentArea

--------------------------------------------------------------------------------
-- 10. UI COMPONENT BUILDER API (CARDS, TOGGLES, SLIDERS, DROPDOWNS, MULTI-SELECT)
--------------------------------------------------------------------------------
local Tabs: { [string]: { Button: TextButton, Page: ScrollingFrame } } = {}
local ActiveTabName = ""

local function FilterCurrentTab(query: string)
    local q = string.lower(query)
    local active = Tabs[ActiveTabName]
    if not active then return end
    for _, child in ipairs(active.Page:GetChildren()) do
        if child:IsA("Frame") and child:GetAttribute("FilterText") then
            local ft = string.lower(tostring(child:GetAttribute("FilterText")))
            child.Visible = (q == "" or string.find(ft, q, 1, true) ~= nil)
        end
    end
end

GlobalSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    FilterCurrentTab(GlobalSearchBox.Text)
end)

local function CreateTab(tabName: string)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Theme.BgCard
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = Theme.TextSecondary
    btn.Text = "  " .. tabName
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = Sidebar
    Corner(btn, 6)

    local page = Instance.new("ScrollingFrame")
    page.Name = tabName .. "_Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = PagesHolder

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 8)
    pad.Parent = page

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = page

    Tabs[tabName] = { Button = btn, Page = page }

    btn.MouseButton1Click:Connect(function()
        ActiveTabName = tabName
        for name, data in pairs(Tabs) do
            local isSelected = (name == tabName)
            data.Page.Visible = isSelected
            data.Button.TextColor3 = isSelected and Theme.TextPrimary or Theme.TextSecondary
            data.Button.BackgroundColor3 = isSelected and Theme.Accent or Theme.BgCard
        end
        FilterCurrentTab(GlobalSearchBox.Text)
    end)

    if ActiveTabName == "" then
        ActiveTabName = tabName
        page.Visible = true
        btn.TextColor3 = Theme.TextPrimary
        btn.BackgroundColor3 = Theme.Accent
    end

    local API = {}

    function API.Section(title: string)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 26)
        row.BackgroundTransparency = 1
        row:SetAttribute("FilterText", title)
        row.Parent = page

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = string.upper(title)
        lbl.Parent = row
        BindAccent(lbl, "TextColor3")
    end

    function API.InfoLabel(title: string, initialValue: string)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 42)
        card.BackgroundColor3 = Theme.BgCard
        card:SetAttribute("FilterText", title .. " " .. initialValue)
        card.Parent = page
        Corner(card, 6)
        Stroke(card, Theme.Border, 1)

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(0.4, -12, 1, 0)
        t.Position = UDim2.new(0, 12, 0, 0)
        t.BackgroundTransparency = 1
        t.Font = Enum.Font.GothamSemibold
        t.TextSize = 12
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextColor3 = Theme.TextPrimary
        t.Text = title
        t.Parent = card

        local v = Instance.new("TextLabel")
        v.Size = UDim2.new(0.6, -12, 1, 0)
        v.Position = UDim2.new(0.4, 0, 0, 0)
        v.BackgroundTransparency = 1
        v.Font = Enum.Font.Gotham
        v.TextSize = 12
        v.TextXAlignment = Enum.TextXAlignment.Right
        v.TextColor3 = Theme.TextSecondary
        v.Text = initialValue
        v.TextTruncate = Enum.TextTruncate.AtEnd
        v.Parent = card

        return {
            SetText = function(newVal: string)
                v.Text = newVal
            end
        }
    end

    function API.Button(title: string, desc: string, callback: () -> ())
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 46)
        card.BackgroundColor3 = Theme.BgCard
        card:SetAttribute("FilterText", title .. " " .. desc)
        card.Parent = page
        Corner(card, 6)
        Stroke(card, Theme.Border, 1)

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -130, 0, 20)
        t.Position = UDim2.new(0, 12, 0, 6)
        t.BackgroundTransparency = 1
        t.Font = Enum.Font.GothamSemibold
        t.TextSize = 13
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextColor3 = Theme.TextPrimary
        t.Text = title
        t.Parent = card

        local d = Instance.new("TextLabel")
        d.Size = UDim2.new(1, -130, 0, 16)
        d.Position = UDim2.new(0, 12, 0, 25)
        d.BackgroundTransparency = 1
        d.Font = Enum.Font.Gotham
        d.TextSize = 11
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.TextColor3 = Theme.TextSecondary
        d.Text = desc
        d.Parent = card

        local execBtn = Instance.new("TextButton")
        execBtn.Size = UDim2.new(0, 96, 0, 28)
        execBtn.Position = UDim2.new(1, -108, 0.5, -14)
        execBtn.Font = Enum.Font.GothamBold
        execBtn.TextSize = 12
        execBtn.TextColor3 = Color3.new(1, 1, 1)
        execBtn.Text = "Run"
        execBtn.Parent = card
        BindAccent(execBtn, "BackgroundColor3")
        Corner(execBtn, 6)

        execBtn.MouseButton1Click:Connect(function()
            local ok, err = pcall(callback)
            if not ok then
                LogDebug("Button error (" .. title .. "): " .. tostring(err))
                Notify("Execution Error", tostring(err), 4)
            end
        end)
    end

    function API.Toggle(title: string, desc: string, initial: boolean, callback: (state: boolean) -> ())
        local state = initial
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 46)
        card.BackgroundColor3 = Theme.BgCard
        card:SetAttribute("FilterText", title .. " " .. desc)
        card.Parent = page
        Corner(card, 6)
        Stroke(card, Theme.Border, 1)

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -90, 0, 20)
        t.Position = UDim2.new(0, 12, 0, 6)
        t.BackgroundTransparency = 1
        t.Font = Enum.Font.GothamSemibold
        t.TextSize = 13
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextColor3 = Theme.TextPrimary
        t.Text = title
        t.Parent = card

        local d = Instance.new("TextLabel")
        d.Size = UDim2.new(1, -90, 0, 16)
        d.Position = UDim2.new(0, 12, 0, 25)
        d.BackgroundTransparency = 1
        d.Font = Enum.Font.Gotham
        d.TextSize = 11
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.TextColor3 = Theme.TextSecondary
        d.Text = desc
        d.Parent = card

        local sw = Instance.new("TextButton")
        sw.Size = UDim2.new(0, 48, 0, 24)
        sw.Position = UDim2.new(1, -60, 0.5, -12)
        sw.BackgroundColor3 = state and Theme.Accent or Theme.BgInput
        sw.Text = ""
        sw.Parent = card
        Corner(sw, 12)
        Stroke(sw, Theme.Border, 1)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.Parent = sw
        Corner(knob, 9)

        local function ApplyVisual(val: boolean)
            state = val
            TweenService:Create(sw, TweenInfo.new(0.15), {
                BackgroundColor3 = state and Theme.Accent or Theme.BgInput
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.15), {
                Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            }):Play()
        end

        sw.MouseButton1Click:Connect(function()
            ApplyVisual(not state)
            pcall(callback, state)
        end)

        return {
            Set = function(val: boolean)
                ApplyVisual(val)
                pcall(callback, state)
            end
        }
    end

    function API.Slider(title: string, minVal: number, maxVal: number, defaultVal: number, callback: (val: number) -> ())
        local currentVal = math.clamp(defaultVal, minVal, maxVal)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 56)
        card.BackgroundColor3 = Theme.BgCard
        card:SetAttribute("FilterText", title)
        card.Parent = page
        Corner(card, 6)
        Stroke(card, Theme.Border, 1)

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -110, 0, 20)
        t.Position = UDim2.new(0, 12, 0, 6)
        t.BackgroundTransparency = 1
        t.Font = Enum.Font.GothamSemibold
        t.TextSize = 13
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextColor3 = Theme.TextPrimary
        t.Text = title
        t.Parent = card

        local numBox = Instance.new("TextBox")
        numBox.Size = UDim2.new(0, 68, 0, 22)
        numBox.Position = UDim2.new(1, -80, 0, 6)
        numBox.BackgroundColor3 = Theme.BgInput
        numBox.Font = Enum.Font.GothamBold
        numBox.TextSize = 12
        numBox.TextColor3 = Theme.TextPrimary
        numBox.Text = tostring(currentVal)
        numBox.Parent = card
        Corner(numBox, 4)
        Stroke(numBox, Theme.Border, 1)

        local barBg = Instance.new("TextButton")
        barBg.Size = UDim2.new(1, -24, 0, 8)
        barBg.Position = UDim2.new(0, 12, 0, 36)
        barBg.BackgroundColor3 = Theme.BgInput
        barBg.Text = ""
        barBg.AutoButtonColor = false
        barBg.Parent = card
        Corner(barBg, 4)

        local fill = Instance.new("Frame")
        local initPct = (currentVal - minVal) / math.max(1, (maxVal - minVal))
        fill.Size = UDim2.new(initPct, 0, 1, 0)
        fill.BorderSizePixel = 0
        fill.Parent = barBg
        BindAccent(fill, "BackgroundColor3")
        Corner(fill, 4)

        local function SetValue(v: number)
            currentVal = math.clamp(math.floor(v * 10) / 10, minVal, maxVal)
            local pct = (currentVal - minVal) / math.max(0.001, (maxVal - minVal))
            fill.Size = UDim2.new(pct, 0, 1, 0)
            numBox.Text = tostring(currentVal)
            pcall(callback, currentVal)
        end

        local sliding = false
        barBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = true
                local pct = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                SetValue(minVal + (maxVal - minVal) * pct)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local pct = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                SetValue(minVal + (maxVal - minVal) * pct)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = false
            end
        end)

        numBox.FocusLost:Connect(function()
            local n = tonumber(numBox.Text)
            if n then SetValue(n) else numBox.Text = tostring(currentVal) end
        end)

        return { Set = SetValue }
    end

    function API.Dropdown(title: string, options: { string }, defaultOpt: string, callback: (selected: string) -> ())
        local expanded = false
        local currentOpt = defaultOpt or options[1] or ""

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 42)
        card.BackgroundColor3 = Theme.BgCard
        card.ClipsDescendants = true
        card:SetAttribute("FilterText", title .. " " .. table.concat(options, " "))
        card.Parent = page
        Corner(card, 6)
        Stroke(card, Theme.Border, 1)

        local headerBtn = Instance.new("TextButton")
        headerBtn.Size = UDim2.new(1, 0, 0, 42)
        headerBtn.BackgroundTransparency = 1
        headerBtn.Text = ""
        headerBtn.Parent = card

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(0.45, -12, 1, 0)
        t.Position = UDim2.new(0, 12, 0, 0)
        t.BackgroundTransparency = 1
        t.Font = Enum.Font.GothamSemibold
        t.TextSize = 13
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextColor3 = Theme.TextPrimary
        t.Text = title
        t.Parent = headerBtn

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0.55, -16, 1, 0)
        valLbl.Position = UDim2.new(0.45, 0, 0, 0)
        valLbl.BackgroundTransparency = 1
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextSize = 12
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.TextColor3 = Theme.TextSecondary
        valLbl.Text = currentOpt .. "  ▼"
        valLbl.Parent = headerBtn

        local listHolder = Instance.new("ScrollingFrame")
        listHolder.Size = UDim2.new(1, -16, 0, 130)
        listHolder.Position = UDim2.new(0, 8, 0, 44)
        listHolder.BackgroundColor3 = Theme.BgInput
        listHolder.BorderSizePixel = 0
        listHolder.ScrollBarThickness = 3
        listHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
        listHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
        listHolder.Parent = card
        Corner(listHolder, 6)

        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 2)
        listLayout.Parent = listHolder

        local function RebuildOptions(newOpts: { string })
            options = newOpts
            for _, ch in ipairs(listHolder:GetChildren()) do
                if ch:IsA("TextButton") then ch:Destroy() end
            end
            for _, opt in ipairs(options) do
                local ob = Instance.new("TextButton")
                ob.Size = UDim2.new(1, -6, 0, 26)
                ob.BackgroundColor3 = (opt == currentOpt) and Theme.Accent or Theme.BgCard
                ob.Font = Enum.Font.Gotham
                ob.TextSize = 12
                ob.TextColor3 = Theme.TextPrimary
                ob.Text = "  " .. opt
                ob.TextXAlignment = Enum.TextXAlignment.Left
                ob.Parent = listHolder
                Corner(ob, 4)

                ob.MouseButton1Click:Connect(function()
                    currentOpt = opt
                    valLbl.Text = currentOpt .. "  ▼"
                    expanded = false
                    card.Size = UDim2.new(1, 0, 0, 42)
                    RebuildOptions(options)
                    pcall(callback, currentOpt)
                end)
            end
        end

        RebuildOptions(options)

        headerBtn.MouseButton1Click:Connect(function()
            expanded = not expanded
            valLbl.Text = currentOpt .. (expanded and "  ▲" or "  ▼")
            card.Size = expanded and UDim2.new(1, 0, 0, 182) or UDim2.new(1, 0, 0, 42)
        end)

        return {
            Refresh = RebuildOptions,
            Get = function() return currentOpt end
        }
    end

    function API.MultiSelect(title: string, options: { string }, selectedMap: { [string]: boolean }, callback: (map: { [string]: boolean }) -> ())
        local expanded = false
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 42)
        card.BackgroundColor3 = Theme.BgCard
        card.ClipsDescendants = true
        card:SetAttribute("FilterText", title .. " " .. table.concat(options, " "))
        card.Parent = page
        Corner(card, 6)
        Stroke(card, Theme.Border, 1)

        local headerBtn = Instance.new("TextButton")
        headerBtn.Size = UDim2.new(1, 0, 0, 42)
        headerBtn.BackgroundTransparency = 1
        headerBtn.Text = ""
        headerBtn.Parent = card

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(0.5, -12, 1, 0)
        t.Position = UDim2.new(0, 12, 0, 0)
        t.BackgroundTransparency = 1
        t.Font = Enum.Font.GothamSemibold
        t.TextSize = 13
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextColor3 = Theme.TextPrimary
        t.Text = title
        t.Parent = headerBtn

        local countLbl = Instance.new("TextLabel")
        countLbl.Size = UDim2.new(0.5, -16, 1, 0)
        countLbl.Position = UDim2.new(0.5, 0, 0, 0)
        countLbl.BackgroundTransparency = 1
        countLbl.Font = Enum.Font.GothamBold
        countLbl.TextSize = 12
        countLbl.TextXAlignment = Enum.TextXAlignment.Right
        countLbl.TextColor3 = Theme.TextSecondary
        countLbl.Parent = headerBtn

        local listHolder = Instance.new("ScrollingFrame")
        listHolder.Size = UDim2.new(1, -16, 0, 145)
        listHolder.Position = UDim2.new(0, 8, 0, 44)
        listHolder.BackgroundColor3 = Theme.BgInput
        listHolder.BorderSizePixel = 0
        listHolder.ScrollBarThickness = 3
        listHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
        listHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
        listHolder.Parent = card
        Corner(listHolder, 6)

        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 2)
        listLayout.Parent = listHolder

        local function UpdateSummary()
            local c = 0
            for _, v in pairs(selectedMap) do
                if v then c += 1 end
            end
            countLbl.Text = tostring(c) .. " Selected  " .. (expanded and "▲" or "▼")
        end

        local function RenderItems()
            for _, ch in ipairs(listHolder:GetChildren()) do
                if ch:IsA("TextButton") then ch:Destroy() end
            end
            for _, opt in ipairs(options) do
                local isSel = selectedMap[opt] == true
                local ob = Instance.new("TextButton")
                ob.Size = UDim2.new(1, -6, 0, 26)
                ob.BackgroundColor3 = isSel and Theme.Accent or Theme.BgCard
                ob.Font = Enum.Font.Gotham
                ob.TextSize = 12
                ob.TextColor3 = Theme.TextPrimary
                ob.Text = (isSel and " [✓] " or " [ ] ") .. opt
                ob.TextXAlignment = Enum.TextXAlignment.Left
                ob.Parent = listHolder
                Corner(ob, 4)

                ob.MouseButton1Click:Connect(function()
                    selectedMap[opt] = not selectedMap[opt]
                    UpdateSummary()
                    RenderItems()
                    pcall(callback, selectedMap)
                end)
            end
        end

        UpdateSummary()
        RenderItems()

        headerBtn.MouseButton1Click:Connect(function()
            expanded = not expanded
            UpdateSummary()
            card.Size = expanded and UDim2.new(1, 0, 0, 196) or UDim2.new(1, 0, 0, 42)
        end)

        return {
            SelectAll = function()
                for _, o in ipairs(options) do selectedMap[o] = true end
                UpdateSummary()
                RenderItems()
                pcall(callback, selectedMap)
            end,
            ClearAll = function()
                table.clear(selectedMap)
                UpdateSummary()
                RenderItems()
                pcall(callback, selectedMap)
            end
        }
    end

    function API.TextInput(title: string, placeholder: string, callback: (text: string) -> ())
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 44)
        card.BackgroundColor3 = Theme.BgCard
        card:SetAttribute("FilterText", title .. " " .. placeholder)
        card.Parent = page
        Corner(card, 6)
        Stroke(card, Theme.Border, 1)

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(0.45, -12, 1, 0)
        t.Position = UDim2.new(0, 12, 0, 0)
        t.BackgroundTransparency = 1
        t.Font = Enum.Font.GothamSemibold
        t.TextSize = 13
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextColor3 = Theme.TextPrimary
        t.Text = title
        t.Parent = card

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0.55, -20, 0, 28)
        box.Position = UDim2.new(0.45, 8, 0.5, -14)
        box.BackgroundColor3 = Theme.BgInput
        box.Font = Enum.Font.Gotham
        box.TextSize = 12
        box.TextColor3 = Theme.TextPrimary
        box.PlaceholderColor3 = Theme.TextSecondary
        box.PlaceholderText = placeholder
        box.Text = ""
        box.ClearTextOnFocus = false
        box.Parent = card
        Corner(box, 5)
        Stroke(box, Theme.Border, 1)

        box.FocusLost:Connect(function()
            pcall(callback, box.Text)
        end)

        return box
    end

    return API
end

--------------------------------------------------------------------------------
-- 11. POPULATING TABS WITH COMPREHENSIVE FUNCTIONALITY
--------------------------------------------------------------------------------

-- =============================================================================
-- TAB 1: PLAYER OPTIONS
-- =============================================================================
local PlayerTab = CreateTab("Player")
PlayerTab.Section("Character Telemetry")
local PosInfoLbl = PlayerTab.InfoLabel("Current Coordinates", "0, 0, 0")
local CharHealthLbl = PlayerTab.InfoLabel("Character Status", "Alive (100/100 HP)")

PlayerTab.Section("Movement & Physics")
PlayerTab.Toggle("Enable Custom WalkSpeed", "Locks WalkSpeed to your configured slider value", false, function(v)
    State.Flags.SpeedEnabled = v
    if not v then
        local _, _, hum = Engine.GetCharacter()
        if hum then hum.WalkSpeed = 16 end
    else
        Movement.UpdateStats()
    end
end)

PlayerTab.Slider("WalkSpeed Value", 16, 200, State.Settings.WalkSpeed, function(v)
    State.Settings.WalkSpeed = v
    Movement.UpdateStats()
end)

PlayerTab.Toggle("Enable Custom JumpPower", "Overrides character JumpPower", false, function(v)
    State.Flags.JumpEnabled = v
    if not v then
        local _, _, hum = Engine.GetCharacter()
        if hum then hum.JumpPower = 50 end
    else
        Movement.UpdateStats()
    end
end)

PlayerTab.Slider("JumpPower Value", 50, 300, State.Settings.JumpPower, function(v)
    State.Settings.JumpPower = v
    Movement.UpdateStats()
end)

PlayerTab.Toggle("Fly Mode (BodyVelocity + Gyro)", "Smooth 6-DOF flight using WASD + Space / LeftCtrl", false, function(v)
    Movement.SetFly(v)
end)

PlayerTab.Slider("Fly Speed", 20, 250, State.Settings.FlySpeed, function(v)
    State.Settings.FlySpeed = v
end)

PlayerTab.Toggle("Noclip (Collision Bypass)", "Disables character BasePart collisions in Stepped loop", false, function(v)
    Movement.SetNoclip(v)
end)

PlayerTab.Toggle("Walk on Water", "Enables CanCollide on Workspace.Water parts", State.Settings.WaterWalk, function(v)
    Movement.SetWaterWalk(v)
end)

PlayerTab.Section("Player Selection, Teleport & Spectate")
local function GetPlayerNamesList(): { string }
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(names, p.Name)
    end
    return names
end

local PlayerDrop = PlayerTab.Dropdown("Select Server Player", GetPlayerNamesList(), LocalPlayer.Name, function(sel)
    State.SelectedPlayerName = sel
end)

Players.PlayerAdded:Connect(function() PlayerDrop.Refresh(GetPlayerNamesList()) end)
Players.PlayerRemoving:Connect(function() PlayerDrop.Refresh(GetPlayerNamesList()) end)

PlayerTab.Button("Teleport to Selected Player", "Teleports your character to the chosen player", function()
    local target = Players:FindFirstChild(PlayerDrop.Get())
    if target and target.Character then
        local hrp = target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if hrp then
            Engine.TeleportCharacter(hrp.CFrame * CFrame.new(0, 2, 4))
            Notify("Player Teleport", "Teleported to " .. target.Name, 3)
        end
    end
end)

PlayerTab.Button("Teleport to Selected Player's Plot", "Finds the property owned by the selected player", function()
    local target = Players:FindFirstChild(PlayerDrop.Get())
    if target then
        local _, origin = Engine.GetPlayerPlot(target)
        if origin then
            Engine.TeleportCharacter(origin.CFrame)
            Notify("Plot Teleport", "Teleported to " .. target.Name .. "'s plot.", 3)
        else
            Notify("Plot Teleport", target.Name .. " does not currently own a plot.", 3)
        end
    end
end)

PlayerTab.Toggle("Spectate Selected Player", "Binds CameraSubject to the selected player's humanoid", false, function(v)
    State.Flags.Spectating = v
    local cam = Workspace.CurrentCamera
    if not cam then return end
    if v then
        local target = Players:FindFirstChild(PlayerDrop.Get())
        if target and target.Character then
            local hum = target.Character:FindFirstChildOfClass("Humanoid")
            if hum then cam.CameraSubject = hum end
        end
    else
        local _, _, myHum = Engine.GetCharacter()
        if myHum then cam.CameraSubject = myHum end
    end
end)

PlayerTab.Button("Return to Previous Position", "Teleports back to your pre-teleport coordinates", function()
    if State.ReturnPosition then
        Engine.TeleportCharacter(State.ReturnPosition)
        Notify("Returned", "Restored previous coordinates.", 3)
    else
        Notify("Return Position", "No previous teleport recorded yet.", 3)
    end
end)

PlayerTab.Button("Reset / Respawn Character", "Breaks joints to force a clean character respawn", function()
    local char = LocalPlayer.Character
    if char then char:BreakJoints() end
end)

-- =============================================================================
-- TAB 2: WORLD OPTIONS
-- =============================================================================
local WorldTab = CreateTab("World")
WorldTab.Section("World & Plot Telemetry")
local PlotInfoLbl = WorldTab.InfoLabel("My Plot Status", "Scanning...")
local WorldCountsLbl = WorldTab.InfoLabel("World Object Totals", "Scanning...")
local NearbyInfoLbl = WorldTab.InfoLabel("Nearest PlayerModel", "Scanning...")

WorldTab.Button("Refresh World Telemetry", "Scans Properties, TreeRegions, LogModels, and PlayerModels", function()
    local myPlot, origin = Engine.GetPlayerPlot(LocalPlayer)
    if myPlot and origin then
        PlotInfoLbl.SetText(string.format("Owned (%d, %d, %d)", origin.Position.X, origin.Position.Y, origin.Position.Z))
    else
        PlotInfoLbl.SetText("No Plot Claimed")
    end

    local trees = Engine.ScanLivingTrees("All")
    local logs = Engine.ScanLooseWood(nil, false)
    local items = Engine.ScanWorldItems("", false)
    WorldCountsLbl.SetText(string.format("Trees: %d | Loose Wood: %d | Items: %d", #trees, #logs, #items))

    if #items > 0 then
        NearbyInfoLbl.SetText(string.format("%s (%dm away)", items[1].ItemName, items[1].Distance))
    else
        NearbyInfoLbl.SetText("None nearby")
    end
end)

WorldTab.Section("Environment & Plot Utilities")
WorldTab.Button("Teleport to Unclaimed Plot", "Finds an empty property in Workspace.Properties", function()
    local _, origin = Engine.GetFreePlot()
    if origin then
        Engine.TeleportCharacter(origin.CFrame)
        Notify("Empty Plot Found", "Teleported to unclaimed land plot.", 3)
    else
        Notify("Plot Finder", "All 6 properties are currently owned!", 3)
    end
end)

WorldTab.Toggle("Fullbright & No Fog", "Forces daytime lighting and removes Volcano/Swamp fog", false, function(v)
    if v then
        BindConnection("Fullbright", RunService.RenderStepped:Connect(function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        end))
    else
        UnbindConnection("Fullbright")
        Lighting.GlobalShadows = true
    end
end)

-- =============================================================================
-- TAB 3: WOOD SELECTION & MANAGEMENT
-- =============================================================================
local WoodTab = CreateTab("Wood")
WoodTab.Section("Verified Wood Database & Selection")

local AllWoodNames = {}
for _, w in ipairs(Databases.WoodTypes) do
    table.insert(AllWoodNames, w.Name)
end

local SelectedWoodInfoLbl = WoodTab.InfoLabel("Wood Info", "Generic | Main Biome | Rank 1")

WoodTab.Dropdown("Inspect Wood Type", AllWoodNames, "Generic", function(sel)
    local info = Databases.WoodLookup[sel]
    if info then
        SelectedWoodInfoLbl.SetText(string.format("%s | Biome: %s | Value Rank: %d", info.Display, info.Biome, info.ValueRank))
    end
end)

local WoodMulti = WoodTab.MultiSelect("Target Wood Classes (Multi-Select)", AllWoodNames, State.Settings.SelectedWoodTypes, function(map)
    State.Settings.SelectedWoodTypes = map
end)

WoodTab.Button("Select All Wood Types", "Marks all 19 verified wood species for batch collection", function()
    WoodMulti.SelectAll()
end)

WoodTab.Button("Clear Wood Selection", "Deselects all wood species", function()
    WoodMulti.ClearAll()
end)

WoodTab.Slider("Minimum Wood Volume Filter", 0, 100, State.Settings.WoodMinVolume, function(v)
    State.Settings.WoodMinVolume = v
end)

WoodTab.Slider("Max Logs/Planks Per Batch", 1, 100, State.Settings.WoodQuantityLimit, function(v)
    State.Settings.WoodQuantityLimit = math.floor(v)
end)

WoodTab.Section("Wood Teleportation & Sawmill Processing")
WoodTab.Button("Bring Selected Loose Wood to Plot", "Teleports matching cut logs & planks to your plot origin", function()
    task.spawn(function()
        State.Flags.EmergencyStop = false
        local _, plotOrigin = Engine.GetPlayerPlot(LocalPlayer)
        local _, hrp, _ = Engine.GetCharacter()
        local destCF = plotOrigin and (plotOrigin.CFrame * CFrame.new(0, 6, 0)) or (hrp and hrp.CFrame or CFrame.new())

        local matches = Engine.ScanLooseWood(State.Settings.SelectedWoodTypes, true)
        local count = math.min(#matches, State.Settings.WoodQuantityLimit or 25)
        if count == 0 then
            Notify("Wood Manager", "No unanchored logs/planks matching selection found.", 3)
            return
        end

        SetStatus("Moving " .. count .. " wood pieces...")
        for i = 1, count do
            if State.Flags.EmergencyStop then break end
            Engine.TeleportModel(matches[i].Model, destCF * CFrame.new(0, (i - 1) * 1.5, 0), i == count)
        end
        SetStatus("Ready")
        Notify("Wood Delivered", "Teleported " .. count .. " wood pieces to destination.", 4)
    end)
end)

WoodTab.Button("Feed Selected Logs into My Sawmill", "Locates your Sawmill and feeds matching cut logs into intake", function()
    task.spawn(function()
        State.Flags.EmergencyStop = false
        local mill, intake = Engine.FindPlayerSawmill()
        if not mill or not intake then
            Notify("Sawmill Missing", "Could not find an owned Sawmill on your plot.", 4)
            return
        end

        local matches = Engine.ScanLooseWood(State.Settings.SelectedWoodTypes, true)
        local moved = 0
        for _, entry in ipairs(matches) do
            if State.Flags.EmergencyStop then break end
            if not entry.IsPlank and moved < (State.Settings.WoodQuantityLimit or 25) then
                moved += 1
                Engine.TeleportModel(entry.Model, intake.CFrame * CFrame.new(0, 2.5, 0), false)
                task.wait(0.25)
            end
        end
        Notify("Sawmill Feeder", "Fed " .. moved .. " raw logs into " .. mill.Name, 4)
    end)
end)

-- =============================================================================
-- TAB 4: TREE MANAGEMENT (BRING TREES)
-- =============================================================================
local TreeTab = CreateTab("Trees")
TreeTab.Section("Living Tree Scanner & Harvester")
local TreeStatsLbl = TreeTab.InfoLabel("Species Availability", "Click 'Scan TreeRegions' to count")

TreeTab.Dropdown("Target Tree Species", AllWoodNames, "Generic", function(sel)
    State.SelectedTreeClass = sel
    local list = Engine.ScanLivingTrees(sel)
    TreeStatsLbl.SetText(string.format("%s: %d living trees found", sel, #list))
end)

TreeTab.Button("Scan TreeRegions for Selected Species", "Counts living trees and locates the largest specimen", function()
    local list = Engine.ScanLivingTrees(State.SelectedTreeClass)
    if #list > 0 then
        TreeStatsLbl.SetText(string.format("%d found | Largest: %d sections", #list, list[1].Mass))
    else
        TreeStatsLbl.SetText("0 living trees of " .. State.SelectedTreeClass .. " currently spawned")
    end
end)

TreeTab.Button("Teleport to Largest Selected Tree", "Teleports directly to the trunk of the largest matching tree", function()
    local list = Engine.ScanLivingTrees(State.SelectedTreeClass)
    if #list == 0 then
        Notify("Tree Teleport", "No living " .. State.SelectedTreeClass .. " trees currently spawned.", 3)
        return
    end
    Engine.TeleportCharacter(list[1].Trunk.CFrame * CFrame.new(0, 3, 4))
    Notify("Tree Teleport", "Teleported to " .. State.SelectedTreeClass .. " (" .. list[1].Mass .. " sections).", 3)
end)

TreeTab.Button("Harvest & Bring Selected Tree to Plot", "Teleports to tree, triggers axe cut, and brings felled logs to plot", function()
    Engine.HarvestAndBringTree(State.SelectedTreeClass)
end)

TreeTab.Button("Recall All Newly Cut Logs to Plot", "Pulls all unanchored logs in Workspace.LogModels to your plot", function()
    task.spawn(function()
        local _, origin = Engine.GetPlayerPlot(LocalPlayer)
        local _, hrp, _ = Engine.GetCharacter()
        local dest = origin and (origin.CFrame * CFrame.new(0, 6, 0)) or (hrp and hrp.CFrame or CFrame.new())
        local logs = Engine.ScanLooseWood(nil, true)
        local c = 0
        for _, entry in ipairs(logs) do
            if not entry.IsPlank and c < 30 then
                c += 1
                Engine.TeleportModel(entry.Model, dest * CFrame.new(0, c * 1.5, 0), false)
            end
        end
        Notify("Recall Logs", "Brought " .. c .. " cut logs to plot.", 3)
    end)
end)

-- =============================================================================
-- TAB 5: ITEM SELECTION & TELEPORTATION
-- =============================================================================
local ItemTab = CreateTab("Items")
ItemTab.Section("World Item Scanner & Group Selector")

local ItemSearchFilter = ""
local OwnedItemsOnly = true
local ScannedItemsCache = {}
local ItemStatusLbl = ItemTab.InfoLabel("Selected Items", "0 items queued")

ItemTab.TextInput("Filter Items by Name", "e.g., Axe, Sawmill, Wire, Truck...", function(txt)
    ItemSearchFilter = txt
end)

ItemTab.Toggle("My Owned Items Only", "Filters out items belonging to other players", true, function(v)
    OwnedItemsOnly = v
end)

local ItemMultiSelector = ItemTab.MultiSelect("Scanned World Items", { "Click 'Refresh Item Scan' first" }, {}, function(map)
    table.clear(State.SelectedItemInstances)
    local count = 0
    for label, isSel in pairs(map) do
        if isSel and ScannedItemsCache[label] then
            State.SelectedItemInstances[ScannedItemsCache[label]] = true
            count += 1
        end
    end
    ItemStatusLbl.SetText(tostring(count) .. " item model(s) selected")
end)

ItemTab.Button("Refresh Item Scan", "Populates the item selector from Workspace.PlayerModels", function()
    local found = Engine.ScanWorldItems(ItemSearchFilter, OwnedItemsOnly)
    table.clear(ScannedItemsCache)
    local labels = {}
    for i, entry in ipairs(found) do
        if i <= 60 then
            local lbl = string.format("#%d %s (%dm)", i, entry.ItemName, entry.Distance)
            ScannedItemsCache[lbl] = entry.Model
            table.insert(labels, lbl)
        end
    end
    Notify("Item Scanner", "Found " .. #found .. " matching unanchored item(s).", 3)
end)

ItemTab.Button("Teleport Matching Items to My Plot", "Moves all items matching your search filter to your plot", function()
    task.spawn(function()
        State.Flags.EmergencyStop = false
        local found = Engine.ScanWorldItems(ItemSearchFilter, OwnedItemsOnly)
        local _, origin = Engine.GetPlayerPlot(LocalPlayer)
        local _, hrp, _ = Engine.GetCharacter()
        local dest = origin and (origin.CFrame * CFrame.new(0, 5, 0)) or (hrp and hrp.CFrame or CFrame.new())

        local limit = math.min(#found, 25)
        for i = 1, limit do
            if State.Flags.EmergencyStop then break end
            Engine.TeleportModel(found[i].Model, dest * CFrame.new((i % 5) * 3, 2, math.floor(i / 5) * 3), i == limit)
        end
        Notify("Items Teleported", "Moved " .. limit .. " item(s) to destination.", 4)
    end)
end)

ItemTab.Button("Teleport Matching Items to Character", "Brings matching items directly in front of you", function()
    task.spawn(function()
        local found = Engine.ScanWorldItems(ItemSearchFilter, OwnedItemsOnly)
        local _, hrp, _ = Engine.GetCharacter()
        if not hrp then return end
        local dest = hrp.CFrame * CFrame.new(0, 3, -6)
        local limit = math.min(#found, 15)
        for i = 1, limit do
            if State.Flags.EmergencyStop then break end
            Engine.TeleportModel(found[i].Model, dest * CFrame.new(0, (i - 1) * 1.5, 0), i == limit)
        end
        Notify("Items Brought", "Brought " .. limit .. " item(s) to character.", 3)
    end)
end)

-- =============================================================================
-- TAB 6: AUTO BUILD SYSTEM (MULTI-MATERIAL)
-- =============================================================================
local BuildTab = CreateTab("Auto Build")
BuildTab.Section("Blueprint Preset & Multi-Material Assignment")

local PresetNames = {}
for k, _ in pairs(Databases.AutoBuildPresets) do
    table.insert(PresetNames, k)
end
table.sort(PresetNames)

local BuildProgressLbl = BuildTab.InfoLabel("Build Progress", "Idle (0%)")

BuildTab.Dropdown("Select Structure Preset", PresetNames, State.SelectedBlueprintPreset, function(sel)
    State.SelectedBlueprintPreset = sel
    local p = Databases.AutoBuildPresets[sel]
    if p then
        BuildProgressLbl.SetText(p.Description)
    end
end)

BuildTab.Dropdown("Floor Section Wood Material", AllWoodNames, State.Settings.AutoBuildMaterials.Floor, function(sel)
    State.Settings.AutoBuildMaterials.Floor = sel
end)

BuildTab.Dropdown("Walls Section Wood Material", AllWoodNames, State.Settings.AutoBuildMaterials.Walls, function(sel)
    State.Settings.AutoBuildMaterials.Walls = sel
end)

BuildTab.Dropdown("Roof Section Wood Material", AllWoodNames, State.Settings.AutoBuildMaterials.Roof, function(sel)
    State.Settings.AutoBuildMaterials.Roof = sel
end)

BuildTab.Dropdown("Trim / Pillars Wood Material", AllWoodNames, State.Settings.AutoBuildMaterials.Trim, function(sel)
    State.Settings.AutoBuildMaterials.Trim = sel
end)

BuildTab.Slider("Structure Rotation (Degrees)", 0, 360, State.Settings.AutoBuildRotation, function(v)
    State.Settings.AutoBuildRotation = v
end)

BuildTab.Section("Hologram Preview & Execution Controls")
BuildTab.Button("Toggle Hologram Build Preview", "Renders color-coded neon preview blocks on your plot", function()
    if State.PreviewFolder then
        AutoBuilder.ClearPreview()
        Notify("Preview Cleared", "Removed hologram preview.", 2)
    else
        AutoBuilder.RenderPreview(State.SelectedBlueprintPreset)
    end
end)

BuildTab.Button("Start Multi-Material Auto Build", "Executes structure assembly using assigned wood per section", function()
    AutoBuilder.ExecuteBuild(State.SelectedBlueprintPreset, function(statusTxt, _)
        BuildProgressLbl.SetText(statusTxt)
        SetStatus(statusTxt)
    end)
end)

BuildTab.Toggle("Pause Active Auto Build", "Temporarily suspends the Auto Build loop", false, function(v)
    State.Flags.AutoBuildPaused = v
end)

BuildTab.Button("Cancel Active Build", "Stops the current build loop immediately", function()
    State.Flags.AutoBuildRunning = false
    SetStatus("Ready")
end)

BuildTab.Button("Undo / Rollback Last Build", "Returns all moved blueprints and wood planks to prior CFrames", function()
    AutoBuilder.RollbackLastBuild()
end)

-- =============================================================================
-- TAB 7: TELEPORTATION SYSTEM
-- =============================================================================
local TeleTab = CreateTab("Teleports")
TeleTab.Section("Verified Shops & Biome Destinations")

local LocationNames = {}
for k, _ in pairs(Databases.Locations) do
    table.insert(LocationNames, k)
end
table.sort(LocationNames)

local SelectedDest = LocationNames[1]
TeleTab.Dropdown("Select World Destination", LocationNames, SelectedDest, function(sel)
    SelectedDest = sel
end)

TeleTab.Button("Teleport to Selected Destination", "Instantly moves your character (or seated vehicle) to destination", function()
    local cf = Databases.Locations[SelectedDest]
    if cf then
        Engine.TeleportCharacter(cf)
        Notify("Teleported", "Arrived at " .. SelectedDest, 3)
    end
end)

TeleTab.Button("Teleport to My Plot", "Teleports directly to your claimed OriginSquare", function()
    local _, origin = Engine.GetPlayerPlot(LocalPlayer)
    if origin then
        Engine.TeleportCharacter(origin.CFrame)
        Notify("Teleported", "Returned to your plot.", 3)
    else
        Notify("Plot Teleport", "You do not own a plot yet! Teleporting to Land Store.", 3)
        Engine.TeleportCharacter(Databases.Locations["Land Store"])
    end
end)

TeleTab.Section("Custom Waypoints & Coordinate Input")
local CustomCoordString = "155, 5, 74"
TeleTab.TextInput("Custom X, Y, Z Coordinates", "e.g., 265, 5, 57", function(txt)
    CustomCoordString = txt
end)

TeleTab.Button("Teleport to Custom Coordinates", "Parses X, Y, Z and teleports character", function()
    local parts = string.split(CustomCoordString, ",")
    if #parts >= 3 then
        local x, y, z = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3])
        if x and y and z then
            Engine.TeleportCharacter(CFrame.new(x, y, z))
            Notify("Custom Teleport", string.format("Teleported to %.1f, %.1f, %.1f", x, y, z), 3)
        end
    end
end)

local WaypointNameInput = "MySavedSpot"
TeleTab.TextInput("New Waypoint Name", "Enter name to save current position", function(txt)
    WaypointNameInput = txt
end)

TeleTab.Button("Save Current Position as Waypoint", "Stores your character's current CFrame into SavedLocations", function()
    local _, hrp, _ = Engine.GetCharacter()
    if hrp and WaypointNameInput ~= "" then
        State.Settings.SavedLocations[WaypointNameInput] = {
            X = hrp.Position.X,
            Y = hrp.Position.Y,
            Z = hrp.Position.Z
        }
        Databases.Locations["[Saved] " .. WaypointNameInput] = CFrame.new(hrp.Position)
        SaveConfiguration()
        Notify("Waypoint Saved", "Saved '" .. WaypointNameInput .. "' to configuration.", 3)
    end
end)

-- =============================================================================
-- TAB 8: AUTOMATION FEATURES
-- =============================================================================
local AutoTab = CreateTab("Automation")
AutoTab.Section("Automated Wood Processing & Base Management")

AutoTab.Toggle("Continuous Auto-Sawmill Feeder", "Automatically pulls nearby cut logs into your plot's Sawmill", false, function(v)
    State.Flags.AutoSawmill = v
    if v then
        task.spawn(function()
            while State.Flags.AutoSawmill and not State.Flags.EmergencyStop do
                local mill, intake = Engine.FindPlayerSawmill()
                if mill and intake then
                    local logs = Engine.ScanLooseWood(State.Settings.SelectedWoodTypes, true)
                    for _, entry in ipairs(logs) do
                        if not State.Flags.AutoSawmill or State.Flags.EmergencyStop then break end
                        if not entry.IsPlank then
                            Engine.TeleportModel(entry.Model, intake.CFrame * CFrame.new(0, 2.5, 0), false)
                            task.wait(0.8)
                        end
                    end
                end
                task.wait(2)
            end
        end)
    end
end)

AutoTab.Button("Auto-Stack & Sort All Planks on Plot", "Neatly stacks milled planks by Wood Class onto your plot origin", function()
    task.spawn(function()
        State.Flags.EmergencyStop = false
        local _, origin = Engine.GetPlayerPlot(LocalPlayer)
        if not origin then
            Notify("Auto-Sort", "Claim a plot first before sorting planks.", 3)
            return
        end
        local planks = Engine.ScanLooseWood(nil, true)
        local byClass: { [string]: { Model } } = {}
        for _, entry in ipairs(planks) do
            if entry.IsPlank then
                byClass[entry.TreeClass] = byClass[entry.TreeClass] or {}
                table.insert(byClass[entry.TreeClass], entry.Model)
            end
        end

        local colIndex = 0
        local totalSorted = 0
        for _, list in pairs(byClass) do
            colIndex += 1
            for row, model in ipairs(list) do
                if State.Flags.EmergencyStop then break end
                local targetCF = origin.CFrame * CFrame.new(-16 + (colIndex * 4), 1.5 + (row * 1.1), -12)
                Engine.TeleportModel(model, targetCF, false)
                totalSorted += 1
            end
        end
        Notify("Plank Sorter", "Organized " .. totalSorted .. " planks by species on your plot.", 4)
    end)
end)

-- =============================================================================
-- TAB 9: QUALITY OF LIFE & SETTINGS
-- =============================================================================
local SettingsTab = CreateTab("Settings")
SettingsTab.Section("Interface Customization & Scaling")

SettingsTab.Slider("Interface Scale (UIScale)", 0.7, 1.4, State.Settings.UIScale, function(v)
    State.Settings.UIScale = v
    UIScaleObj.Scale = v
end)

local AccentPresets = {
    ["Emerald Green"] = Color3.fromRGB(16, 185, 129),
    ["Cyber Blue"] = Color3.fromRGB(59, 130, 246),
    ["Crimson Red"] = Color3.fromRGB(239, 68, 68),
    ["Royal Purple"] = Color3.fromRGB(139, 92, 246),
    ["Sunset Amber"] = Color3.fromRGB(245, 158, 11),
}

SettingsTab.Dropdown("Theme Accent Color", { "Emerald Green", "Cyber Blue", "Crimson Red", "Royal Purple", "Sunset Amber" }, "Emerald Green", function(sel)
    local c = AccentPresets[sel]
    if c then SetAccentColor(c) end
end)

SettingsTab.Toggle("Enable Toast Notifications", "Shows status notifications in the bottom-right corner", State.Settings.NotificationsEnabled, function(v)
    State.Settings.NotificationsEnabled = v
end)

SettingsTab.Toggle("Enable Debug Logging (F9 Console)", "Outputs diagnostic warnings to the developer console", State.Settings.DebugMode, function(v)
    State.Settings.DebugMode = v
end)

SettingsTab.Section("Configuration Persistence & Lifecycle")
SettingsTab.Button("Save Configuration to Disk", "Writes current settings to LT2_UltimateHub/config_v4.json", function()
    SaveConfiguration()
end)

SettingsTab.Button("Reload Configuration from Disk", "Loads saved configuration from executor workspace", function()
    if LoadConfiguration() then
        UIScaleObj.Scale = State.Settings.UIScale or 1.0
        Notify("Configuration Loaded", "Restored saved settings from disk.", 3)
    else
        Notify("Load Failed", "No saved configuration file found.", 3)
    end
end)

SettingsTab.Button("Reset Settings to Default", "Restores all sliders, colors, and flags to factory defaults", function()
    State.Settings = table.clone(DefaultSettings)
    UIScaleObj.Scale = 1.0
    SetAccentColor(Color3.fromRGB(16, 185, 129))
    Notify("Reset Complete", "Restored default settings.", 3)
end)

SettingsTab.Button("Unload & Clean Up Script Hub", "Disconnects all loops, removes previews, and destroys GUI", function()
    State.Flags.EmergencyStop = true
    Movement.SetFly(false)
    Movement.SetNoclip(false)
    AutoBuilder.ClearPreview()
    CleanupAllConnections()
    ScreenGui:Destroy()
end)

--------------------------------------------------------------------------------
-- 12. BACKGROUND TELEMETRY, HOTKEYS & CHARACTER RESPAWN HANDLER
--------------------------------------------------------------------------------
BindConnection("Keybinds", UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        MainWin.Visible = not MainWin.Visible
        ReopenBtn.Visible = not MainWin.Visible
    elseif input.KeyCode == Enum.KeyCode.End then
        -- Panic Hotkey (End)
        State.Flags.EmergencyStop = true
        State.Flags.AutoBuildRunning = false
        State.Flags.AutoSawmill = false
        Movement.SetFly(false)
        Movement.SetNoclip(false)
        SetStatus("EMERGENCY STOPPED")
        Notify("Hotkey Panic [END]", "All active tasks halted immediately.", 3)
    end
end))

BindConnection("CharRespawn", LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)
    Movement.UpdateStats()
    if State.Flags.FlyEnabled then
        Movement.SetFly(true)
    end
end))

BindConnection("TelemetryHeartbeat", RunService.Heartbeat:Connect(function()
    local _, hrp, hum = Engine.GetCharacter()
    if hrp then
        PosInfoLbl.SetText(string.format("%.1f, %.1f, %.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z))
    end
    if hum then
        CharHealthLbl.SetText(string.format("HP: %d / %d", math.floor(hum.Health), math.floor(hum.MaxHealth)))
        if State.Flags.SpeedEnabled and hum.WalkSpeed ~= State.Settings.WalkSpeed then
            hum.WalkSpeed = State.Settings.WalkSpeed
        end
    end
end))

Notify("LT2 Ultimate Hub Ready", "Loaded 9 tabs. Press [RightShift] to toggle UI or [End] for Emergency Stop.", 5)
