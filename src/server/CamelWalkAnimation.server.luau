--[[
    CamelWalkAnimation v1.0.0
    Server script that animates the baby camel on game start.
    Synced via Rojo to ServerScriptService.
]]

print("[CamelWalkAnimation v1.0.0] Script starting...")

-- Wait for workspace to load
local camel = workspace:WaitForChild("BabyCamel", 10)
if not camel then
    warn("[CamelWalkAnimation] BabyCamel not found in workspace!")
    return
end

local body = camel:WaitForChild("Body", 5)
if not body then
    warn("[CamelWalkAnimation] Body not found!")
    return
end

print("[CamelWalkAnimation] Found BabyCamel, starting animation...")

-- Animation parameters
local WALK_DISTANCE = 10
local STEPS = 60
local STEP_DELAY = 0.05
local BOB_HEIGHT = 0.3

-- Calculate relative offsets for ALL parts
local partOffsets = {}
local bodyPos = body.Position
for _, part in ipairs(camel:GetChildren()) do
    if part:IsA("BasePart") and part ~= body then
        partOffsets[part] = part.Position - bodyPos
    end
end

print("[CamelWalkAnimation] Tracking " .. tostring(#partOffsets) .. " parts")

local startX = body.Position.X
local startY = body.Position.Y
local startZ = body.Position.Z

-- Small delay before starting
wait(1)
print("[CamelWalkAnimation] Walking...")

-- Walk animation
for i = 1, STEPS do
    local progress = i / STEPS
    local newX = startX + (WALK_DISTANCE * progress)

    -- Bob up and down
    local bobPhase = (i % 10) / 10 * math.pi * 2
    local bobOffset = math.sin(bobPhase) * BOB_HEIGHT
    local newY = startY + bobOffset

    -- Move body
    local newBodyPos = Vector3.new(newX, newY, startZ)
    body.Position = newBodyPos

    -- Move ALL other parts maintaining offset
    for part, offset in pairs(partOffsets) do
        part.Position = newBodyPos + offset
    end

    wait(STEP_DELAY)
end

-- Settle at final position
local finalBodyPos = Vector3.new(startX + WALK_DISTANCE, startY, startZ)
body.Position = finalBodyPos
for part, offset in pairs(partOffsets) do
    part.Position = finalBodyPos + offset
end

print("[CamelWalkAnimation] Walk complete! Final X=" .. tostring(startX + WALK_DISTANCE))
