--[[
    CamelSetup v1.1.0
    Helper module for creating and animating baby camel.
    Used by Claude via MCP.

    IMPORTANT: TweenService does NOT work in MCP context!
    Use direct position changes in loops instead.
]]

local CamelSetup = {}
CamelSetup.VERSION = "1.2.0"

-- Log with version
local function log(msg)
    print("[CamelSetup v" .. CamelSetup.VERSION .. "] " .. msg)
end

-- Create SurfaceAppearance with PBR textures
function CamelSetup.createSurfaceAppearance(meshPart, textures)
    log("Creating SurfaceAppearance for " .. meshPart.Name)

    local sa = Instance.new("SurfaceAppearance")
    sa.Name = "PBRTextures"

    if textures.ColorMap then
        sa.ColorMap = textures.ColorMap
        log("  ColorMap: " .. textures.ColorMap)
    end

    if textures.NormalMap then
        sa.NormalMap = textures.NormalMap
        log("  NormalMap: " .. textures.NormalMap)
    end

    if textures.RoughnessMap then
        sa.RoughnessMap = textures.RoughnessMap
        log("  RoughnessMap: " .. textures.RoughnessMap)
    end

    if textures.MetalnessMap then
        sa.MetalnessMap = textures.MetalnessMap
        log("  MetalnessMap: " .. textures.MetalnessMap)
    end

    sa.Parent = meshPart
    log("  SurfaceAppearance created!")
    return sa
end

-- Setup all MeshParts in a model
function CamelSetup.setupModel(model, textures)
    log("Setting up model: " .. model.Name)

    local count = 0
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("MeshPart") then
            -- Remove existing SurfaceAppearance
            local existing = child:FindFirstChildOfClass("SurfaceAppearance")
            if existing then
                existing:Destroy()
            end

            CamelSetup.createSurfaceAppearance(child, textures)
            count = count + 1
        end
    end

    log("Setup complete! " .. count .. " MeshParts configured")
    return count
end

-- Insert model from asset ID and setup
function CamelSetup.insertAndSetup(modelAssetId, textures, position)
    log("Inserting model: " .. modelAssetId)

    local InsertService = game:GetService("InsertService")
    local success, model = pcall(function()
        return InsertService:LoadAsset(tonumber(modelAssetId))
    end)

    if not success then
        log("ERROR: Failed to load asset " .. modelAssetId)
        log("  " .. tostring(model))
        return nil
    end

    -- Get the actual model from the asset container
    local actualModel = model:GetChildren()[1]
    if actualModel then
        actualModel.Parent = workspace

        if position then
            if actualModel:IsA("Model") and actualModel.PrimaryPart then
                actualModel:SetPrimaryPartCFrame(CFrame.new(position))
            elseif actualModel:IsA("BasePart") then
                actualModel.Position = position
            end
        end

        CamelSetup.setupModel(actualModel, textures)
        log("Model inserted and setup complete!")
        return actualModel
    end

    return nil
end

-- Walk animation using direct position changes (MCP compatible)
-- IMPORTANT: Must move ALL parts together - welds don't work with direct Position changes
function CamelSetup.walk(model, distance, options)
    options = options or {}
    local steps = options.steps or 60
    local stepDelay = options.stepDelay or 0.05
    local bobHeight = options.bobHeight or 0.3

    local body = model:FindFirstChild("Body") or model.PrimaryPart
    if not body then
        log("ERROR: No Body found for walking")
        return false
    end

    -- Calculate relative offsets for ALL parts (welds don't work with Position changes!)
    local partOffsets = {}
    local bodyPos = body.Position
    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") and part ~= body then
            partOffsets[part] = part.Position - bodyPos
        end
    end
    log("Tracking " .. #partOffsets .. " parts relative to body")

    local startX = body.Position.X
    local startY = body.Position.Y
    local startZ = body.Position.Z

    log("Walking " .. distance .. " studs...")

    for i = 1, steps do
        local progress = i / steps
        local newX = startX + (distance * progress)

        -- Bob up and down
        local bobPhase = (i % 10) / 10 * math.pi * 2
        local bobOffset = math.sin(bobPhase) * bobHeight
        local newY = startY + bobOffset

        -- Move body
        local newBodyPos = Vector3.new(newX, newY, startZ)
        body.Position = newBodyPos

        -- Move ALL other parts maintaining offset (P0 bug fix!)
        for part, offset in pairs(partOffsets) do
            part.Position = newBodyPos + offset
        end

        wait(stepDelay)
    end

    -- Settle at final Y
    local finalBodyPos = Vector3.new(startX + distance, startY, startZ)
    body.Position = finalBodyPos
    for part, offset in pairs(partOffsets) do
        part.Position = finalBodyPos + offset
    end

    log("Walk complete! Final X=" .. (startX + distance))
    return true
end

-- Create baby camel model
function CamelSetup.createBabyCamel(position)
    position = position or Vector3.new(0, 3, 0)
    log("Creating baby camel at " .. tostring(position))

    local CAMEL_COLOR = Color3.fromRGB(255, 140, 0)
    local HOOF_COLOR = Color3.fromRGB(139, 90, 43)
    local EYE_COLOR = Color3.fromRGB(20, 20, 20)

    local camel = Instance.new("Model")
    camel.Name = "BabyCamel"

    -- Body
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(3, 1.5, 2)
    body.Position = position
    body.Color = CAMEL_COLOR
    body.Material = Enum.Material.Neon
    body.Anchored = true
    body.Parent = camel
    camel.PrimaryPart = body

    -- Head
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(1.2, 1.2, 1.2)
    head.Position = position + Vector3.new(2, 1, 0)
    head.Color = CAMEL_COLOR
    head.Material = Enum.Material.Neon
    head.Anchored = false
    head.Parent = camel

    -- Weld head to body
    local headWeld = Instance.new("WeldConstraint")
    headWeld.Part0 = body
    headWeld.Part1 = head
    headWeld.Parent = head

    -- Add more parts as needed...
    log("Baby camel created with " .. #camel:GetChildren() .. " parts")
    return camel
end

return CamelSetup
