#!/usr/bin/env python3
"""
Fix color management for vibrant colors in Blender 5.0.
Based on 2025 research findings.
"""

import bpy

def fix_color_management():
    """Fix color management settings for vibrant colors."""

    scene = bpy.context.scene

    # Key fix: Change View Transform from Filmic to Standard
    # This prevents color washing in Blender 5.0
    scene.view_settings.view_transform = 'Standard'

    # Set display device
    scene.display_settings.display_device = 'sRGB'

    # Working color space (new in Blender 5.0)
    # Use Linear Rec.709 for standard work, or Rec.2020 for wider gamut
    scene.sequencer_colorspace_settings.name = 'Linear Rec.709'

    print("✓ Color management fixed:")
    print(f"  View Transform: {scene.view_settings.view_transform}")
    print(f"  Display Device: {scene.display_settings.display_device}")
    print(f"  Look: {scene.view_settings.look}")

def reduce_environment_lighting():
    """Reduce environment lighting that washes out colors."""
    world = bpy.data.worlds.get('World')
    if world and world.node_tree:
        bg = world.node_tree.nodes.get('Background')
        if bg:
            # Reduce strength significantly
            bg.inputs['Strength'].default_value = 0.3
            print("✓ Reduced environment lighting strength to 0.3")

def main():
    """Apply all color fixes."""
    print("Applying Blender 5.0 color management fixes...")

    fix_color_management()
    reduce_environment_lighting()

    # Save
    bpy.ops.wm.save_mainfile()

    print("\n✓ Color fixes applied!")
    print("  Colors should now appear vibrant and saturated")

if __name__ == "__main__":
    main()
