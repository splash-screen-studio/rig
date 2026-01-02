# Claude Code Workflow Guide

This document explains how Claude Code works with this 3D animation pipeline.

## Project Goal

**Get an animated baby camel into Roblox** - a kids' game with vibrant, fun colors.

## Subsystem Versions

| Subsystem | Version | Description |
|-----------|---------|-------------|
| animate.sh | 1.2.0 | Unified CLI with deploy command |
| create_baby_camel.py | 1.0.0 | Procedural baby camel model |
| animate_baby_camel_walk.py | 1.0.0 | Walk cycle animation |
| export_fbx.py | 1.1.0 | FBX export with auto-detect |
| upload_to_roblox.py | 1.0.0 | Upload FBX + textures to Cloud |
| CamelSetup.luau | 1.2.0 | MCP walk - moves ALL parts together |
| MCP Explorer | 1.0.0 | Workspace exploration via MCP |
| Rojo Config | 1.0.0 | Default project structure |

**Rule: Bump version with every change to a subsystem.**

## Debugging Rules

### NEVER Remove Code When Debugging
- **DO:** Add more logging, wrap in conditionals, comment out temporarily
- **DON'T:** Delete functionality, remove features, regress behavior

### Always Add Logging
```python
# Python
print(f"[DEBUG v1.0.0] Processing {obj.name}...")
```
```lua
-- Luau
print("[DEBUG v1.0.0] Loading camel model...")
```

### Version Everything
- Log version at startup of every script
- Include version in debug output
- Bump version on any change

## Code Quality Rules

### Single Source of Truth - No Magic Numbers
Calculate values from actual data, don't hardcode:

```lua
-- ❌ WRONG: Magic numbers
local OFFSET_UP = 3  -- Why 3? What if camel size changes?

-- ✅ CORRECT: Calculate from geometry
local lowestY = math.huge
for _, part in ipairs(model:GetChildren()) do
    if part:IsA("BasePart") then
        lowestY = math.min(lowestY, part.Position.Y - part.Size.Y/2)
    end
end
local bodyToGround = body.Position.Y - lowestY
local OFFSET_UP = bodyToGround + 0.1  -- Calculated + small clearance
```

Benefits:
- Works if model size changes
- Self-documenting (shows intent)
- Single source of truth (geometry)
- Logs actual values for debugging

## Overview

This project uses a unified CLI workflow (`animate.sh`) that allows Claude Code to:
1. Create 3D scenes procedurally with Python
2. Apply animations
3. Render to PNG frames
4. Generate MP4 videos
5. **Read and verify frames** using the Read tool

## The Workflow Script

### `./animate.sh` - Unified CLI Tool

The master script orchestrates the entire animation pipeline.

**Core Commands:**
```bash
./animate.sh create <name>       # Create scene
./animate.sh animate <name>      # Apply animation
./animate.sh render <name>       # Render frames
./animate.sh video <name>        # Generate MP4
./animate.sh full <name>         # Complete workflow
./animate.sh verify <name> [N]   # List frames for Claude to read
./animate.sh clean <name>        # Clean up renders
```

**Options:**
```bash
--engine <ENGINE>           # EEVEE (fast) or CYCLES (quality)
--samples <N>               # Render samples (default: 64)
--fps <N>                   # Frames per second (default: 24)
--start <N> --end <N>       # Frame range
--resolution <W> <H>        # Output resolution
--force                     # Overwrite existing files
--no-video                  # Skip video generation
```

## Claude Code Workflow Pattern

### Pattern: Create & Verify Animation

**Step 1: Create the animation**
```bash
./animate.sh full baby_camel --samples 64
```

**Step 2: Verify with Claude**
```bash
./animate.sh verify baby_camel 10
```

This outputs a list of frame paths (every 10th frame). Claude can then use the **Read tool** to view each frame and verify:
- All body parts moving together
- No separation/stretching bugs
- Animation looks correct
- Quality is acceptable

**Step 3: Iterate if needed**
If Claude finds bugs:
1. Fix the Python animation script
2. Re-run: `./animate.sh full baby_camel --force`
3. Verify again: `./animate.sh verify baby_camel 10`
4. Repeat until all P0 bugs resolved

