--[[
    CamelFollowPlayer v1.5.0
    Makes the baby camel follow the player with multiple behavior modes.

    BEHAVIOR MODES:
    - FOLLOW_PLAYER: Walk alongside player (original behavior)
    - RUN_TO_CUPCAKE: Sprint to a nearby cupcake
    - CIRCLE_CUPCAKE: Circle around the cupcake excitedly
    - RETURN_TO_PLAYER: Sprint back to player

    Uses TerrainConfig as SINGLE SOURCE OF TRUTH for terrain elevation.
    All dimensions calculated from actual camel geometry.
    Cupcake selection uses randomness within distance threshold.

    Synced via Rojo to ServerScriptService.

    v1.3.x: Facing direction fixes
    v1.4.x: Dynamic terrain elevation with raycast
    v1.5.0: State machine with cupcake chase behavior
    v1.5.1: Acceleration/deceleration, normal circle speed
    v1.5.2: Favor cupcakes in player's field of vision
    v1.5.3: Faster speeds, quicker acceleration/deceleration
    v1.5.4: Direction-based search radius (far in front, close behind)
    v1.5.5: Fixed print statement referencing removed variable
]]

local VERSION = "1.5.5"
print("[CamelFollowPlayer v" .. VERSION .. "] Script starting...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for TerrainConfig module (SINGLE SOURCE OF TRUTH for terrain)
local TerrainConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TerrainConfig"))
print("[CamelFollowPlayer v" .. VERSION .. "] TerrainConfig v" .. TerrainConfig.VERSION .. " loaded")

-- ============================================
-- TERRAIN RAYCAST (single source of truth)
-- ============================================

local function getActualTerrainHeight(x, z)
    local rayOrigin = Vector3.new(x, TerrainConfig.MAX_ELEVATION + 50, z)
    local rayDirection = Vector3.new(0, -(TerrainConfig.ELEVATION_RANGE + 100), 0)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = {workspace.Terrain}

    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if result then
        return result.Position.Y
    else
        return TerrainConfig.getElevation(x, z)
    end
end

-- ============================================
-- WAIT FOR CAMEL
-- ============================================

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
-- CAMEL GEOMETRY (single source of truth)
-- ============================================

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
local bodyToGround = body.Position.Y - lowestY

-- Determine camel's forward direction from geometry
local head = camel:FindFirstChild("Head")
local camelForwardLocal = Vector3.new(1, 0, 0)
if head then
    local headOffset = head.Position - body.Position
    local headOffsetFlat = Vector3.new(headOffset.X, 0, headOffset.Z)
    if headOffsetFlat.Magnitude > 0.1 then
        camelForwardLocal = headOffsetFlat.Unit
    end
end

print("[CamelFollowPlayer v" .. VERSION .. "] Camel geometry:")
print("  Height: " .. string.format("%.2f", camelHeight) .. " studs")
print("  Body to ground: " .. string.format("%.2f", bodyToGround) .. " studs")

-- ============================================
-- CONFIGURATION (derived from camel geometry)
-- ============================================

-- Following player offsets
local OFFSET_FORWARD = camelHeight * 2.5
local OFFSET_LEFT = camelHeight * 1.2
local GROUND_CLEARANCE = 0.1

-- Movement speeds (studs per second, derived from camel height)
local SPEED_WALK = camelHeight * 2.5      -- Normal walking with player
local SPEED_RUN = camelHeight * 6.0       -- Fast running to/from cupcake
local SPEED_CIRCLE = camelHeight * 2.0    -- Circling cupcake

-- Acceleration (studs per second squared - fast/brief transitions)
local ACCELERATION = camelHeight * 12.0   -- Quick speed up
local DECELERATION = camelHeight * 15.0   -- Quick slow down

-- Animation parameters
local BOB_HEIGHT = camelHeight * 0.03
local BOB_SPEED = 8
local LEG_SWING_ANGLE = math.rad(20)
local LEG_SWING_SPEED = 10

-- Cupcake behavior timing (derived from camel size for consistency)
local FOLLOW_DURATION_MIN = 5    -- Min seconds following player
local FOLLOW_DURATION_MAX = 12   -- Max seconds following player
local CIRCLE_DURATION = 3        -- Seconds circling cupcake
local CIRCLE_RADIUS = camelHeight * 1.5  -- Circle radius around cupcake
local CIRCLE_SPEED = 2           -- Rotations per circle duration

-- Cupcake selection - search radius varies by direction (world size is single source of truth)
local CUPCAKE_SEARCH_RADIUS_FRONT = TerrainConfig.WORLD_HALF_SIZE * 0.8   -- 80% of world if in front
local CUPCAKE_SEARCH_RADIUS_SIDE = TerrainConfig.WORLD_HALF_SIZE * 0.4    -- 40% of world to the side
local CUPCAKE_SEARCH_RADIUS_BEHIND = TerrainConfig.WORLD_HALF_SIZE * 0.15 -- 15% of world if behind
local CUPCAKE_NEARBY_THRESHOLD = camelHeight * 20  -- Distance weight factor

-- FOV weighting - favor cupcakes in player's field of vision
local FOV_WEIGHT_FRONT = 3.0    -- Multiplier for cupcakes directly in front
local FOV_WEIGHT_SIDE = 1.0     -- Multiplier for cupcakes to the side
local FOV_WEIGHT_BEHIND = 0.1   -- Multiplier for cupcakes behind (rarely chosen)

print("[CamelFollowPlayer v" .. VERSION .. "] Configuration:")
print("  Speeds: walk=" .. string.format("%.1f", SPEED_WALK) .. " run=" .. string.format("%.1f", SPEED_RUN) .. " circle=" .. string.format("%.1f", SPEED_CIRCLE))
print("  Acceleration=" .. string.format("%.1f", ACCELERATION) .. " Deceleration=" .. string.format("%.1f", DECELERATION))
print("  Cupcake search radius: front=" .. string.format("%.1f", CUPCAKE_SEARCH_RADIUS_FRONT) .. " side=" .. string.format("%.1f", CUPCAKE_SEARCH_RADIUS_SIDE) .. " behind=" .. string.format("%.1f", CUPCAKE_SEARCH_RADIUS_BEHIND))

-- ============================================
-- STATE MACHINE
-- ============================================

local State = {
    FOLLOW_PLAYER = "FOLLOW_PLAYER",
    RUN_TO_CUPCAKE = "RUN_TO_CUPCAKE",
    CIRCLE_CUPCAKE = "CIRCLE_CUPCAKE",
    RETURN_TO_PLAYER = "RETURN_TO_PLAYER",
}

local currentState = State.FOLLOW_PLAYER
local stateStartTime = 0
local stateDuration = 0
local targetCupcake = nil
local circleAngle = 0

-- ============================================
-- CUPCAKE SELECTION
-- ============================================

local function selectCupcake(playerPos, playerLookVector)
    local cupcakesFolder = workspace:FindFirstChild("Cupcakes")
    if not cupcakesFolder then return nil end

    local playerLookFlat = Vector3.new(playerLookVector.X, 0, playerLookVector.Z).Unit
    local candidates = {}

    -- Find all cupcakes within search radius
    for _, cupcake in ipairs(cupcakesFolder:GetChildren()) do
        if cupcake:IsA("Model") and cupcake.PrimaryPart then
            local cupcakePos = cupcake.PrimaryPart.Position
            local toCupcake = Vector3.new(cupcakePos.X - playerPos.X, 0, cupcakePos.Z - playerPos.Z)
            local distance = toCupcake.Magnitude

            if distance > 0.1 then
                local dirToCupcake = toCupcake.Unit

                -- Dot product: 1 = directly in front, 0 = side, -1 = behind
                local dot = playerLookFlat:Dot(dirToCupcake)

                -- Determine max search radius based on direction
                local maxRadius
                if dot > 0.5 then
                    maxRadius = CUPCAKE_SEARCH_RADIUS_FRONT  -- In front
                elseif dot > -0.3 then
                    maxRadius = CUPCAKE_SEARCH_RADIUS_SIDE   -- Side
                else
                    maxRadius = CUPCAKE_SEARCH_RADIUS_BEHIND -- Behind
                end

                -- Only consider if within direction-based radius
                if distance <= maxRadius then
                    -- Calculate FOV weight based on dot product
                    local fovWeight
                    if dot > 0.5 then
                        fovWeight = FOV_WEIGHT_FRONT
                    elseif dot > 0 then
                        fovWeight = FOV_WEIGHT_FRONT * 0.7
                    elseif dot > -0.5 then
                        fovWeight = FOV_WEIGHT_SIDE
                    else
                        fovWeight = FOV_WEIGHT_BEHIND
                    end

                    -- Combine distance weight with FOV weight
                    local distWeight = 1 / (distance + CUPCAKE_NEARBY_THRESHOLD * 0.5)
                    local totalWeight = distWeight * fovWeight

                    table.insert(candidates, {
                        cupcake = cupcake,
                        distance = distance,
                        dot = dot,
                        weight = totalWeight
                    })
                end
            end
        end
    end

    if #candidates == 0 then return nil end

    -- Calculate total weight
    local totalWeight = 0
    for _, c in ipairs(candidates) do
        totalWeight = totalWeight + c.weight
    end

    -- Random weighted selection
    local roll = math.random() * totalWeight
    local cumulative = 0
    for _, c in ipairs(candidates) do
        cumulative = cumulative + c.weight
        if roll <= cumulative then
            local facing = c.dot > 0.5 and "FRONT" or (c.dot > 0 and "FRONT-SIDE" or (c.dot > -0.5 and "SIDE" or "BEHIND"))
            print("[CamelFollowPlayer v" .. VERSION .. "] Selected " .. c.cupcake.Name .. " dist=" .. string.format("%.0f", c.distance) .. " (" .. facing .. ")")
            return c.cupcake
        end
    end

    -- Fallback to first candidate
    return candidates[1].cupcake
end

-- ============================================
-- SETUP PARTS
-- ============================================

body.Anchored = true
body.CanCollide = false

local partOffsets = {}
for _, part in ipairs(camel:GetChildren()) do
    if part:IsA("BasePart") and part ~= body then
        partOffsets[part] = part.Position - body.Position
        part.Anchored = true
        part.CanCollide = false
    end
end

local partCount = 0
for _ in pairs(partOffsets) do partCount = partCount + 1 end
print("[CamelFollowPlayer v" .. VERSION .. "] Tracking " .. partCount .. " parts")

-- ============================================
-- MOVEMENT STATE
-- ============================================

local currentPos = body.Position
local currentLookVector = Vector3.new(1, 0, 0)
local previousPos = currentPos
local currentSpeed = 0  -- Current speed in studs/sec (for acceleration)
local elapsed = 0
local totalDistance = 0
local lastDebugLog = 0

-- Initialize state
stateStartTime = 0
stateDuration = math.random() * (FOLLOW_DURATION_MAX - FOLLOW_DURATION_MIN) + FOLLOW_DURATION_MIN

-- ============================================
-- MAIN LOOP
-- ============================================

local connection
connection = RunService.Heartbeat:Connect(function(dt)
    elapsed = elapsed + dt

    -- Get player
    local player = Players:GetPlayers()[1]
    if not player then return end
    local character = player.Character
    if not character then return end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local playerCFrame = humanoidRootPart.CFrame
    local playerPos = playerCFrame.Position
    local lookVector = playerCFrame.LookVector
    local rightVector = playerCFrame.RightVector

    -- ============================================
    -- STATE MACHINE LOGIC
    -- ============================================

    local targetPos
    local targetLookVector
    local targetSpeed = SPEED_WALK
    local stateTime = elapsed - stateStartTime

    if currentState == State.FOLLOW_PLAYER then
        -- Walk alongside player
        targetPos = playerPos + (lookVector * OFFSET_FORWARD) - (rightVector * OFFSET_LEFT)
        targetLookVector = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
        targetSpeed = SPEED_WALK

        -- Check if time to go get a cupcake
        if stateTime >= stateDuration then
            local cupcake = selectCupcake(playerPos, lookVector)
            if cupcake then
                targetCupcake = cupcake
                currentState = State.RUN_TO_CUPCAKE
                stateStartTime = elapsed
                print("[CamelFollowPlayer v" .. VERSION .. "] State: RUN_TO_CUPCAKE -> " .. cupcake.Name)
            else
                -- No cupcakes, reset timer
                stateStartTime = elapsed
                stateDuration = math.random() * (FOLLOW_DURATION_MAX - FOLLOW_DURATION_MIN) + FOLLOW_DURATION_MIN
            end
        end

    elseif currentState == State.RUN_TO_CUPCAKE then
        -- Sprint to cupcake
        if not targetCupcake or not targetCupcake.PrimaryPart then
            currentState = State.FOLLOW_PLAYER
            stateStartTime = elapsed
            stateDuration = math.random() * (FOLLOW_DURATION_MAX - FOLLOW_DURATION_MIN) + FOLLOW_DURATION_MIN
        else
            local cupcakePos = targetCupcake.PrimaryPart.Position
            targetPos = Vector3.new(cupcakePos.X, currentPos.Y, cupcakePos.Z)

            -- Face toward cupcake
            local toCupcake = (targetPos - currentPos)
            if toCupcake.Magnitude > 0.1 then
                targetLookVector = Vector3.new(toCupcake.X, 0, toCupcake.Z).Unit
            else
                targetLookVector = currentLookVector
            end

            -- Decelerate as we approach cupcake
            local distToCupcake = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(cupcakePos.X, 0, cupcakePos.Z)).Magnitude
            if distToCupcake < CIRCLE_RADIUS * 3 then
                targetSpeed = SPEED_CIRCLE  -- Slow down near cupcake
            else
                targetSpeed = SPEED_RUN
            end

            -- Check if arrived at cupcake
            if distToCupcake < CIRCLE_RADIUS then
                currentState = State.CIRCLE_CUPCAKE
                stateStartTime = elapsed
                circleAngle = math.atan2(currentPos.Z - cupcakePos.Z, currentPos.X - cupcakePos.X)
                print("[CamelFollowPlayer v" .. VERSION .. "] State: CIRCLE_CUPCAKE")
            end
        end

    elseif currentState == State.CIRCLE_CUPCAKE then
        -- Circle around cupcake at normal pace
        if not targetCupcake or not targetCupcake.PrimaryPart then
            currentState = State.RETURN_TO_PLAYER
            stateStartTime = elapsed
        else
            local cupcakePos = targetCupcake.PrimaryPart.Position

            -- Update circle angle based on circle speed (not fixed rotations)
            local angularSpeed = SPEED_CIRCLE / CIRCLE_RADIUS  -- radians per second
            circleAngle = circleAngle + angularSpeed * dt

            -- Position on circle
            targetPos = Vector3.new(
                cupcakePos.X + math.cos(circleAngle) * CIRCLE_RADIUS,
                currentPos.Y,
                cupcakePos.Z + math.sin(circleAngle) * CIRCLE_RADIUS
            )

            -- Face tangent to circle (direction of movement)
            targetLookVector = Vector3.new(-math.sin(circleAngle), 0, math.cos(circleAngle))
            targetSpeed = SPEED_CIRCLE  -- Normal pace while circling

            -- Check if done circling
            if stateTime >= CIRCLE_DURATION then
                currentState = State.RETURN_TO_PLAYER
                stateStartTime = elapsed
                print("[CamelFollowPlayer v" .. VERSION .. "] State: RETURN_TO_PLAYER")
            end
        end

    elseif currentState == State.RETURN_TO_PLAYER then
        -- Sprint back to player
        local returnTarget = playerPos + (lookVector * OFFSET_FORWARD) - (rightVector * OFFSET_LEFT)
        targetPos = returnTarget

        -- Face toward player position
        local toPlayer = (targetPos - currentPos)
        if toPlayer.Magnitude > 0.1 then
            targetLookVector = Vector3.new(toPlayer.X, 0, toPlayer.Z).Unit
        else
            targetLookVector = currentLookVector
        end

        -- Decelerate as we approach player
        local distToTarget = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(returnTarget.X, 0, returnTarget.Z)).Magnitude
        if distToTarget < camelHeight * 3 then
            targetSpeed = SPEED_WALK  -- Slow down near player
        else
            targetSpeed = SPEED_RUN
        end

        -- Check if back with player
        if distToTarget < camelHeight then
            currentState = State.FOLLOW_PLAYER
            stateStartTime = elapsed
            stateDuration = math.random() * (FOLLOW_DURATION_MAX - FOLLOW_DURATION_MIN) + FOLLOW_DURATION_MIN
            targetCupcake = nil
            print("[CamelFollowPlayer v" .. VERSION .. "] State: FOLLOW_PLAYER (duration: " .. string.format("%.1f", stateDuration) .. "s)")
        end
    end

    -- ============================================
    -- MOVEMENT & ANIMATION
    -- ============================================

    -- Apply acceleration/deceleration to current speed
    if currentSpeed < targetSpeed then
        currentSpeed = math.min(currentSpeed + ACCELERATION * dt, targetSpeed)
    elseif currentSpeed > targetSpeed then
        currentSpeed = math.max(currentSpeed - DECELERATION * dt, targetSpeed)
    end

    -- Calculate direction to target
    local toTarget = Vector3.new(targetPos.X - currentPos.X, 0, targetPos.Z - currentPos.Z)
    local distToTarget = toTarget.Magnitude
    local moveDir = distToTarget > 0.1 and toTarget.Unit or currentLookVector

    -- Move at current speed (don't overshoot target)
    local moveAmount = math.min(currentSpeed * dt, distToTarget)
    local newX = currentPos.X + moveDir.X * moveAmount
    local newZ = currentPos.Z + moveDir.Z * moveAmount

    -- Get terrain height at new position
    local terrainY = getActualTerrainHeight(newX, newZ)
    local groundY = terrainY + bodyToGround + GROUND_CLEARANCE

    local newPos = Vector3.new(newX, groundY, newZ)

    -- Track movement
    local movement = newPos - previousPos
    local moveDistance = movement.Magnitude
    totalDistance = totalDistance + moveDistance

    -- Update facing (turn faster when moving faster)
    if targetLookVector and moveDistance > 0.01 then
        local lookLerp = math.min(0.15, moveDistance * 0.5)
        currentLookVector = currentLookVector:Lerp(targetLookVector, lookLerp)
    end

    previousPos = currentPos
    currentPos = newPos

    -- Body bob (scales with speed for more energetic running)
    local bobOffset = 0
    if moveDistance > 0.01 then
        local bobScale = math.min(currentSpeed / SPEED_WALK, 1.5)  -- More bob when running
        bobOffset = math.sin(totalDistance * BOB_SPEED) * BOB_HEIGHT * bobScale
    end
    local finalPos = currentPos + Vector3.new(0, bobOffset, 0)

    -- Update body CFrame
    local forwardAngleOffset = math.atan2(camelForwardLocal.X, -camelForwardLocal.Z)
    local baseCFrame = CFrame.new(finalPos, finalPos + currentLookVector)
    local newCFrame = baseCFrame * CFrame.Angles(0, forwardAngleOffset, 0)
    body.CFrame = newCFrame

    -- Update all other parts with leg animation (faster legs when running)
    local legSpeedMult = currentSpeed / SPEED_WALK  -- Legs move faster when running
    for part, offset in pairs(partOffsets) do
        local rotatedOffset = body.CFrame:VectorToWorldSpace(offset)
        local partPos = finalPos + rotatedOffset

        if moveDistance > 0.01 then
            local isLeg = part.Name:match("Leg") or part.Name:match("Hoof")
            if isLeg then
                local phase = 0
                if part.Name:match("1") or part.Name:match("4") then
                    phase = 0
                else
                    phase = math.pi
                end
                local swingAngle = math.sin(totalDistance * LEG_SWING_SPEED * legSpeedMult + phase) * LEG_SWING_ANGLE
                local swingOffset = currentLookVector * math.sin(swingAngle) * 0.5
                partPos = partPos + swingOffset
            end
        end

        part.Position = partPos
    end

    -- Debug logging
    if elapsed - lastDebugLog > 5 then
        lastDebugLog = elapsed
        print("[CamelFollowPlayer v" .. VERSION .. "] State: " .. currentState .. " | Pos: " .. string.format("(%.0f, %.0f, %.0f)", currentPos.X, currentPos.Y, currentPos.Z))
    end
end)

print("[CamelFollowPlayer v" .. VERSION .. "] Started with state machine! Modes: FOLLOW_PLAYER, RUN_TO_CUPCAKE, CIRCLE_CUPCAKE, RETURN_TO_PLAYER")

game:BindToClose(function()
    if connection then
        connection:Disconnect()
    end
end)
