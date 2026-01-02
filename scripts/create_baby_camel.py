#!/usr/bin/env python3
"""
Create a cute baby camel model with procedural modeling.
Uses simple shapes to create an adorable baby camel.
"""

import bpy
import math
from mathutils import Vector

def clear_scene():
    """Remove default objects."""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

def create_baby_camel():
    """Create a cute baby camel using procedural modeling."""

    # Body (main torso) - scaled down for baby proportions
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.6, location=(0, 0, 1.2))
    body = bpy.context.active_object
    body.name = "Body"
    body.scale = (1.2, 0.8, 0.9)  # Elongated for torso
    bpy.ops.object.shade_smooth()

    # Neck
    bpy.ops.mesh.primitive_cylinder_add(radius=0.25, depth=0.8, location=(0.8, 0, 1.5))
    neck = bpy.context.active_object
    neck.name = "Neck"
    neck.rotation_euler = (0, math.radians(30), 0)  # Angled forward
    bpy.ops.object.shade_smooth()

    # Head (smaller for baby)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.35, location=(1.2, 0, 1.9))
    head = bpy.context.active_object
    head.name = "Head"
    head.scale = (1.0, 0.8, 0.9)
    bpy.ops.object.shade_smooth()

    # Snout
    bpy.ops.mesh.primitive_cylinder_add(radius=0.15, depth=0.3, location=(1.45, 0, 1.85))
    snout = bpy.context.active_object
    snout.name = "Snout"
    snout.rotation_euler = (0, math.radians(90), 0)
    bpy.ops.object.shade_smooth()

    # Eyes (big cute baby eyes!)
    for x_offset in [-0.15, 0.15]:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.1, location=(1.25, x_offset, 2.05))
        eye = bpy.context.active_object
        eye.name = f"Eye_{'L' if x_offset < 0 else 'R'}"
        bpy.ops.object.shade_smooth()

        # Create dark material for eyes
        mat = bpy.data.materials.new(name=f"EyeMaterial_{x_offset}")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes["Principled BSDF"]
        bsdf.inputs['Base Color'].default_value = (0.05, 0.05, 0.05, 1)
        bsdf.inputs['Roughness'].default_value = 0.2
        eye.data.materials.append(mat)

    # Ears (floppy baby ears)
    for y_offset in [-0.25, 0.25]:
        bpy.ops.mesh.primitive_cone_add(radius1=0.12, depth=0.3, location=(1.1, y_offset, 2.15))
        ear = bpy.context.active_object
        ear.name = f"Ear_{'L' if y_offset < 0 else 'R'}"
        ear.rotation_euler = (math.radians(-20), 0, math.radians(30) if y_offset < 0 else math.radians(-30))
        bpy.ops.object.shade_smooth()

    # Baby hump (single small hump)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.35, location=(-0.2, 0, 1.8))
    hump = bpy.context.active_object
    hump.name = "Hump"
    hump.scale = (0.7, 0.6, 0.8)
    bpy.ops.object.shade_smooth()

    # Legs (shorter and stubbier for baby)
    leg_positions = [
        (0.5, -0.4, 0.5),   # Front left
        (0.5, 0.4, 0.5),    # Front right
        (-0.5, -0.4, 0.5),  # Back left
        (-0.5, 0.4, 0.5)    # Back right
    ]

    for i, pos in enumerate(leg_positions):
        # Upper leg
        bpy.ops.mesh.primitive_cylinder_add(radius=0.15, depth=0.7, location=(pos[0], pos[1], 0.85))
        leg_upper = bpy.context.active_object
        leg_upper.name = f"LegUpper_{i}"
        bpy.ops.object.shade_smooth()

        # Lower leg
        bpy.ops.mesh.primitive_cylinder_add(radius=0.12, depth=0.6, location=(pos[0], pos[1], 0.3))
        leg_lower = bpy.context.active_object
        leg_lower.name = f"LegLower_{i}"
        bpy.ops.object.shade_smooth()

        # Hoof
        bpy.ops.mesh.primitive_cylinder_add(radius=0.13, depth=0.1, location=(pos[0], pos[1], 0.05))
        hoof = bpy.context.active_object
        hoof.name = f"Hoof_{i}"
        bpy.ops.object.shade_smooth()

    # Tail (cute little tail)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.6, location=(-1.0, 0, 1.0))
    tail = bpy.context.active_object
    tail.name = "Tail"
    tail.rotation_euler = (0, math.radians(-45), 0)
    bpy.ops.object.shade_smooth()

    # Create FUN, VIBRANT camel material with PROCEDURAL FUR for kids!
    mat = bpy.data.materials.new(name="CamelFur")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links

    # Clear default nodes
    nodes.clear()

    # Output node
    output = nodes.new('ShaderNodeOutputMaterial')
    output.location = (400, 0)

    # Principled BSDF
    bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.location = (0, 0)

    # FUN BRIGHT COLORS - Eye-popping orange for kids!
    # Base: Bright orange
    base_color = (1.0, 0.45, 0.1, 1)  # SUPER bright orange

    # Noise Texture for FUR variation
    noise = nodes.new('ShaderNodeTexNoise')
    noise.location = (-600, 200)
    noise.inputs['Scale'].default_value = 15.0  # Fine fur detail
    noise.inputs['Detail'].default_value = 8.0
    noise.inputs['Roughness'].default_value = 0.6

    # ColorRamp for fur highlights and shadows
    color_ramp = nodes.new('ShaderNodeValToRGB')
    color_ramp.location = (-400, 200)
    # Adjust color stops for fur variation
    color_ramp.color_ramp.elements[0].position = 0.3
    color_ramp.color_ramp.elements[0].color = (0.9, 0.35, 0.05, 1)  # Darker fur
    color_ramp.color_ramp.elements[1].position = 0.7
    color_ramp.color_ramp.elements[1].color = (1.0, 0.6, 0.2, 1)  # Lighter fur highlights

    # Mix RGB for final color
    mix = nodes.new('ShaderNodeMix')
    mix.location = (-200, 0)
    mix.data_type = 'RGBA'
    mix.inputs[6].default_value = base_color  # Base bright orange
    mix.inputs[0].default_value = 0.4  # Mix factor

    # Voronoi for fur clumps (more realistic)
    voronoi = nodes.new('ShaderNodeTexVoronoi')
    voronoi.location = (-600, -100)
    voronoi.inputs['Scale'].default_value = 25.0
    voronoi.feature = 'F1'

    # Bump for fur surface detail
    bump = nodes.new('ShaderNodeBump')
    bump.location = (-200, -200)
    bump.inputs['Strength'].default_value = 0.3
    bump.inputs['Distance'].default_value = 0.05

    # Connect nodes for TEXTURED FUR
    links.new(noise.outputs['Fac'], color_ramp.inputs['Fac'])
    links.new(color_ramp.outputs['Color'], mix.inputs[7])  # Color B
    links.new(mix.outputs[2], bsdf.inputs['Base Color'])
    links.new(voronoi.outputs['Distance'], bump.inputs['Height'])
    links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])

    # Material properties for kid-friendly look
    bsdf.inputs['Roughness'].default_value = 0.6  # Soft fur appearance
    bsdf.inputs['Specular IOR Level'].default_value = 0.3  # Subtle shine
    bsdf.inputs['Sheen Weight'].default_value = 0.5  # Fuzzy edges
    bsdf.inputs['Sheen Tint'].default_value = 0.8  # Warm sheen

    # EMISSION for extra pop!
    bsdf.inputs['Emission Color'].default_value = (1.0, 0.5, 0.15, 1)
    bsdf.inputs['Emission Strength'].default_value = 0.4  # Bright and fun!

    # Connect to output
    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])

    # Apply material to all camel parts except eyes
    for obj in bpy.data.objects:
        if obj.type == 'MESH' and not obj.name.startswith('Eye'):
            if not obj.data.materials:
                obj.data.materials.append(mat)

    print("✓ Baby camel model created!")
    return body

