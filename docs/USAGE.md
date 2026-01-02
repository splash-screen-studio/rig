# Usage Guide

Complete guide for the professional 3D animation pipeline.

## Installation

### 1. Install Blender

```bash
# macOS via Homebrew
brew install --cask blender

# Verify installation
blender --version
```

### 2. Install Python Dependencies

```bash
cd rig
pip install -r requirements.txt
```

## Workflows

### Headless Animation Rendering

Render an animation without opening the Blender GUI:

```bash
# Basic animation render
blender -b assets/my_scene.blend -a

# With custom settings
blender -b assets/my_scene.blend \
  -E CYCLES \
  -s 1 \
  -e 250 \
  -o //renders/frame_#### \
  -F PNG \
  -a

# Using the batch render script
blender -b assets/my_scene.blend --python scripts/batch_render.py -- \
  --output renders/my_animation \
  --engine CYCLES \
  --samples 256 \
  --resolution 1920 1080 \
  --start 1 \
  --end 250
```

**Parameters:**
- `-b` = background/headless mode
- `-E CYCLES` = use Cycles render engine
- `-s 1` = start at frame 1
- `-e 250` = end at frame 250
- `-o //renders/frame_####` = output path (// means relative to .blend file)
- `-F PNG` = output format
- `-a` = render animation

### Baking PBR Textures for Roblox

Bake Color, Normal, Roughness, and Metalness maps:

```bash
blender -b assets/character.blend --python scripts/bake_pbr.py -- \
  --object "Character" \
  --output exports/character_textures \
  --resolution 2048
```

This creates:
- `Character_ColorMap.png`
- `Character_NormalMap.png`
- `Character_RoughnessMap.png`

**Resolution options:** 1024, 2048, 4096

### Exporting to FBX for Roblox

Export models with proper transforms applied:

```bash
blender -b assets/character.blend --python scripts/export_fbx.py -- \
  --objects "Character" "Weapon" \
  --output exports/character.fbx
```

**Features:**
- Automatically applies transforms (scale, rotation, location)
- Validates mesh (UV maps, n-gons, scale)
- Optimizes for Roblox import
- Supports multiple objects
- Includes armatures for rigging

### Single Frame Rendering

Render a specific frame for testing:

```bash
blender -b assets/scene.blend --python scripts/batch_render.py -- \
  --output renders/test \
  --frame 120 \
  --engine CYCLES \
  --samples 256
```

## Roblox Integration

### Importing FBX Models

1. Open Roblox Studio
2. **Avatar → Import 3D** or **Model → Import 3D**
3. Select your exported `.fbx` file
4. The model appears in the workspace

### Adding PBR Textures

For each `MeshPart`:

1. Insert `SurfaceAppearance` object as child:
   ```
   MeshPart
   └── SurfaceAppearance
   ```

2. Upload textures via **Asset Manager**:
   - Click **Create** → **Image**
   - Upload each baked texture map
   - Note the asset ID for each

3. Set texture properties in `SurfaceAppearance`:
   - `ColorMap` = `rbxassetid://[ColorMap ID]`
   - `NormalMap` = `rbxassetid://[NormalMap ID]`
   - `RoughnessMap` = `rbxassetid://[RoughnessMap ID]`
   - `MetalnessMap` = `rbxassetid://[MetalnessMap ID]`

## Advanced Usage

### Custom Python Scripts

Run any Python script in Blender's environment:

```bash
blender -b my_file.blend --python my_script.py
```

Pass arguments after `--`:

```bash
blender -b file.blend --python script.py -- --arg1 value1 --arg2 value2
```

### GPU Acceleration

Enable GPU rendering for faster performance:

```bash
# In your Python scripts, use:
bpy.context.scene.cycles.device = 'GPU'
```

Verify GPU is detected:

```bash
blender -b --python-expr "import bpy; print(bpy.context.preferences.addons['cycles'].preferences.devices)"
```

### Batch Processing Multiple Files

Process all `.blend` files in a directory:

```bash
for file in assets/*.blend; do
  echo "Processing $file..."
  blender -b "$file" --python scripts/batch_render.py -- \
    --output "renders/$(basename "$file" .blend)" \
    --engine CYCLES
done
```

## Troubleshooting

### "Object has no UV map"

UV unwrapping is required for PBR texture baking:

1. Open Blender GUI
2. Select object → Edit mode
3. Select all faces (A)
4. UV → Unwrap

Or use Smart UV Project for automatic unwrapping.

### "Blender command not found"

Add Blender to PATH or use full path:

```bash
# macOS
/Applications/Blender.app/Contents/MacOS/Blender -b ...
```

### FBX Import Issues in Roblox

- Ensure all transforms are applied (script does this automatically)
- Check that scale is (1, 1, 1) before export
- Validate mesh has no n-gons (faces with >4 vertices)
- Confirm axis orientation matches Roblox (-Z forward, Y up)

## Performance Tips

1. **Use EEVEE for previews:** Much faster than Cycles
   ```bash
   blender -b file.blend -E EEVEE -a
   ```

2. **Reduce samples for testing:**
   ```bash
   --samples 32  # instead of 256
   ```

3. **Render at lower resolution:**
   ```bash
   --resolution 1280 720  # instead of 1920 1080
   ```

4. **Use frame step for previews:**
   ```bash
   blender -b file.blend -s 1 -e 250 -j 10 -a  # every 10th frame
   ```

## Resources

- [Blender Python API](https://docs.blender.org/api/current/)
- [Blender CLI Documentation](https://docs.blender.org/manual/en/latest/advanced/command_line/)
- [Roblox PBR Textures](https://create.roblox.com/docs/art/modeling/surface-appearance)
- [Cycles Render Settings](https://docs.blender.org/manual/en/latest/render/cycles/)
