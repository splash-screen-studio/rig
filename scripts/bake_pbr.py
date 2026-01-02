#!/usr/bin/env python3
"""
PBR Texture Baking Automation for Roblox Export
Bakes Color, Normal, Roughness, and Metalness maps from Blender materials.
"""

import bpy
import sys
import os
import argparse
from pathlib import Path


def setup_bake_settings(resolution=2048):
    """Configure Cycles bake settings."""
    bpy.context.scene.render.engine = 'CYCLES'
    bpy.context.scene.cycles.device = 'GPU'
    bpy.context.scene.cycles.samples = 128
    bpy.context.scene.render.bake.use_pass_direct = False
    bpy.context.scene.render.bake.use_pass_indirect = False


def create_image(name, resolution=2048):
    """Create a new image for baking."""
    img = bpy.data.images.new(name, width=resolution, height=resolution)
    img.use_generated_float = False
    img.generated_color = (0, 0, 0, 1)
    return img


def select_object(obj_name):
    """Select and make active the specified object."""
    bpy.ops.object.select_all(action='DESELECT')
    obj = bpy.data.objects.get(obj_name)

    if obj is None:
        raise ValueError(f"Object '{obj_name}' not found in scene")

    if obj.type != 'MESH':
        raise ValueError(f"Object '{obj_name}' is not a mesh")

    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

    # Check for UV map
    if not obj.data.uv_layers:
        raise ValueError(f"Object '{obj_name}' has no UV map. UV unwrap required!")

    return obj


def bake_map(bake_type, img, output_path):
    """Bake a specific map type."""
    print(f"Baking {bake_type}...")

    # Set active image in all material nodes
    obj = bpy.context.active_object
    for mat_slot in obj.material_slots:
        if mat_slot.material and mat_slot.material.node_tree:
            nodes = mat_slot.material.node_tree.nodes

            # Create temp image node for baking
            img_node = nodes.new('ShaderNodeTexImage')
            img_node.image = img
            img_node.select = True
            nodes.active = img_node

    # Bake
    bpy.ops.object.bake(type=bake_type)

    # Save image
    img.filepath_raw = output_path
    img.file_format = 'PNG'
    img.save()
    print(f"Saved: {output_path}")

    # Cleanup temp nodes
    for mat_slot in obj.material_slots:
        if mat_slot.material and mat_slot.material.node_tree:
            nodes = mat_slot.material.node_tree.nodes
            for node in nodes:
                if node.type == 'TEX_IMAGE' and node.image == img:
                    nodes.remove(node)


def bake_pbr_maps(obj_name, output_dir, resolution=2048):
    """Bake all PBR maps for Roblox."""
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # Setup
    setup_bake_settings(resolution)
    obj = select_object(obj_name)

    base_name = obj_name.replace(" ", "_")

    # Map configurations for Roblox
    maps = {
        'DIFFUSE': f"{base_name}_ColorMap.png",
        'NORMAL': f"{base_name}_NormalMap.png",
        'ROUGHNESS': f"{base_name}_RoughnessMap.png",
        # Note: Blender doesn't have direct metalness bake, use shader setup
    }

    for bake_type, filename in maps.items():
        img = create_image(f"{base_name}_{bake_type}", resolution)
        output_file = output_path / filename
        bake_map(bake_type, img, str(output_file))
        bpy.data.images.remove(img)

    print(f"\n✓ PBR baking complete for '{obj_name}'")
    print(f"  Output: {output_path}")
    print(f"  Maps: {len(maps)} textures @ {resolution}x{resolution}")
    print("\nNext steps:")
    print("1. Export model as FBX")
    print("2. Import FBX to Roblox Studio")
    print("3. Add SurfaceAppearance to MeshPart")
    print("4. Upload textures via Asset Manager")
    print("5. Paste texture IDs into SurfaceAppearance properties")


def main():
    """Main entry point when run from CLI."""
    # Remove Blender args
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []

    parser = argparse.ArgumentParser(
        description="Bake PBR textures from Blender for Roblox"
    )
    parser.add_argument(
        "--object",
        required=True,
        help="Name of object to bake"
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Output directory for textures"
    )
    parser.add_argument(
        "--resolution",
        type=int,
        default=2048,
        choices=[1024, 2048, 4096],
        help="Texture resolution (default: 2048)"
    )

    args = parser.parse_args(argv)

    try:
        bake_pbr_maps(args.object, args.output, args.resolution)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