def create_simple_rig():
    """Create a simple armature for animation."""
    # Create armature
    bpy.ops.object.armature_add(location=(0, 0, 0.5))
    armature = bpy.context.active_object
    armature.name = "CamelRig"
    armature.show_in_front = True

    # Enter edit mode to add bones
    bpy.ops.object.mode_set(mode='EDIT')
    edit_bones = armature.data.edit_bones

    # Remove default bone
    edit_bones.remove(edit_bones[0])

    # Create main spine
    spine = edit_bones.new('Spine')
    spine.head = (0, 0, 0.5)
    spine.tail = (0, 0, 1.5)

    # Create neck bone
    neck = edit_bones.new('Neck')
    neck.head = (0.6, 0, 1.5)
    neck.tail = (1.0, 0, 1.9)
    neck.parent = spine

    # Create head bone
    head = edit_bones.new('Head')
    head.head = (1.0, 0, 1.9)
    head.tail = (1.4, 0, 2.1)
    head.parent = neck

    # Create leg bones (simple IK setup)
    leg_positions = [
        ('LegFL', 0.5, -0.4),   # Front left
        ('LegFR', 0.5, 0.4),    # Front right
        ('LegBL', -0.5, -0.4),  # Back left
        ('LegBR', -0.5, 0.4)    # Back right
    ]

    for name, x, y in leg_positions:
        leg = edit_bones.new(name)
        leg.head = (x, y, 0.5)
        leg.tail = (x, y, 0)
        leg.parent = spine

    bpy.ops.object.mode_set(mode='OBJECT')

    print("✓ Simple rig created!")
    return armature

