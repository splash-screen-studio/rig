#!/usr/bin/env python3
"""
Create a colorful bouncing ball scene.
Simple demonstration of the animation workflow.
"""

import bpy
import math

def clear_scene():
    """Remove default objects."""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

def create_bouncing_ball():
    """Create a colorful ball."""
    # Ball
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.5,
        location=(0, 0, 2),
        segments=64,
        ring_count=32
    )
    ball = bpy.context.active_object
    ball.name = "Ball"
    bpy.ops.object.shade_smooth()

    # Vibrant material
    mat = bpy.data.materials.new(name="BallMaterial")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]

    # Bright orange/red color
    bsdf.inputs['Base Color'].default_value = (1.0, 0.3, 0.1, 1)
    bsdf.inputs['Metallic'].default_value = 0.2
    bsdf.inputs['Roughness'].default_value = 0.3
    bsdf.inputs['Specular IOR Level'].default_value = 0.8

    ball.data.materials.append(mat)

    print("✓ Ball created!")
    return ball

def setup_scene():
    """Set up lighting, camera, and environment."""
    # Ground plane
    bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0, 0))
    ground = bpy.context.active_object
    ground.name = "Ground"

    # Ground material
    mat = bpy.data.materials.new(name="GroundMaterial")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs['Base Color'].default_value = (0.2, 0.6, 0.9, 1)  # Blue
    bsdf.inputs['Roughness'].default_value = 0.8
    ground.data.materials.append(mat)

    # Camera
    bpy.ops.object.camera_add(location=(8, -8, 4))
    camera = bpy.context.active_object
    camera.rotation_euler = (math.radians(70), 0, math.radians(45))
    bpy.context.scene.camera = camera

    # Sun light
    bpy.ops.object.light_add(type='SUN', location=(5, 5, 10))
    sun = bpy.context.active_object
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(45), math.radians(30), 0)

    # Fill light
    bpy.ops.object.light_add(type='AREA', location=(-4, -4, 5))
    fill = bpy.context.active_object
    fill.data.energy = 200
    fill.data.size = 5

    # World (gradient sky)
    world = bpy.data.worlds['World']
    world.use_nodes = True
    bg = world.node_tree.nodes['Background']
    bg.inputs['Color'].default_value = (0.6, 0.8, 1.0, 1.0)
    bg.inputs['Strength'].default_value = 1.2

    print("✓ Scene setup complete!")

def main():
    """Main function."""
    print("Creating bouncing ball scene...")

    clear_scene()
    ball = create_bouncing_ball()
    setup_scene()

    # Save
    output_path = "/Users/bedwards/rig/assets/bouncing_ball.blend"
    bpy.ops.wm.save_as_mainfile(filepath=output_path)

    print(f"\n✓ Scene saved to: {output_path}")
    print("\nNext: Run animation script to add bounce!")

if __name__ == "__main__":
    main()
