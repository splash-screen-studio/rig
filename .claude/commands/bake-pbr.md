# Bake PBR Textures

You are helping bake PBR textures from Blender for Roblox export.

Ask the user for:
1. Input .blend file path
2. Object name to bake
3. Texture resolution (1024, 2048, 4096)
4. Output directory

Required PBR maps for Roblox:
- ColorMap (Base Color/Albedo)
- NormalMap
- RoughnessMap
- MetalnessMap

Steps:
1. Verify UV unwrapping exists
2. Switch to Cycles render engine
3. Bake each map type individually
4. Save as PNG files
5. Verify output quality

Generate a Python script to run with:
```bash
blender -b input.blend --python scripts/bake_pbr.py
```

The script should:
- Select the specified object
- Create image nodes for each map type
- Bake using Cycles
- Save to output directory with proper naming