def setup_scene():
    """Set up lighting, camera, and environment."""
    # Camera setup
    bpy.ops.object.camera_add(location=(5, -5, 3))
    camera = bpy.context.active_object
    camera.rotation_euler = (math.radians(70), 0, math.radians(45))
    bpy.context.scene.camera = camera

    # Sun light - reduced intensity to preserve colors
    bpy.ops.object.light_add(type='SUN', location=(5, 5, 10))
    sun = bpy.context.active_object
    sun.data.energy = 2.0  # Lower energy to avoid washing out colors
    sun.rotation_euler = (math.radians(45), math.radians(45), 0)

    # Fill light - warmer color to enhance vibrance
    bpy.ops.object.light_add(type='AREA', location=(-3, -3, 3))
    fill = bpy.context.active_object
    fill.data.energy = 100  # Lower to preserve material colors
    fill.data.size = 5
    fill.data.color = (1.0, 0.9, 0.8)  # Warm tint

    # Ground plane
    bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0, 0))
    ground = bpy.context.active_object
    ground.name = "Ground"

    # Ground material (VIBRANT golden sand)
    mat = bpy.data.materials.new(name="Sand")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs['Base Color'].default_value = (1.0, 0.8, 0.4, 1)  # Bright golden sand
    bsdf.inputs['Roughness'].default_value = 0.7
    ground.data.materials.append(mat)

    # World background (vibrant sky blue)
    world = bpy.data.worlds['World']
    world.use_nodes = True
    bg = world.node_tree.nodes['Background']
    bg.inputs['Color'].default_value = (0.6, 0.8, 1.0, 1.0)  # Brighter sky
    bg.inputs['Strength'].default_value = 1.2

    print("✓ Scene setup complete!")

def main():
    """Main function to create the baby camel scene."""
    print("Creating baby camel scene...")

    clear_scene()
    body = create_baby_camel()
    rig = create_simple_rig()
    setup_scene()

    # Save the scene
    output_path = "/Users/bedwards/rig/assets/baby_camel.blend"
    bpy.ops.wm.save_as_mainfile(filepath=output_path)

    print(f"\n✓ Baby camel scene saved to: {output_path}")
    print("\nNext: Run the animation script to add walk cycle!")

if __name__ == "__main__":
    main()
