--[[
    TerrainConfig v1.0.0
    Single source of truth for all terrain elevation and material calculations.
    Used by: Terrain generation (MCP), CamelFollowPlayer (runtime)

    NO MAGIC NUMBERS - all values derived from named parameters below.
]]

local TerrainConfig = {}
TerrainConfig.VERSION = "1.0.0"

-- ============================================
-- TERRAIN PARAMETERS (the ONLY place to define values)
-- ============================================

-- World bounds (symmetrical around origin)
TerrainConfig.WORLD_HALF_SIZE = 256
TerrainConfig.WORLD_MIN_X = -TerrainConfig.WORLD_HALF_SIZE
TerrainConfig.WORLD_MAX_X = TerrainConfig.WORLD_HALF_SIZE
TerrainConfig.WORLD_MIN_Z = -TerrainConfig.WORLD_HALF_SIZE
TerrainConfig.WORLD_MAX_Z = TerrainConfig.WORLD_HALF_SIZE

-- Elevation range
TerrainConfig.BASE_ELEVATION = 0           -- Lowest valleys
TerrainConfig.MAX_ELEVATION = 80           -- Highest peaks
TerrainConfig.ELEVATION_RANGE = TerrainConfig.MAX_ELEVATION - TerrainConfig.BASE_ELEVATION

-- Noise parameters for natural undulation
TerrainConfig.NOISE_SEED = 42              -- Reproducible terrain
TerrainConfig.NOISE_SCALE = 0.01           -- Larger = smoother hills
TerrainConfig.NOISE_OCTAVES = 4            -- Layers of detail
TerrainConfig.NOISE_PERSISTENCE = 0.5      -- How much each octave contributes
TerrainConfig.NOISE_LACUNARITY = 2.0       -- Frequency multiplier per octave

-- Material thresholds (as fractions of ELEVATION_RANGE)
-- These define where each material transitions
TerrainConfig.MATERIAL_THRESHOLDS = {
    SAND = 0.05,    -- 0-5%: sandy lowlands
    GRASS = 0.35,   -- 5-35%: grassy plains
    GROUND = 0.55,  -- 35-55%: dirt/mud transition
    ROCK = 0.80,    -- 55-80%: rocky highlands
    SNOW = 1.0,     -- 80-100%: snowy peaks
}

-- Terrain generation resolution
TerrainConfig.VOXEL_RESOLUTION = 4  -- Studs per terrain voxel

-- ============================================
-- LOGGING
-- ============================================

local function log(msg)
    print("[TerrainConfig v" .. TerrainConfig.VERSION .. "] " .. msg)
end

-- ============================================
-- DERIVED VALUES (calculated from parameters)
-- ============================================

function TerrainConfig.getElevationThresholds()
    local base = TerrainConfig.BASE_ELEVATION
    local range = TerrainConfig.ELEVATION_RANGE
    return {
        SAND = base + range * TerrainConfig.MATERIAL_THRESHOLDS.SAND,
        GRASS = base + range * TerrainConfig.MATERIAL_THRESHOLDS.GRASS,
        GROUND = base + range * TerrainConfig.MATERIAL_THRESHOLDS.GROUND,
        ROCK = base + range * TerrainConfig.MATERIAL_THRESHOLDS.ROCK,
        SNOW = base + range * TerrainConfig.MATERIAL_THRESHOLDS.SNOW,
    }
end

-- ============================================
-- FRACTAL BROWNIAN MOTION NOISE
-- ============================================

local function fbm(x, z, seed)
    local total = 0
    local amplitude = 1
    local frequency = 1
    local maxValue = 0  -- For normalization

    for i = 1, TerrainConfig.NOISE_OCTAVES do
        -- Roblox's math.noise returns values in [-0.5, 0.5]
        local noiseValue = math.noise(
            x * TerrainConfig.NOISE_SCALE * frequency + seed,
            z * TerrainConfig.NOISE_SCALE * frequency + seed
        )
        total = total + noiseValue * amplitude
        maxValue = maxValue + amplitude
        amplitude = amplitude * TerrainConfig.NOISE_PERSISTENCE
        frequency = frequency * TerrainConfig.NOISE_LACUNARITY
    end

    -- Normalize to [0, 1]
    return (total / maxValue) + 0.5
end

-- ============================================
-- CANONICAL ELEVATION FUNCTION
-- This is THE function everyone must use
-- ============================================

