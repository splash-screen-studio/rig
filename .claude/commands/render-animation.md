# Render Animation

You are helping render a Blender animation using the CLI.

Ask the user for:
1. Input .blend file path
2. Start and end frames
3. Output directory
4. Render engine (CYCLES or EEVEE)
5. Output format (PNG, JPEG, EXR)

Then execute the appropriate blender command with:
- `-b` for background mode
- `-E` for render engine
- `-s` and `-e` for frame range
- `-o` for output path
- `-F` for format
- `-a` to render animation

Example:
```bash
blender -b assets/scene.blend -E CYCLES -s 1 -e 250 -o //renders/frame_#### -F PNG -a
```

After rendering, report:
- Number of frames rendered
- Output location
- Any errors or warnings