### Pattern: High Quality Final Render

After verification passes:
```bash
./animate.sh render baby_camel \
  --engine CYCLES \
  --samples 256 \
  --resolution 2560 1440 \
  --force

./animate.sh video baby_camel
```

## How Claude Reads Frames

Claude Code's **Read tool** can read images directly. This enables:

1. **Visual verification** - Claude sees exactly what the user sees
2. **Bug detection** - Claude can spot animation issues (separation, clipping, etc.)
3. **Quality assessment** - Claude can evaluate render quality
4. **Frame-by-frame analysis** - Compare sequential frames for smooth motion

### Example Verification Flow

```bash
# After rendering
$ ./animate.sh verify baby_camel 15

# Output:
renders/baby_camel/frame_0001.png
renders/baby_camel/frame_0015.png
renders/baby_camel/frame_0030.png
renders/baby_camel/frame_0045.png
renders/baby_camel/frame_0060.png
```

Claude then uses the Read tool on each path to visually inspect frames.

## Project Structure

```
rig/
├── animate.sh              # Master workflow script (USE THIS!)
├── default.project.json    # Rojo config (use defaults, just run `rojo serve`)
├── .env                    # API keys (git ignored)
├── assets/                 # Source .blend files (git ignored)
├── exports/                # FBX exports for Roblox
├── scripts/
│   ├── create_*.py        # Scene creation scripts
│   ├── animate_*_walk.py  # Animation scripts
│   ├── bake_pbr.py        # PBR texture baking
│   ├── export_fbx.py      # FBX export for Roblox
│   └── batch_render.py    # Headless rendering
├── src/
│   ├── server/            # ServerScriptService (Rojo synced)
│   ├── client/            # StarterPlayerScripts (Rojo synced)
│   └── shared/            # ReplicatedStorage (Rojo synced)
├── renders/               # Output frames & videos (git ignored)
├── docs/                  # Documentation
└── CLAUDE.md             # This file
```

## Creating New Animations

### 1. Create Scene Script

`scripts/create_my_model.py`:
```python
import bpy

def create_model():
    # Create your 3D model here
    pass

def main():
    create_model()
    bpy.ops.wm.save_as_mainfile(filepath="assets/my_model.blend")

if __name__ == "__main__":
    main()
```

### 2. Create Animation Script

`scripts/animate_my_model_walk.py`:
```python
import bpy
import math

def create_walk_cycle():
    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = 60

    # Get all objects that need animation
    body = bpy.data.objects.get("Body")

    for frame in range(1, 61):
        scene.frame_set(frame)
        forward_offset = (frame / 60.0) * 3.0

        # IMPORTANT: Animate ALL objects' X position!
        # Missing even one object causes separation bugs
        if body:
            body.location.x = forward_offset
            body.keyframe_insert(data_path="location", frame=frame)

        # ... animate other parts ...

def main():
    create_walk_cycle()
    bpy.ops.wm.save_mainfile()

if __name__ == "__main__":
    main()
```

### 3. Run the Workflow

```bash
./animate.sh full my_model --samples 64
./animate.sh verify my_model 10
```

## Common Patterns

### Quick Preview
```bash
./animate.sh render my_scene \
  --engine EEVEE \
  --samples 32 \
  --end 30 \
  --force
```

### Production Quality
```bash
./animate.sh render my_scene \
  --engine CYCLES \
  --samples 256 \
  --resolution 3840 2160 \
  --force
```

### Test Single Frame
```bash
./animate.sh render my_scene \
  --start 30 \
  --end 30 \
  --no-video
```

### Batch Verification
```bash
# Check every 5th frame
./animate.sh verify my_scene 5 > frames_to_check.txt

# Claude reads each frame listed
```

## Critical Animation Bug Classes

### P0: Body Parts Left Behind

**Symptom:** Body parts stay at original position while others move forward

**Cause:** Forgetting to animate X position for some objects

**Fix:** Ensure EVERY object has `location.x = base_x + forward_offset`

**Detection:** Use `verify` command - Claude compares frames to spot separation

### Example Bug Fix Pattern

