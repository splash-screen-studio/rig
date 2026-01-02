# Professional 3D Animation Rig Pipeline

A world-class, headless 3D animation pipeline for Blender → Roblox workflows with PBR support.

## Overview

This project provides CLI-based automation for:
- Headless Blender rendering
- Automated rigging and animation
- PBR texture baking
- FBX export optimization
- Roblox Studio integration

## Tech Stack

- **Blender** (latest) - Free, open-source 3D creation suite
- **Python 3.x** - Blender scripting and automation
- **BlenderProc** - Professional pipeline framework
- **Roblox Studio** - Target platform

## Quick Start

### Prerequisites

```bash
# Install Blender (macOS)
brew install --cask blender

# Install Python dependencies
pip install -r requirements.txt
```

### Render Animation (Headless)

```bash
blender -b assets/scene.blend -E CYCLES -s 1 -e 250 -o //renders/frame_#### -F PNG -a
```

### Run Custom Pipeline

```bash
python scripts/bake_pbr.py --input assets/model.blend --output exports/
```

## Project Structure

```
rig/
├── assets/          # Source .blend files
├── scripts/         # Python automation scripts
│   ├── bake_pbr.py
│   ├── export_fbx.py
│   └── batch_render.py
├── exports/         # Generated FBX and textures
├── renders/         # Animation frames
├── roblox/          # Roblox Studio integration
└── docs/            # Documentation
```

## Blender → Roblox Workflow

1. **Model in Blender**: Create geometry, rig, animate
2. **UV Unwrap**: Essential for PBR textures
3. **Bake PBR Maps**: Run `python scripts/bake_pbr.py`
4. **Export FBX**: Run `python scripts/export_fbx.py`
5. **Import to Roblox**: Load FBX, add SurfaceAppearance
6. **Upload Textures**: Asset Manager → paste texture IDs

## Best Practices

- Always UV unwrap before baking
- Use Cycles render engine for PBR
- Apply all transforms before export (Ctrl+A)
- Validate mesh topology (no n-gons)
- Keep texture resolution power-of-2 (1024, 2048, 4096)

## Resources

- [Blender CLI Docs](https://docs.blender.org/manual/en/latest/advanced/command_line/render.html)
- [Roblox Export Requirements](https://create.roblox.com/docs/art/modeling/export-requirements)
- [PBR Texture Workflow](https://devforum.roblox.com/t/export-pbr-textures-from-blender-water/1175137)