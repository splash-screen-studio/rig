--[[
    CamelSetup v1.0.0
    Helper module for setting up imported models with PBR textures.
    Used by Claude via MCP after uploading assets.
]]

local CamelSetup = {}
CamelSetup.VERSION = "1.0.0"

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

return CamelSetup
