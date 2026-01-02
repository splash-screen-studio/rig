--[[
    CamelFollowPlayer v1.4.0
    Makes the baby camel follow the player, positioned ahead and to the left.
    Uses direct CFrame positioning (no physics - more stable).
    All dimensions calculated from actual camel geometry.
    Includes leg walking animation.
    Synced via Rojo to ServerScriptService.

    v1.3.1: Added facing direction debug logging
    v1.3.2: FIX - Camel now faces player's direction, not its own movement direction
            (Bug: movement towards offset target made camel face towards player)
    v1.3.3: FIX - Account for camel's local forward direction from geometry
            Camel's head is at +X (not -Z), calculate rotation offset from head position
            Fixed partCount logging (# doesn't work on dictionaries)
    v1.3.4: FIX - Flipped rotation sign (was 180° backwards)
    v1.3.5: Increased offset multipliers (ahead: 1.5→2.5, left: 0.8→1.2)
    v1.4.0: Dynamic terrain elevation - camel walks on undulating terrain
            Uses TerrainConfig.getElevation(x, z) as single source of truth
    v1.4.1: FIX - Set Y directly from terrain, don't lerp it
            Lerping Y caused camel to sink underground on elevation changes
    v1.4.2: FIX - Use raycast to find ACTUAL terrain surface
            Math function doesn't match voxel grid exactly, raycast is single source of truth
]]

local VERSION = "1.4.2"
print("[CamelFollowPlayer v" .. VERSION .. "] Script starting...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for TerrainConfig module (for reference elevation range)
local TerrainConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TerrainConfig"))
print("[CamelFollowPlayer v" .. VERSION .. "] TerrainConfig v" .. TerrainConfig.VERSION .. " loaded")

-- v1.4.2: Raycast to find ACTUAL terrain surface (single source of truth)
-- The mathematical getElevation() doesn't match voxel grid exactly
local function getActualTerrainHeight(x, z)
    local rayOrigin = Vector3.new(x, TerrainConfig.MAX_ELEVATION + 50, z)  -- Start above max terrain
    local rayDirection = Vector3.new(0, -(TerrainConfig.ELEVATION_RANGE + 100), 0)  -- Ray down

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

-- Wait for camel
local camel = workspace:WaitForChild("BabyCamel", 10)
if not camel then
    warn("[CamelFollowPlayer] BabyCamel not found!")
    return
end

local body = camel:WaitForChild("Body", 5)
if not body then
    warn("[CamelFollowPlayer] Body not found!")
    return
end

-- ============================================
-- SINGLE SOURCE OF TRUTH: Calculate from camel geometry
-- ============================================

-- Find the lowest point of the camel (hooves)
local lowestY = math.huge
local highestY = -math.huge
for _, part in ipairs(camel:GetChildren()) do
    if part:IsA("BasePart") then
        local bottomY = part.Position.Y - (part.Size.Y / 2)
        local topY = part.Position.Y + (part.Size.Y / 2)
        lowestY = math.min(lowestY, bottomY)
        highestY = math.max(highestY, topY)
    end
end

local camelHeight = highestY - lowestY
local bodyToGround = body.Position.Y - lowestY  -- Distance from body center to ground

-- Determine camel's forward direction from geometry (head relative to body)
-- This is the SINGLE SOURCE OF TRUTH for which way the camel faces
local head = camel:FindFirstChild("Head")
local camelForwardLocal = Vector3.new(1, 0, 0)  -- Default: +X is forward
if head then
    local headOffset = head.Position - body.Position
    local headOffsetFlat = Vector3.new(headOffset.X, 0, headOffset.Z)
    if headOffsetFlat.Magnitude > 0.1 then
        camelForwardLocal = headOffsetFlat.Unit
    end
end

print("[CamelFollowPlayer v" .. VERSION .. "] Camel geometry:")
print("  Total height: " .. string.format("%.2f", camelHeight) .. " studs")
print("  Body to ground: " .. string.format("%.2f", bodyToGround) .. " studs")
print("  Body size: " .. tostring(body.Size))
print("  Camel forward (local): " .. string.format("(%.2f, %.2f, %.2f)", camelForwardLocal.X, camelForwardLocal.Y, camelForwardLocal.Z))
if head then
    print("  Head offset from body: " .. tostring(head.Position - body.Position))
end

-- Configuration - based on camel size (single source of truth)
local OFFSET_FORWARD = camelHeight * 2.5   -- Ahead by 2.5x camel height (v1.3.5: was 1.5)
local OFFSET_LEFT = camelHeight * 1.2      -- Left by 1.2x camel height (v1.3.5: was 0.8)
local GROUND_CLEARANCE = 0.1               -- Small gap above ground
-- v1.4.0: Ground height now computed dynamically from TerrainConfig.getElevation()
-- Formula: terrainY + bodyToGround + GROUND_CLEARANCE
local LERP_SPEED = 0.1                     -- Smoothing factor
local BOB_HEIGHT = camelHeight * 0.03      -- Bob 3% of height
local BOB_SPEED = 8                        -- Cycles per second

print("[CamelFollowPlayer v" .. VERSION .. "] Calculated offsets:")
print("  Forward: " .. string.format("%.2f", OFFSET_FORWARD))
print("  Left: " .. string.format("%.2f", OFFSET_LEFT))
print("  Body to ground: " .. string.format("%.2f", bodyToGround))
print("  Ground clearance: " .. string.format("%.2f", GROUND_CLEARANCE))
print("  Terrain elevation: DYNAMIC (from TerrainConfig)")

-- Keep everything anchored (no physics!)
body.Anchored = true

-- Calculate part offsets relative to body
local partOffsets = {}
local bodyPos = body.Position
for _, part in ipairs(camel:GetChildren()) do
    if part:IsA("BasePart") and part ~= body then
        partOffsets[part] = part.Position - bodyPos
        part.Anchored = true  -- Anchor all parts
        part.CanCollide = false  -- No collisions
    end
end
body.CanCollide = false  -- Body doesn't collide either

-- Count parts properly (# doesn't work on dictionaries)
local partCount = 0
for _ in pairs(partOffsets) do partCount = partCount + 1 end
print("[CamelFollowPlayer v" .. VERSION .. "] Tracking " .. partCount .. " parts (all anchored, no physics)")

-- Identify leg parts for animation
local legs = {
    frontLeft = { upper = camel:FindFirstChild("Leg1"), lower = camel:FindFirstChild("Hoof1") },
    frontRight = { upper = camel:FindFirstChild("Leg2"), lower = camel:FindFirstChild("Hoof2") },
    backLeft = { upper = camel:FindFirstChild("Leg3"), lower = camel:FindFirstChild("Hoof3") },
    backRight = { upper = camel:FindFirstChild("Leg4"), lower = camel:FindFirstChild("Hoof4") },
}

-- Leg animation parameters (calculated from body size)
local LEG_SWING_ANGLE = math.rad(20)  -- Max swing angle in radians
local LEG_SWING_SPEED = 10            -- Cycles per second

-- Current state for lerping
local currentPos = body.Position
local currentLookVector = Vector3.new(1, 0, 0)
local previousPos = currentPos

-- Track time and movement
local elapsed = 0
local totalDistance = 0
local debugLogInterval = 2  -- Log every 2 seconds
local lastDebugLog = 0

-- Main follow loop
local connection
connection = RunService.Heartbeat:Connect(function(dt)
    elapsed = elapsed + dt

    -- Find the first player's character
    local player = Players:GetPlayers()[1]
    if not player then return end

    local character = player.Character
    if not character then return end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- Get player's position and look direction
    local playerCFrame = humanoidRootPart.CFrame
    local playerPos = playerCFrame.Position
    local lookVector = playerCFrame.LookVector
    local rightVector = playerCFrame.RightVector

    -- Calculate target position: ahead and to the left of player
    local targetPos = playerPos
        + (lookVector * OFFSET_FORWARD)  -- ahead
        - (rightVector * OFFSET_LEFT)     -- to the left

    -- Smooth lerp X and Z only (horizontal movement)
    local newXZ = Vector2.new(currentPos.X, currentPos.Z):Lerp(
        Vector2.new(targetPos.X, targetPos.Z), LERP_SPEED
    )

    -- Set height DIRECTLY from terrain (no lerp - stay on surface!)
    -- v1.4.2 FIX: Use raycast to find ACTUAL terrain surface (voxels don't match math exactly)
    -- getActualTerrainHeight() is the SINGLE SOURCE OF TRUTH for terrain height
    local terrainY = getActualTerrainHeight(newXZ.X, newXZ.Y)  -- Raycast at lerped X,Z position
    local groundY = terrainY + bodyToGround + GROUND_CLEARANCE

    local newPos = Vector3.new(newXZ.X, groundY, newXZ.Y)

    -- Calculate movement direction (for facing)
    local movement = newPos - previousPos
    local moveDistance = movement.Magnitude
    totalDistance = totalDistance + moveDistance

    -- Only update facing if actually moving
    -- FIX v1.3.2: Face the PLAYER's direction, not camel's movement direction
    -- The camel walks alongside the player, so they should face the same way
    -- (Old bug: camel's movement towards offset target made it face towards player)
    if moveDistance > 0.01 then
        local moveDirection = Vector3.new(movement.X, 0, movement.Z).Unit
        local playerFacing = Vector3.new(lookVector.X, 0, lookVector.Z).Unit  -- Player's horizontal look direction
        local oldLookVector = currentLookVector
        currentLookVector = currentLookVector:Lerp(playerFacing, LERP_SPEED * 2)  -- Face player's direction

        -- Debug logging every interval
        if elapsed - lastDebugLog > debugLogInterval then
            lastDebugLog = elapsed
            print("[CamelFollowPlayer v" .. VERSION .. "] DEBUG:")
            print("  position: " .. string.format("(%.1f, %.1f, %.1f)", currentPos.X, currentPos.Y, currentPos.Z))
            print("  terrainY: " .. string.format("%.2f", terrainY))
            print("  groundY: " .. string.format("%.2f", groundY))
            print("  moveDistance: " .. string.format("%.3f", moveDistance))
            print("  playerFacing: " .. string.format("(%.2f, %.2f, %.2f)", playerFacing.X, playerFacing.Y, playerFacing.Z))
        end
    end

    previousPos = currentPos
    currentPos = newPos

    -- Add body bob based on movement
    local bobOffset = 0
    if moveDistance > 0.01 then
        bobOffset = math.sin(totalDistance * BOB_SPEED) * BOB_HEIGHT
    end
    local finalPos = currentPos + Vector3.new(0, bobOffset, 0)

    -- Update body CFrame (position + rotation facing movement direction)
    -- FIX v1.3.3: Account for camel's local forward direction (head is at +X, not -Z)
    -- CFrame.new(pos, lookAt) makes -Z point at target, but camel's front is +X
    -- Calculate rotation offset from camel geometry (single source of truth)
    local forwardAngleOffset = math.atan2(camelForwardLocal.X, -camelForwardLocal.Z)
    local baseCFrame = CFrame.new(finalPos, finalPos + currentLookVector)
    local newCFrame = baseCFrame * CFrame.Angles(0, forwardAngleOffset, 0)  -- v1.3.4: flipped sign
    body.CFrame = newCFrame

    -- Log the resulting orientation periodically
    if elapsed - lastDebugLog < 0.1 then  -- Right after debug log
        print("  forwardAngleOffset: " .. string.format("%.1f", math.deg(forwardAngleOffset)) .. " degrees")
        print("  body.CFrame.LookVector: " .. string.format("(%.2f, %.2f, %.2f)", newCFrame.LookVector.X, newCFrame.LookVector.Y, newCFrame.LookVector.Z))
        print("  body.CFrame.RightVector: " .. string.format("(%.2f, %.2f, %.2f)", newCFrame.RightVector.X, newCFrame.RightVector.Y, newCFrame.RightVector.Z))
    end

    -- Update ALL other parts maintaining offset + leg animation
    for part, offset in pairs(partOffsets) do
        -- Rotate offset by body's rotation
        local rotatedOffset = body.CFrame:VectorToWorldSpace(offset)
        local partPos = finalPos + rotatedOffset

        -- Apply leg swing animation if this is a leg and we're moving
        if moveDistance > 0.01 then
            local isLeg = part.Name:match("Leg") or part.Name:match("Hoof")
            if isLeg then
                -- Determine leg phase (diagonal pairs move together like real quadrupeds)
                local phase = 0
                if part.Name:match("1") or part.Name:match("4") then
                    phase = 0  -- Front-left and back-right
                else
                    phase = math.pi  -- Front-right and back-left
                end

                -- Calculate swing offset
                local swingAngle = math.sin(totalDistance * LEG_SWING_SPEED + phase) * LEG_SWING_ANGLE
                local swingOffset = currentLookVector * math.sin(swingAngle) * 0.5
                partPos = partPos + swingOffset
            end
        end

        part.Position = partPos
    end
end)

print("[CamelFollowPlayer v" .. VERSION .. "] Following player! Ahead=" .. string.format("%.1f", OFFSET_FORWARD) .. " Left=" .. string.format("%.1f", OFFSET_LEFT))

-- Cleanup on script end
game:BindToClose(function()
    if connection then
        connection:Disconnect()
    end
end)