```python
# ❌ WRONG - only animates Z (height)
leg.location.z = 0.5 + lift
leg.keyframe_insert(data_path="location", frame=frame)

# ✅ CORRECT - animates both X (forward) and Z (height)
leg.location.x = base_x + forward_offset + swing
leg.location.z = 0.5 + lift
leg.keyframe_insert(data_path="location", frame=frame)
```

## Environment Variables

```bash
# Custom Blender path
export BLENDER_BIN=/opt/homebrew/bin/blender

# Then use normally
./animate.sh full my_scene
```

## Integration with Other Tools

### Export to Roblox
```bash
# After animation verified
blender -b assets/my_model.blend --python scripts/bake_pbr.py -- \
  --object "Body" \
  --output exports/textures \
  --resolution 2048

blender -b assets/my_model.blend --python scripts/export_fbx.py -- \
  --objects "Body" "Armature" \
  --output exports/my_model.fbx
```

### Git Workflow
```bash
# Renders are git ignored automatically
./animate.sh full my_scene

# Only commit source files
git add scripts/create_my_scene.py
git add scripts/animate_my_scene_walk.py
git commit -m "Add my_scene animation"
```

## Tips for Working with Claude Code

1. **Always verify after rendering** - Use `verify` command and let Claude read frames
2. **Start with low samples** - Use EEVEE with 32-64 samples for iteration
3. **Increment verification interval** - Use `verify <name> 15` for faster checks
4. **Use --force liberally** - Don't hesitate to re-render during iteration
5. **Test single frames first** - Use `--start 1 --end 1` to test quickly

## Troubleshooting

### "Scene file not found"
Run `create` command first: `./animate.sh create my_scene`

### "Animation script not found"
Create `scripts/animate_my_scene_walk.py` following the pattern above

### "Frames directory not found"
Run `render` command first: `./animate.sh render my_scene`

### Separation bugs after rendering
1. Check animation script - ensure ALL objects have X animation
2. List all objects in scene: `blender -b assets/scene.blend --python-expr "import bpy; print([o.name for o in bpy.data.objects])"`
3. Add missing objects to animation loop

## Best Practices

✅ **DO:**
- Use `full` command for complete workflow
- Verify with Claude before final high-quality render
- Start with low samples (32-64) for iteration
- Use descriptive scene names
- Clean up old renders with `clean` command