function TerrainConfig.getElevation(x, z)
    local normalizedNoise = fbm(x, z, TerrainConfig.NOISE_SEED)
    return TerrainConfig.BASE_ELEVATION + (normalizedNoise * TerrainConfig.ELEVATION_RANGE)
end

-- ============================================
-- MATERIAL DETERMINATION
-- ============================================

function TerrainConfig.getMaterial(elevation)
    local thresholds = TerrainConfig.getElevationThresholds()

    if elevation < thresholds.SAND then
        return Enum.Material.Sand
    elseif elevation < thresholds.GRASS then
        return Enum.Material.Grass
    elseif elevation < thresholds.GROUND then
        return Enum.Material.Ground
    elseif elevation < thresholds.ROCK then
        return Enum.Material.Rock
    else
        return Enum.Material.Snow
    end
end

-- ============================================
-- TERRAIN GENERATION (for MCP use)
-- ============================================

function TerrainConfig.generateTerrain()
    local terrain = workspace.Terrain
    local resolution = TerrainConfig.VOXEL_RESOLUTION

    log("Generating terrain...")
    log("  World bounds: [" .. TerrainConfig.WORLD_MIN_X .. ", " .. TerrainConfig.WORLD_MAX_X .. "]")
    log("  Elevation range: [" .. TerrainConfig.BASE_ELEVATION .. ", " .. TerrainConfig.MAX_ELEVATION .. "]")
    log("  Resolution: " .. resolution .. " studs/voxel")

    -- Log material thresholds
    local thresholds = TerrainConfig.getElevationThresholds()
    log("  Material thresholds (elevation):")
    log("    Sand < " .. string.format("%.1f", thresholds.SAND))
    log("    Grass < " .. string.format("%.1f", thresholds.GRASS))
    log("    Ground < " .. string.format("%.1f", thresholds.GROUND))
    log("    Rock < " .. string.format("%.1f", thresholds.ROCK))
    log("    Snow >= " .. string.format("%.1f", thresholds.ROCK))

    -- Clear existing terrain
    terrain:Clear()
    log("  Cleared existing terrain")

    local startTime = tick()
    local columns = 0
    local totalColumns = ((TerrainConfig.WORLD_MAX_X - TerrainConfig.WORLD_MIN_X) / resolution)
                       * ((TerrainConfig.WORLD_MAX_Z - TerrainConfig.WORLD_MIN_Z) / resolution)

    -- Generate terrain column by column
    for x = TerrainConfig.WORLD_MIN_X, TerrainConfig.WORLD_MAX_X - resolution, resolution do
        for z = TerrainConfig.WORLD_MIN_Z, TerrainConfig.WORLD_MAX_Z - resolution, resolution do
            local elevation = TerrainConfig.getElevation(x, z)
            local material = TerrainConfig.getMaterial(elevation)

            -- Fill from below base up to surface
            local minY = TerrainConfig.BASE_ELEVATION - 10
            local region = Region3.new(
                Vector3.new(x, minY, z),
                Vector3.new(x + resolution, elevation, z + resolution)
            ):ExpandToGrid(resolution)

            terrain:FillRegion(region, resolution, material)
            columns = columns + 1
        end

        -- Progress feedback every 32 X slices
        if columns % (32 * (TerrainConfig.WORLD_HALF_SIZE * 2 / resolution)) < (TerrainConfig.WORLD_HALF_SIZE * 2 / resolution) then
            local progress = (columns / totalColumns) * 100
            log("  Progress: " .. string.format("%.0f", progress) .. "%")
            wait()  -- Yield to prevent timeout
        end
    end

    local elapsed = tick() - startTime
    log("Terrain generation complete!")
    log("  Columns: " .. columns)
    log("  Time: " .. string.format("%.2f", elapsed) .. " seconds")

    return true
end

-- ============================================
-- DEBUG: Sample elevation at a point
-- ============================================

function TerrainConfig.debugElevation(x, z)
    local elevation = TerrainConfig.getElevation(x, z)
    local material = TerrainConfig.getMaterial(elevation)
    log("Elevation at (" .. x .. ", " .. z .. "):")
    log("  Height: " .. string.format("%.2f", elevation))
    log("  Material: " .. tostring(material))
    return elevation, material
end

return TerrainConfig
