# Example Workflows

Real-world examples for the 3D animation pipeline.

## Example 1: Character Model for Roblox

Complete workflow from Blender modeling to Roblox import.

### Step 1: Create and Rig in Blender

1. Model your character in Blender
2. UV unwrap: `Select all → U → Smart UV Project`
3. Create PBR materials using Principled BSDF
4. Rig with armature
5. Animate
6. Save as `assets/character.blend`

### Step 2: Bake PBR Textures

```bash
blender -b assets/character.blend --python scripts/bake_pbr.py -- \
  --object "CharacterMesh" \
  --output exports/character_pbr \
  --resolution 2048
```

Output:
```
exports/character_pbr/
├── CharacterMesh_ColorMap.png
├── CharacterMesh_NormalMap.png
└── CharacterMesh_RoughnessMap.png
```

### Step 3: Export to FBX

```bash
blender -b assets/character.blend --python scripts/export_fbx.py -- \
  --objects "CharacterMesh" "Armature" \
  --output exports/character.fbx
```

### Step 4: Import to Roblox

1. Open Roblox Studio
2. **Avatar → Import 3D** → Select `character.fbx`
3. For the MeshPart, insert **SurfaceAppearance**
4. Upload textures to Roblox:
   - Asset Manager → Create → Image
   - Upload each PNG file
   - Copy the asset IDs

5. Configure SurfaceAppearance:
   ```lua
   SurfaceAppearance.ColorMap = "rbxassetid://123456789"
   SurfaceAppearance.NormalMap = "rbxassetid://123456790"
   SurfaceAppearance.RoughnessMap = "rbxassetid://123456791"
   ```

---

## Example 2: Animated Environment Asset

Render an animated environment piece.

### Render Preview (Fast)

```bash
blender -b assets/environment.blend --python scripts/batch_render.py -- \
  --output renders/preview \
  --engine EEVEE \
  --samples 32 \
  --resolution 1280 720 \
  --start 1 \
  --end 120
```

### Render Production (High Quality)

```bash
blender -b assets/environment.blend --python scripts/batch_render.py -- \
  --output renders/production \
  --engine CYCLES \
  --samples 256 \
  --resolution 1920 1080 \
  --start 1 \
  --end 120
```

---

## Example 3: Weapon with PBR Materials

### Complete Pipeline

```bash
# 1. Bake PBR textures
blender -b assets/sword.blend --python scripts/bake_pbr.py -- \
  --object "Sword" \
  --output exports/sword_textures \
  --resolution 4096

# 2. Export FBX
blender -b assets/sword.blend --python scripts/export_fbx.py -- \
  --objects "Sword" \
  --output exports/sword.fbx

# 3. Render beauty shot
blender -b assets/sword.blend --python scripts/batch_render.py -- \
  --output renders/sword_beauty \
  --frame 1 \
  --engine CYCLES \
  --samples 512 \
  --resolution 2048 2048
```

---

## Example 4: Batch Processing Multiple Assets

Process all models in a directory:

```bash
#!/bin/bash

for model in assets/*.blend; do
  name=$(basename "$model" .blend)
  echo "Processing $name..."

  # Bake textures
  blender -b "$model" --python scripts/bake_pbr.py -- \
    --object "Mesh" \
    --output "exports/${name}_textures" \
    --resolution 2048

  # Export FBX
  blender -b "$model" --python scripts/export_fbx.py -- \
    --objects "Mesh" \
    --output "exports/${name}.fbx"

  echo "✓ $name complete"
done

echo "All assets processed!"
```

Save as `batch_process.sh`, make executable with `chmod +x batch_process.sh`, then run `./batch_process.sh`.

---

## Example 5: Animation Turntable

Create a 360° turntable animation for showcasing models.

### Blender Python Script

Save as `scripts/create_turntable.py`:

```python
import bpy
import math

# Setup
scene = bpy.context.scene
obj = bpy.data.objects["YourModelName"]

# Create camera rotation
camera = bpy.data.objects["Camera"]
radius = 5
height = 2

for frame in range(1, 361):
    scene.frame_set(frame)
    angle = math.radians(frame)

    camera.location.x = radius * math.cos(angle)
    camera.location.y = radius * math.sin(angle)
    camera.location.z = height

    # Point camera at object
    direction = obj.location - camera.location
    camera.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()

    # Insert keyframe
    camera.keyframe_insert(data_path="location", frame=frame)
    camera.keyframe_insert(data_path="rotation_euler", frame=frame)
```

### Render Turntable

```bash
blender -b assets/model.blend \
  --python scripts/create_turntable.py \
  --python scripts/batch_render.py -- \
  --output renders/turntable \
  --engine CYCLES \
  --samples 128 \
  --start 1 \
  --end 360
```

---

## Example 6: Headless Testing

Test renders without saving:

```bash
# Render single frame to /tmp for quick testing
blender -b assets/scene.blend -f 1 -o /tmp/test -F PNG
```

View the test render:

```bash
open /tmp/test0001.png
```

---

## Example 7: Automated CI/CD Pipeline

GitHub Actions example for automated rendering:

`.github/workflows/render.yml`:

```yaml
name: Render Animations

on:
  push:
    paths:
      - 'assets/*.blend'

jobs:
  render:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v3

      - name: Install Blender
        run: brew install --cask blender

      - name: Render Animation
        run: |
          blender -b assets/scene.blend --python scripts/batch_render.py -- \
            --output renders/output \
            --engine CYCLES \
            --samples 128

      - name: Upload Renders
        uses: actions/upload-artifact@v3
        with:
          name: rendered-frames
          path: renders/
```

---

## Tips & Tricks

### Faster Iteration

1. **Preview every 10th frame:**
   ```bash
   blender -b file.blend -s 1 -e 100 -j 10 -a
   ```

2. **Lower resolution preview:**
   ```bash
   blender -b file.blend -o //preview/#### -F JPEG -a -p 50
   ```
   (`-p 50` = 50% resolution)

### Memory Management

For large scenes, enable progressive rendering:

```python
scene.cycles.use_progressive_refine = True
```

### GPU Rendering

Verify GPU is being used:

```bash
blender -b --python-expr "import bpy; print(bpy.context.preferences.addons['cycles'].preferences.compute_device_type)"
```

### Network Rendering

Render different frame ranges on different machines:

```bash
# Machine 1: frames 1-100
blender -b scene.blend -s 1 -e 100 -a

# Machine 2: frames 101-200
blender -b scene.blend -s 101 -e 200 -a

# Machine 3: frames 201-300
blender -b scene.blend -s 201 -e 300 -a
```

Then combine the rendered frames.