❌ **DON'T:**
- Skip verification step
- Commit render files to git (they're ignored)
- Use high samples during iteration
- Forget to animate all object positions
- Hard-code file paths in scripts

## Roblox Integration

### Installed Toolset (Mac)

| Tool | Version | Purpose |
|------|---------|---------|
| **rbxcloud** | 0.17.0 | Roblox Open Cloud CLI (assets, datastores, Luau execution) |
| **rojo** | 7.7.0-rc.1 | Sync files between Studio and filesystem |
| **lune** | 0.10.4 | Standalone Luau runtime for testing |
| **run-in-roblox** | 0.3.0 | Execute scripts in Studio from CLI |
| **StyLua** | 2.0.2 | Luau code formatter |
| **selene** | 0.28.0 | Luau linter |
| **wally** | 0.3.2 | Roblox package manager |
| **remodel** | 0.11.0 | Roblox file manipulation |
| **tarmac** | 0.8.2 | Asset management |
| **MCP Server** | Custom | Low-CPU Rust fork for Claude ↔ Studio |

### MCP Server Tools

Claude Code has direct access to Roblox Studio via MCP:

```
mcp__roblox-studio__run_code    # Execute Luau code in Studio
mcp__roblox-studio__insert_model # Insert marketplace models
```

### Primary Workflow: Create Directly via MCP

**MCP is the primary approach** - more reliable than Cloud upload, instant results, no timeouts.

```lua
-- Claude creates models directly in Studio via MCP
-- No FBX export, no Cloud upload, no manual steps!

local camel = Instance.new("Model")
camel.Name = "BabyCamel"

local body = Instance.new("Part")
body.Size = Vector3.new(3, 1.5, 2)
body.Color = Color3.fromRGB(255, 140, 0)  -- Vibrant orange
body.Material = Enum.Material.Neon        -- Glowing!
body.Parent = camel

-- ... create all parts via MCP
camel.Parent = workspace
```

**Why MCP over Blender FBX:**
- Instant - no upload timeouts
- Reliable - no Cloud API issues
- Controllable - adjust colors/sizes in real-time
- Animated - direct position changes in loops

**MCP Caveats:**

1. ❌ `TweenService` does NOT work (Command Bar doesn't update tweens)
2. ❌ `WeldConstraints` don't follow when you set `Position` directly (bypasses physics)
3. ✅ Must move ALL parts together in the loop
4. ⚠️ `RunService:IsRunning()` always returns `false` - MCP runs in Command Bar context which is always Edit mode, even when Play mode is active

```lua
-- WRONG: Only moves body, other parts left behind!
body.Position = Vector3.new(10, 3, 0)

-- CORRECT: Move ALL parts together
local offsets = {}
for _, part in ipairs(model:GetChildren()) do
    if part:IsA("BasePart") and part ~= body then
        offsets[part] = part.Position - body.Position
    end
end

body.Position = newPos
for part, offset in pairs(offsets) do
    part.Position = newPos + offset
end
```

### Legacy: Blender FBX Workflow (Optional)

For complex organic models that need Blender's sculpting:
```bash
./animate.sh export baby_camel    # Export FBX
# Then use Studio's File > Import 3D manually
```

### rbxcloud Commands

```bash
# Upload FBX model
rbxcloud assets create model-fbx <file> --api-key $ROBLOX_API_KEY

# Upload texture
rbxcloud assets create decal-png <file> --api-key $ROBLOX_API_KEY

# Execute Luau in cloud
rbxcloud luau execute <script.luau> \
  --universe-id $ROBLOX_EXPERIENCE_ID \
  --place-id $ROBLOX_PLACE_ID \
  --api-key $ROBLOX_API_KEY
```

### Environment Variables (.env)

```bash
ROBLOX_API_KEY=<your-key>
ROBLOX_EXPERIENCE_ID=9490082627
ROBLOX_PLACE_ID=98594852978811
```

## Rojo Workflow

### Setup (Already Done)
```bash
rojo init        # Creates default.project.json
rojo serve       # Start sync server (no args needed)
```

### In Roblox Studio
1. Install Rojo plugin
2. Click "Connect" in plugin toolbar
3. Studio auto-syncs with `src/` folder

### File Structure (Rojo Default)
```
src/server/init.server.luau  → ServerScriptService.Server
src/client/init.client.luau  → StarterPlayerScripts.Client
src/shared/*.luau            → ReplicatedStorage.Shared
```

### Adding New Scripts
```bash
# Server script
echo 'print("Hello from server")' > src/server/MyScript.server.luau

# Client script
echo 'print("Hello from client")' > src/client/MyScript.client.luau

# Shared module
echo 'return {}' > src/shared/MyModule.luau
```

## MCP Workflow

### Explore Workspace
```lua
-- Claude runs via MCP to see Studio state
for _, child in ipairs(game.Workspace:GetChildren()) do
    print(child.Name .. " (" .. child.ClassName .. ")")
end
```

### Read Studio Output
Claude uses MCP `run_code` to execute Luau and read printed output.

### Edit vs Play Mode
**Claude will ask user to switch modes when needed:**
- **Edit Mode**: For modifying workspace, inserting models
- **Play Mode**: For testing scripts, runtime behavior

### Create Objects via MCP
```lua
local part = Instance.new("Part")
part.Name = "CamelFromBlender"
part.Parent = workspace
print("Created: " .. part.Name)
```

## Version History

- **v0.1.0** (2026-01-02): Initial workflow - baby camel animation
- **v0.2.0** (2026-01-02): Roblox integration
  - Added rbxcloud upload commands
  - MCP server connection verified
  - Rojo project initialized
  - Debugging rules documented
  - Subsystem versioning added
- **v0.3.0** (2026-01-02): Automated deploy pipeline
  - `./animate.sh deploy` - one command export + bake + upload
  - `upload_to_roblox.py` - automated asset upload
  - `CamelSetup.luau` - MCP helper for SurfaceAppearance
  - No more manual texture upload steps!
