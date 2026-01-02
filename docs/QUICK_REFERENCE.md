# Quick Reference

Fast lookup for common Blender CLI commands and pipeline tasks.

## Blender CLI Commands

### Basic Syntax

```bash
blender [options] [file.blend] [--python script.py] [-- script_args]
```

### Common Flags

| Flag | Description |
|------|-------------|
| `-b` | Background/headless mode |
| `-a` | Render animation |
| `-f NUM` | Render single frame NUM |
| `-s NUM` | Start frame |
| `-e NUM` | End frame |
| `-j NUM` | Frame step (jump) |
| `-o PATH` | Output path |
| `-F FORMAT` | Output format (PNG, JPEG, EXR, etc.) |
| `-E ENGINE` | Render engine (CYCLES, EEVEE) |
| `-t NUM` | Number of threads |
| `-p NUM` | Resolution percentage |
| `--python FILE` | Run Python script |
| `--python-expr EXPR` | Execute Python expression |

### Quick Commands

```bash
# Render full animation
blender -b scene.blend -a

# Render frames 1-100
blender -b scene.blend -s 1 -e 100 -a

# Render every 5th frame
blender -b scene.blend -j 5 -a

# Render single frame 42
blender -b scene.blend -f 42

# Use Cycles with custom output
blender -b scene.blend -E CYCLES -o //renders/frame_#### -F PNG -a

# Run Python script
blender -b scene.blend --python my_script.py

# Run script with args
blender -b scene.blend --python script.py -- --arg1 value1
```

## Pipeline Scripts

### Bake PBR Textures

```bash
blender -b MODEL.blend --python scripts/bake_pbr.py -- \
  --object "OBJECT_NAME" \
  --output OUTPUT_DIR \
  --resolution RESOLUTION
```

**Parameters:**
- `--object` - Name of object to bake (required)
- `--output` - Output directory (required)
- `--resolution` - Texture size: 1024, 2048, 4096 (default: 2048)

**Output:** ColorMap, NormalMap, RoughnessMap PNG files

### Export FBX

```bash
blender -b MODEL.blend --python scripts/export_fbx.py -- \
  --objects OBJ1 OBJ2 ... \
  --output OUTPUT.fbx
```

**Parameters:**
- `--objects` - Space-separated object names (required)
- `--output` - Output FBX path (required)
- `--skip-validation` - Skip transform application and validation

**Features:** Auto-applies transforms, validates mesh, Roblox-optimized

### Batch Render

```bash
blender -b SCENE.blend --python scripts/batch_render.py -- \
  --output OUTPUT_DIR \
  --engine ENGINE \
  --samples NUM \
  --resolution WIDTH HEIGHT \
  --start NUM \
  --end NUM \
  --step NUM
```

**Parameters:**
- `--output` - Output directory (required)
- `--engine` - CYCLES or EEVEE (default: CYCLES)
- `--samples` - Render samples (default: 128)
- `--resolution` - Width height (default: 1920 1080)
- `--start` - Start frame (default: scene setting)
- `--end` - End frame (default: scene setting)
- `--step` - Frame step (default: 1)
- `--frame` - Render single frame instead

## Roblox Integration

### FBX Import Checklist

- [ ] Model is UV unwrapped
- [ ] All transforms applied (scale = 1,1,1)
- [ ] No n-gons (faces with >4 vertices)
- [ ] Materials use Principled BSDF
- [ ] Armature included for rigged models

### SurfaceAppearance Properties

| Property | Description | Map Type |
|----------|-------------|----------|
| `ColorMap` | Base color/albedo | RGB |
| `NormalMap` | Surface detail | RGB (tangent space) |
| `RoughnessMap` | Surface roughness | Grayscale |
| `MetalnessMap` | Metallic areas | Grayscale |

**Format:** `rbxassetid://ASSET_ID`

## Performance Tips

### Preview Renders (Fast)

```bash
# Low samples, lower resolution
blender -b file.blend --python scripts/batch_render.py -- \
  --output preview \
  --engine EEVEE \
  --samples 32 \
  --resolution 1280 720
```

### Production Renders (Quality)

```bash
# High samples, full resolution
blender -b file.blend --python scripts/batch_render.py -- \
  --output production \
  --engine CYCLES \
  --samples 256 \
  --resolution 1920 1080
```

### Test Single Frame

```bash
blender -b file.blend -f 1 -o /tmp/test -F PNG
open /tmp/test0001.png
```

## File Paths

### Relative Paths

Use `//` for paths relative to .blend file:

```bash
-o //renders/frame_####
```

Expands to: `[blend_directory]/renders/frame_0001.png`

### Frame Numbering

Use `#` for frame number padding:

| Pattern | Result |
|---------|--------|
| `frame_#` | `frame_1` |
| `frame_####` | `frame_0001` |
| `frame_######` | `frame_000001` |

## Environment Variables

```bash
# Set Blender temporary directory
export TEMP=/custom/tmp

# Set number of threads
export BLENDER_THREADS=8

# Enable GPU rendering (if available)
export CYCLES_DEVICE=GPU
```

## Troubleshooting

### Common Issues

**"Python: command not found"**
```bash
# Use full Blender path
/opt/homebrew/bin/blender -b file.blend --python script.py
```

**"Blender is already running"**
```bash
# Kill existing processes
pkill -9 blender
```

**"Out of memory"**
```bash
# Reduce tile size in Cycles
# Add to your Python script:
bpy.context.scene.cycles.tile_size = 256
```

**"GPU not detected"**
```bash
# Check GPU devices
blender -b --python-expr "import bpy; print(bpy.context.preferences.addons['cycles'].preferences.devices)"
```

## Keyboard Shortcuts (GUI)

When testing in Blender GUI:

| Key | Action |
|-----|--------|
| `Ctrl+A` | Apply transforms |
| `U` | UV mapping menu |
| `F12` | Render image |
| `Ctrl+F12` | Render animation |
| `Tab` | Edit/Object mode toggle |
| `Alt+A` | Play animation |

## Python API Quick Reference

```python
import bpy

# Scene
scene = bpy.context.scene
scene.frame_start = 1
scene.frame_end = 250

# Objects
obj = bpy.data.objects["ObjectName"]
obj.select_set(True)
bpy.context.view_layer.objects.active = obj

# Render
scene.render.engine = 'CYCLES'
scene.cycles.samples = 128
scene.render.filepath = "/path/to/output"
bpy.ops.render.render(write_still=True)

# Materials
mat = obj.material_slots[0].material
nodes = mat.node_tree.nodes
principled = nodes["Principled BSDF"]
```

## Resources

- **Blender Docs:** https://docs.blender.org/manual/
- **Python API:** https://docs.blender.org/api/
- **Roblox Docs:** https://create.roblox.com/docs/
- **This Project:** See `docs/USAGE.md` and `docs/EXAMPLES.md`
