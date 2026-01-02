#!/usr/bin/env python3
"""
FBX Export Automation for Roblox
Exports Blender objects to FBX with proper settings for Roblox Studio.
"""

import bpy
import sys
import argparse
from pathlib import Path


def apply_transforms(obj):
    """Apply all transforms (location, rotation, scale)."""
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    print(f"✓ Applied transforms to '{obj.name}'")


def validate_mesh(obj):
    """Validate mesh is ready for export."""
    if obj.type != 'MESH':
        raise ValueError(f"Object '{obj.name}' is not a mesh")

    mesh = obj.data

    # Check for UV map
    if not mesh.uv_layers:
        print(f"⚠ Warning: '{obj.name}' has no UV map")

    # Check for n-gons
    has_ngons = any(len(poly.vertices) > 4 for poly in mesh.polygons)
    if has_ngons:
        print(f"⚠ Warning: '{obj.name}' contains n-gons (faces with >4 vertices)")

    # Check scale
    if obj.scale != (1.0, 1.0, 1.0):
        print(f"⚠ Warning: '{obj.name}' has unapplied scale: {obj.scale}")
        return False

    return True


def export_to_fbx(objects, output_path, apply_modifiers=True):
    """Export selected objects to FBX with Roblox-compatible settings."""
    output_file = Path(output_path)
    output_file.parent.mkdir(parents=True, exist_ok=True)

    # Select objects for export
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:
        obj.select_set(True)

    # FBX Export settings optimized for Roblox
    bpy.ops.export_scene.fbx(
        filepath=str(output_file),
        use_selection=True,

        # Transform settings
        global_scale=1.0,
        apply_scale_options='FBX_SCALE_ALL',
        axis_forward='-Z',
        axis_up='Y',

        # Object types
        object_types={'MESH', 'ARMATURE'},
        use_mesh_modifiers=apply_modifiers,

        # Mesh settings
        mesh_smooth_type='FACE',
        use_mesh_edges=False,
        use_tspace=True,  # Tangent space for normal maps

        # Animation
        bake_anim=True,
        bake_anim_use_all_bones=True,
        bake_anim_use_nla_strips=False,
        bake_anim_use_all_actions=False,

        # Advanced
        path_mode='AUTO',
        embed_textures=False,
        batch_mode='OFF'
    )

    print(f"\n✓ Exported to: {output_file}")
    print(f"  Objects: {len(objects)}")
    print(f"  Format: FBX")


def export_workflow(object_names, output_path, skip_validation=False):
    """Complete export workflow with validation."""
    objects = []

    # If no object names specified, export all meshes and armatures
    if object_names is None:
        print("Auto-detecting objects to export...")
        for obj in bpy.data.objects:
            if obj.type in ('MESH', 'ARMATURE'):
                objects.append(obj)
                print(f"  + {obj.name} ({obj.type})")
        if not objects:
            raise ValueError("No meshes or armatures found in scene")
    else:
        # Collect and validate specified objects
        for obj_name in object_names:
            obj = bpy.data.objects.get(obj_name)

            if obj is None:
                raise ValueError(f"Object '{obj_name}' not found in scene")

            objects.append(obj)

    # Validate and apply transforms
    if not skip_validation:
        for obj in objects:
            if obj.type == 'MESH':
                apply_transforms(obj)
                validate_mesh(obj)

    # Export
    export_to_fbx(objects, output_path)

    print("\nNext steps:")
    print("1. Open Roblox Studio")
    print("2. Use 'Import 3D' to load the FBX file")
    print("3. For each MeshPart, insert a SurfaceAppearance object as child")
    print("4. Upload PBR textures via Asset Manager")
    print("5. Paste texture asset IDs into SurfaceAppearance properties:")
    print("   - ColorMap")
    print("   - NormalMap")
    print("   - RoughnessMap")
    print("   - MetalnessMap")


def main():
    """Main entry point when run from CLI."""
    # Remove Blender args
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []

    parser = argparse.ArgumentParser(
        description="Export Blender objects to FBX for Roblox"
    )
    parser.add_argument(
        "--objects",
        nargs='+',
        default=None,
        help="Names of objects to export (default: all meshes)"
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Output FBX file path"
    )
    parser.add_argument(
        "--skip-validation",
        action='store_true',
        help="Skip validation and transform application"
    )

    args = parser.parse_args(argv)

    try:
        export_workflow(args.objects, args.output, args.skip_validation)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
