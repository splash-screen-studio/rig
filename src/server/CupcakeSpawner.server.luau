--[[
    CupcakeSpawner v1.0.0
    Spawns cupcakes on the terrain surface for players to collect.

    Uses TerrainConfig as SINGLE SOURCE OF TRUTH for:
    - World bounds (where to spawn)
    - Elevation range (for raycast parameters)

    Uses raycast to find ACTUAL terrain surface (same as CamelFollowPlayer).
    All spawn parameters calculated from terrain config - no magic numbers.

    Synced via Rojo to ServerScriptService.
]]

local VERSION = "1.0.2"
print("[CupcakeSpawner v" .. VERSION .. "] Script starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for TerrainConfig module (SINGLE SOURCE OF TRUTH for terrain)
local TerrainConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TerrainConfig"))
print("[CupcakeSpawner v" .. VERSION .. "] TerrainConfig v" .. TerrainConfig.VERSION .. " loaded")

-- ============================================
-- SPAWN CONFIGURATION (derived from TerrainConfig)
-- ============================================

-- Spawn cupcakes in a region near world center (reachable from spawn)
-- Using fractions of world size - no magic numbers
local SPAWN_REGION_FRACTION = 0.6  -- Spawn within 60% of world from center
local SPAWN_RADIUS = TerrainConfig.WORLD_HALF_SIZE * SPAWN_REGION_FRACTION

-- Exact number of cupcakes to spawn
local NUM_CUPCAKES = 22

-- Height above terrain surface (0 = sitting directly on ground)
local SURFACE_OFFSET = 0

print("[CupcakeSpawner v" .. VERSION .. "] Configuration:")
print("  Spawn radius: " .. string.format("%.1f", SPAWN_RADIUS) .. " studs")
print("  Number of cupcakes: " .. NUM_CUPCAKES)
print("  Surface offset: " .. SURFACE_OFFSET)

-- ============================================
-- TERRAIN RAYCAST (same as CamelFollowPlayer)
-- ============================================

local function getTerrainHeight(x, z)
    -- Raycast from above max terrain down to find surface
    -- This is the SINGLE SOURCE OF TRUTH for actual terrain height
    local rayOrigin = Vector3.new(x, TerrainConfig.MAX_ELEVATION + 50, z)
    local rayDirection = Vector3.new(0, -(TerrainConfig.ELEVATION_RANGE + 100), 0)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = {workspace.Terrain}

    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if result then
        return result.Position.Y
    else
        -- Fallback to mathematical function if raycast fails
        return TerrainConfig.getElevation(x, z)
    end
end

-- ============================================
-- CUPCAKE CREATION
-- ============================================

local function createCupcake()
    local cupcake = Instance.new("Model")
    cupcake.Name = "Cupcake"

    -- Scale factor (studs) - cupcake should be player-reachable size
    local SCALE = 2

    -- ROOT (invisible, at base for proper positioning)
    local root = Instance.new("Part")
    root.Name = "Root"
    root.Size = Vector3.new(0.1, 0.1, 0.1)
    root.Position = Vector3.new(0, 0, 0)
    root.Transparency = 1
    root.Anchored = true
    root.CanCollide = false
    root.Parent = cupcake

    -- WRAPPER (light pink)
    local wrapper = Instance.new("Part")
    wrapper.Name = "Wrapper"
    wrapper.Shape = Enum.PartType.Cylinder
    wrapper.Size = Vector3.new(SCALE * 0.6, SCALE * 1.2, SCALE * 1.2)
    wrapper.CFrame = CFrame.new(0, SCALE * 0.3, 0) * CFrame.Angles(0, 0, math.rad(90))
    wrapper.Color = Color3.fromRGB(255, 182, 193)
    wrapper.Material = Enum.Material.SmoothPlastic
    wrapper.Anchored = true
    wrapper.CanCollide = true
    wrapper.Parent = cupcake

    -- CAKE (golden brown)
    local cake = Instance.new("Part")
    cake.Name = "Cake"
    cake.Shape = Enum.PartType.Cylinder
    cake.Size = Vector3.new(SCALE * 0.4, SCALE * 1.0, SCALE * 1.0)
    cake.CFrame = CFrame.new(0, SCALE * 0.7, 0) * CFrame.Angles(0, 0, math.rad(90))
    cake.Color = Color3.fromRGB(222, 184, 135)
    cake.Material = Enum.Material.Sand
    cake.Anchored = true
    cake.CanCollide = true
    cake.Parent = cupcake

    -- FROSTING (hot pink dome)
    local frosting = Instance.new("Part")
    frosting.Name = "Frosting"
    frosting.Shape = Enum.PartType.Ball
    frosting.Size = Vector3.new(SCALE * 1.1, SCALE * 1.1, SCALE * 1.1)
    frosting.Position = Vector3.new(0, SCALE * 1.2, 0)
    frosting.Color = Color3.fromRGB(255, 105, 180)
    frosting.Material = Enum.Material.SmoothPlastic
    frosting.Anchored = true
    frosting.CanCollide = true
    frosting.Parent = cupcake

    -- CHERRY (crimson red, shiny)
    local cherry = Instance.new("Part")
    cherry.Name = "Cherry"
    cherry.Shape = Enum.PartType.Ball
    cherry.Size = Vector3.new(SCALE * 0.35, SCALE * 0.35, SCALE * 0.35)
    cherry.Position = Vector3.new(0, SCALE * 1.85, 0)
    cherry.Color = Color3.fromRGB(220, 20, 60)
    cherry.Material = Enum.Material.Glass
    cherry.Anchored = true
    cherry.CanCollide = true
    cherry.Parent = cupcake

    -- STEM (forest green)
    local stem = Instance.new("Part")
    stem.Name = "Stem"
    stem.Shape = Enum.PartType.Cylinder
    stem.Size = Vector3.new(SCALE * 0.3, SCALE * 0.06, SCALE * 0.06)
    stem.CFrame = CFrame.new(0, SCALE * 2.1, 0) * CFrame.Angles(0, 0, math.rad(90))
    stem.Color = Color3.fromRGB(34, 139, 34)
    stem.Material = Enum.Material.SmoothPlastic
    stem.Anchored = true
    stem.CanCollide = false
    stem.Parent = cupcake

    -- SPRINKLES (rainbow colors, neon)
    local sprinkleColors = {
        Color3.fromRGB(255, 255, 0),   -- Yellow
        Color3.fromRGB(0, 255, 255),   -- Cyan
        Color3.fromRGB(255, 0, 255),   -- Magenta
        Color3.fromRGB(255, 165, 0),   -- Orange
        Color3.fromRGB(50, 205, 50),   -- Lime green
        Color3.fromRGB(138, 43, 226),  -- Blue violet
    }

    for i = 1, 8 do
        local sprinkle = Instance.new("Part")
        sprinkle.Name = "Sprinkle_" .. i
        sprinkle.Size = Vector3.new(SCALE * 0.08, SCALE * 0.08, SCALE * 0.2)

        local angle = (i / 8) * math.pi * 2
        local radius = SCALE * 0.4
        local height = SCALE * 1.3 + math.random() * SCALE * 0.2
        sprinkle.Position = Vector3.new(
            math.cos(angle) * radius,
            height,
            math.sin(angle) * radius
        )
        sprinkle.Rotation = Vector3.new(
            math.random() * 360,
            math.random() * 360,
            math.random() * 360
        )
        sprinkle.Color = sprinkleColors[(i % #sprinkleColors) + 1]
        sprinkle.Material = Enum.Material.Neon
        sprinkle.Anchored = true
        sprinkle.CanCollide = false
        sprinkle.Parent = cupcake
    end

    cupcake.PrimaryPart = root
    return cupcake
end

-- ============================================
-- SPAWN CUPCAKES ON TERRAIN
-- ============================================

-- Create container for cupcakes
local cupcakesFolder = Instance.new("Folder")
cupcakesFolder.Name = "Cupcakes"
cupcakesFolder.Parent = workspace

-- Remove template if it exists from earlier MCP testing
local template = workspace:FindFirstChild("CupcakeTemplate")
if template then
    template:Destroy()
    print("[CupcakeSpawner v" .. VERSION .. "] Removed template cupcake")
end

print("[CupcakeSpawner v" .. VERSION .. "] Spawning " .. NUM_CUPCAKES .. " cupcakes...")

local spawned = 0
local attempts = 0
local maxAttempts = NUM_CUPCAKES * 3  -- Allow some failed attempts

while spawned < NUM_CUPCAKES and attempts < maxAttempts do
    attempts = attempts + 1

    -- Random position within spawn radius (circular distribution)
    local angle = math.random() * math.pi * 2
    local distance = math.sqrt(math.random()) * SPAWN_RADIUS  -- sqrt for uniform distribution
    local x = math.cos(angle) * distance
    local z = math.sin(angle) * distance

    -- Get terrain height at this position
    local terrainY = getTerrainHeight(x, z)

    -- Only spawn if terrain exists (raycast succeeded)
    if terrainY > TerrainConfig.BASE_ELEVATION - 10 then
        local cupcake = createCupcake()

        -- Position cupcake on terrain surface
        -- The cupcake's wrapper base is at Y=0 in local space
        -- So we position at terrain height + offset
        local groundY = terrainY + SURFACE_OFFSET
        cupcake:SetPrimaryPartCFrame(CFrame.new(x, groundY, z))

        cupcake.Name = "Cupcake_" .. spawned + 1
        cupcake.Parent = cupcakesFolder

        spawned = spawned + 1
    end
end

print("[CupcakeSpawner v" .. VERSION .. "] Spawning complete!")
print("  Cupcakes spawned: " .. spawned)
print("  Attempts: " .. attempts)
print("  Location: workspace.Cupcakes")

-- Log some sample positions for verification
local children = cupcakesFolder:GetChildren()
if #children > 0 then
    print("[CupcakeSpawner v" .. VERSION .. "] Sample positions:")
    for i = 1, math.min(3, #children) do
        local c = children[i]
        if c.PrimaryPart then
            local pos = c.PrimaryPart.Position
            print("  " .. c.Name .. ": (" .. string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z) .. ")")
        end
    end
end
