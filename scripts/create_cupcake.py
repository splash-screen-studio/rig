#!/usr/bin/env python3
"""
Create Cupcake v1.0.0
Creates a fun, colorful cupcake for kids with elaborate textures.
Uses procedural geometry and vibrant materials.

Usage:
    blender -b --python scripts/create_cupcake.py
    OR
    ./animate.sh create cupcake
"""

import bpy
import math
import random

VERSION = "1.0.5"

def log(msg):
    print(f"[create_cupcake v{VERSION}] {msg}")

def clear_scene():
    """Remove all objects from the scene."""
    log("Clearing scene...")
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

    # Clear orphan data
    for block in bpy.data.meshes:
        if block.users == 0:
            bpy.data.meshes.remove(block)
    for block in bpy.data.materials:
        if block.users == 0:
            bpy.data.materials.remove(block)

def create_wrapper_material():
    """Create a fun striped wrapper material - pink and white stripes."""
    log("Creating wrapper material...")
    mat = bpy.data.materials.new(name="WrapperMaterial")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    # Output
    output = nodes.new('ShaderNodeOutputMaterial')
    output.location = (400, 0)

    # Principled BSDF
    bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.location = (100, 0)

    # Wave texture for stripes
    wave = nodes.new('ShaderNodeTexWave')
    wave.location = (-500, 0)
    wave.wave_type = 'BANDS'
    wave.bands_direction = 'Z'
    wave.inputs['Scale'].default_value = 8.0
    wave.inputs['Distortion'].default_value = 0.0

    # Color ramp for pink/white stripes
    ramp = nodes.new('ShaderNodeValToRGB')
    ramp.location = (-200, 0)
    ramp.color_ramp.elements[0].position = 0.4
    ramp.color_ramp.elements[0].color = (1.0, 0.4, 0.6, 1.0)  # Pink
    ramp.color_ramp.elements[1].position = 0.6
    ramp.color_ramp.elements[1].color = (1.0, 1.0, 1.0, 1.0)  # White

    # Connect
    links.new(wave.outputs['Fac'], ramp.inputs['Fac'])
    links.new(ramp.outputs['Color'], bsdf.inputs['Base Color'])
    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])

    # Paper-like properties
    bsdf.inputs['Roughness'].default_value = 0.9
    bsdf.inputs['Specular IOR Level'].default_value = 0.1

    return mat

def create_cake_material():
    """Create a golden-brown cake material with texture."""
    log("Creating cake material...")
    mat = bpy.data.materials.new(name="CakeMaterial")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    output = nodes.new('ShaderNodeOutputMaterial')
    output.location = (600, 0)

    bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.location = (300, 0)

    # Noise for cake texture
    noise = nodes.new('ShaderNodeTexNoise')
    noise.location = (-300, 100)
    noise.inputs['Scale'].default_value = 20.0
    noise.inputs['Detail'].default_value = 10.0
    noise.inputs['Roughness'].default_value = 0.6

    # Color ramp for golden brown variation
    ramp = nodes.new('ShaderNodeValToRGB')
    ramp.location = (0, 100)
    ramp.color_ramp.elements[0].position = 0.3
    ramp.color_ramp.elements[0].color = (0.7, 0.45, 0.2, 1.0)  # Dark brown
    ramp.color_ramp.elements[1].position = 0.7
    ramp.color_ramp.elements[1].color = (0.95, 0.7, 0.35, 1.0)  # Golden

    # Bump for porous texture
    bump = nodes.new('ShaderNodeBump')
    bump.location = (0, -100)
    bump.inputs['Strength'].default_value = 0.2

    links.new(noise.outputs['Fac'], ramp.inputs['Fac'])
    links.new(noise.outputs['Fac'], bump.inputs['Height'])
    links.new(ramp.outputs['Color'], bsdf.inputs['Base Color'])
    links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])
    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])

    bsdf.inputs['Roughness'].default_value = 0.8
    bsdf.inputs['Subsurface Weight'].default_value = 0.2  # Soft look
    bsdf.inputs['Subsurface Radius'].default_value = (0.5, 0.3, 0.1)

    return mat

def create_frosting_material():
    """Create a creamy pink frosting material with swirl texture."""
    log("Creating frosting material...")
    mat = bpy.data.materials.new(name="FrostingMaterial")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    output = nodes.new('ShaderNodeOutputMaterial')
    output.location = (600, 0)

    bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.location = (300, 0)

    # Voronoi for creamy swirl texture
    voronoi = nodes.new('ShaderNodeTexVoronoi')
    voronoi.location = (-300, 100)
    voronoi.feature = 'SMOOTH_F1'
    voronoi.inputs['Scale'].default_value = 5.0
    voronoi.inputs['Smoothness'].default_value = 1.0

    # Color ramp for pink frosting variation
    ramp = nodes.new('ShaderNodeValToRGB')
    ramp.location = (0, 100)
    ramp.color_ramp.elements[0].position = 0.2
    ramp.color_ramp.elements[0].color = (1.0, 0.5, 0.7, 1.0)  # Light pink
    ramp.color_ramp.elements[1].position = 0.8
    ramp.color_ramp.elements[1].color = (1.0, 0.7, 0.85, 1.0)  # Lighter pink

    # Subtle bump
    bump = nodes.new('ShaderNodeBump')
    bump.location = (0, -100)
    bump.inputs['Strength'].default_value = 0.1

    links.new(voronoi.outputs['Distance'], ramp.inputs['Fac'])
    links.new(voronoi.outputs['Distance'], bump.inputs['Height'])
    links.new(ramp.outputs['Color'], bsdf.inputs['Base Color'])
    links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])
    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])

    # Creamy, slightly shiny
    bsdf.inputs['Roughness'].default_value = 0.4
    bsdf.inputs['Specular IOR Level'].default_value = 0.5
    bsdf.inputs['Subsurface Weight'].default_value = 0.3
    bsdf.inputs['Subsurface Radius'].default_value = (1.0, 0.5, 0.5)

    # Slight emission for glow
    bsdf.inputs['Emission Color'].default_value = (1.0, 0.6, 0.8, 1.0)
    bsdf.inputs['Emission Strength'].default_value = 0.15

    return mat

def create_sprinkle_material(color_name, rgb):
    """Create a vibrant sprinkle material."""
    mat = bpy.data.materials.new(name=f"Sprinkle_{color_name}")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    output = nodes.new('ShaderNodeOutputMaterial')
    output.location = (200, 0)

    bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.location = (0, 0)

    bsdf.inputs['Base Color'].default_value = (*rgb, 1.0)
    bsdf.inputs['Roughness'].default_value = 0.3
    bsdf.inputs['Specular IOR Level'].default_value = 0.6

    # Candy-like emission
    bsdf.inputs['Emission Color'].default_value = (*rgb, 1.0)
    bsdf.inputs['Emission Strength'].default_value = 0.3

    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])

    return mat

def create_cherry_material():
    """Create a shiny red cherry material."""
    log("Creating cherry material...")
    mat = bpy.data.materials.new(name="CherryMaterial")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    output = nodes.new('ShaderNodeOutputMaterial')
    output.location = (200, 0)

    bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.location = (0, 0)

    # Deep red color
    bsdf.inputs['Base Color'].default_value = (0.8, 0.05, 0.1, 1.0)
    bsdf.inputs['Roughness'].default_value = 0.15  # Very shiny
    bsdf.inputs['Specular IOR Level'].default_value = 0.8
    bsdf.inputs['Coat Weight'].default_value = 0.5  # Glossy coat
    bsdf.inputs['Coat Roughness'].default_value = 0.1

    # Subsurface for translucency
    bsdf.inputs['Subsurface Weight'].default_value = 0.4
    bsdf.inputs['Subsurface Radius'].default_value = (1.0, 0.2, 0.1)

    # Emission for pop
    bsdf.inputs['Emission Color'].default_value = (1.0, 0.1, 0.15, 1.0)
    bsdf.inputs['Emission Strength'].default_value = 0.2

    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])

    return mat

def create_stem_material():
    """Create a green stem material."""
    mat = bpy.data.materials.new(name="StemMaterial")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    output = nodes.new('ShaderNodeOutputMaterial')
    output.location = (200, 0)

    bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.location = (0, 0)

    bsdf.inputs['Base Color'].default_value = (0.2, 0.5, 0.15, 1.0)
    bsdf.inputs['Roughness'].default_value = 0.6

    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])

    return mat

def create_cupcake():
    """Create the cupcake model with all components."""
    log("Creating cupcake geometry...")

    # ============================================
    # DIMENSIONS - Single source of truth
    # ============================================
    WRAPPER_RADIUS_BOTTOM = 0.4
    WRAPPER_RADIUS_TOP = 0.6
    WRAPPER_HEIGHT = 0.5
    CAKE_RADIUS = 0.55
    CAKE_HEIGHT = 0.3
    FROSTING_RADIUS = 0.5
    FROSTING_HEIGHT = 0.6
    CHERRY_RADIUS = 0.18  # Larger cherry, more visible
    SPRINKLE_SIZE = 0.03
    NUM_SPRINKLES = 30

    cupcake_parts = []

    # ============================================
    # WRAPPER (pleated paper cup)
    # ============================================
    log("  Creating wrapper...")
    bpy.ops.mesh.primitive_cone_add(
        vertices=32,
        radius1=WRAPPER_RADIUS_BOTTOM,
        radius2=WRAPPER_RADIUS_TOP,
        depth=WRAPPER_HEIGHT,
        location=(0, 0, WRAPPER_HEIGHT / 2)
    )
    wrapper = bpy.context.active_object
    wrapper.name = "Wrapper"

    # Apply wrapper material
    wrapper_mat = create_wrapper_material()
    wrapper.data.materials.append(wrapper_mat)
    cupcake_parts.append(wrapper)

    # ============================================
    # CAKE (visible above wrapper)
    # ============================================
    log("  Creating cake...")
    cake_z = WRAPPER_HEIGHT + CAKE_HEIGHT / 2 - 0.05  # Slightly inside wrapper
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=32,
        radius=CAKE_RADIUS,
        depth=CAKE_HEIGHT,
        location=(0, 0, cake_z)
    )
    cake = bpy.context.active_object
    cake.name = "Cake"

    # Round the top slightly
    cake.scale.z = 0.8
    bpy.ops.object.shade_smooth()

    cake_mat = create_cake_material()
    cake.data.materials.append(cake_mat)
    cupcake_parts.append(cake)

    # ============================================
    # FROSTING (swirled on top)
    # ============================================
    log("  Creating frosting swirl...")
    frosting_base_z = WRAPPER_HEIGHT + CAKE_HEIGHT - 0.1

    # Main frosting dome
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=32,
        ring_count=16,
        radius=FROSTING_RADIUS,
        location=(0, 0, frosting_base_z + FROSTING_HEIGHT / 2)
    )
    frosting = bpy.context.active_object
    frosting.name = "Frosting"
    frosting.scale = (1.0, 1.0, 1.2)  # Taller
    bpy.ops.object.shade_smooth()

    frosting_mat = create_frosting_material()
    frosting.data.materials.append(frosting_mat)
    cupcake_parts.append(frosting)

    # Frosting peak (cone on top)
    peak_z = frosting_base_z + FROSTING_HEIGHT + 0.15
    bpy.ops.mesh.primitive_cone_add(
        vertices=16,
        radius1=0.15,
        radius2=0.02,
        depth=0.25,
        location=(0, 0, peak_z)
    )
    peak = bpy.context.active_object
    peak.name = "FrostingPeak"
    bpy.ops.object.shade_smooth()
    peak.data.materials.append(frosting_mat)
    cupcake_parts.append(peak)

    # ============================================
    # SPRINKLES (colorful candy pieces)
    # ============================================
    log(f"  Creating {NUM_SPRINKLES} sprinkles...")

    # Sprinkle colors - vibrant rainbow
    sprinkle_colors = [
        ("Red", (1.0, 0.2, 0.2)),
        ("Orange", (1.0, 0.5, 0.1)),
        ("Yellow", (1.0, 0.9, 0.2)),
        ("Green", (0.2, 0.9, 0.3)),
        ("Blue", (0.2, 0.4, 1.0)),
        ("Purple", (0.7, 0.2, 0.9)),
    ]

    # Create materials for each color
    sprinkle_mats = []
    for name, rgb in sprinkle_colors:
        sprinkle_mats.append(create_sprinkle_material(name, rgb))

    random.seed(42)  # Reproducible placement

    for i in range(NUM_SPRINKLES):
        # Random position on frosting surface (spherical distribution)
        theta = random.uniform(0, 2 * math.pi)
        phi = random.uniform(0.2, 0.8)  # Avoid very top and bottom

        r = FROSTING_RADIUS * 0.95  # Just above surface
        x = r * math.sin(phi * math.pi) * math.cos(theta)
        y = r * math.sin(phi * math.pi) * math.sin(theta)
        z = frosting_base_z + FROSTING_HEIGHT / 2 + r * math.cos(phi * math.pi) * 0.8

        # Create elongated sprinkle (cylinder)
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8,
            radius=SPRINKLE_SIZE,
            depth=SPRINKLE_SIZE * 4,
            location=(x, y, z)
        )
        sprinkle = bpy.context.active_object
        sprinkle.name = f"Sprinkle_{i:02d}"

        # Random rotation
        sprinkle.rotation_euler = (
            random.uniform(0, math.pi),
            random.uniform(0, math.pi),
            random.uniform(0, 2 * math.pi)
        )

        # Random color
        mat = random.choice(sprinkle_mats)
        sprinkle.data.materials.append(mat)

        bpy.ops.object.shade_smooth()
        cupcake_parts.append(sprinkle)

    # ============================================
    # CHERRY ON TOP
    # ============================================
    log("  Creating cherry...")
    cherry_z = peak_z + 0.25  # Raised higher

    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=16,
        ring_count=8,
        radius=CHERRY_RADIUS,
        location=(0.05, -0.05, cherry_z)  # Slightly forward toward camera
    )
    cherry = bpy.context.active_object
    cherry.name = "Cherry"
    bpy.ops.object.shade_smooth()

    cherry_mat = create_cherry_material()
    cherry.data.materials.append(cherry_mat)
    cupcake_parts.append(cherry)

    # Cherry stem
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=8,
        radius=0.015,
        depth=0.15,
        location=(0, 0.03, cherry_z + CHERRY_RADIUS + 0.05)
    )
    stem = bpy.context.active_object
    stem.name = "CherryStem"
    stem.rotation_euler = (math.radians(15), 0, 0)

    stem_mat = create_stem_material()
    stem.data.materials.append(stem_mat)
    cupcake_parts.append(stem)

    log(f"  Created {len(cupcake_parts)} parts total")
    return cupcake_parts

def setup_lighting():
    """Set up studio-style lighting for the cupcake."""
    log("Setting up lighting...")

    # Key light (sun)
    bpy.ops.object.light_add(type='SUN', location=(3, 3, 5))
    sun = bpy.context.active_object
    sun.name = "KeyLight"
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(45), math.radians(30), 0)

    # Fill light (area)
    bpy.ops.object.light_add(type='AREA', location=(-2, -2, 2))
    fill = bpy.context.active_object
    fill.name = "FillLight"
    fill.data.energy = 150
    fill.data.size = 3
    fill.data.color = (1.0, 0.95, 0.9)  # Warm

    # Rim light (from behind)
    bpy.ops.object.light_add(type='AREA', location=(0, -3, 3))
    rim = bpy.context.active_object
    rim.name = "RimLight"
    rim.data.energy = 100
    rim.data.size = 2
    rim.rotation_euler = (math.radians(60), 0, 0)

    # World background - soft gradient
    world = bpy.data.worlds['World']
    world.use_nodes = True
    bg = world.node_tree.nodes['Background']
    bg.inputs['Color'].default_value = (0.8, 0.9, 1.0, 1.0)  # Light blue
    bg.inputs['Strength'].default_value = 0.8

def setup_camera():
    """Set up camera for a nice cupcake view."""
    log("Setting up camera...")

    # Create an empty at cupcake center to track
    # Cupcake total height: wrapper(0.6) + cake(0.3) + frosting(0.6) + cherry(0.18) ≈ 1.7
    cupcake_center_z = 0.85  # Approximate visual center
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0, 0, cupcake_center_z))
    target = bpy.context.active_object
    target.name = "CupcakeCenter"

    # Camera further back to fit entire cupcake
    bpy.ops.object.camera_add(location=(5, -5, 4))
    camera = bpy.context.active_object
    camera.name = "CupcakeCamera"

    # Add constraint to track the cupcake center
    constraint = camera.constraints.new(type='TRACK_TO')
    constraint.target = target
    constraint.track_axis = 'TRACK_NEGATIVE_Z'
    constraint.up_axis = 'UP_Y'

    bpy.context.scene.camera = camera

def setup_render_settings():
    """Configure render settings for quality output."""
    log("Configuring render settings...")

    scene = bpy.context.scene

    # Use EEVEE for fast preview, CYCLES for final
    scene.render.engine = 'BLENDER_EEVEE'

    # Resolution
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080
    scene.render.resolution_percentage = 100

    # Frame range (for static, just 1 frame)
    scene.frame_start = 1
    scene.frame_end = 1

def main():
    print(f"\n{'='*50}")
    print(f"Create Cupcake v{VERSION}")
    print(f"{'='*50}\n")

    clear_scene()
    parts = create_cupcake()
    setup_lighting()
    setup_camera()
    setup_render_settings()

    # Save the .blend file
    output_path = "/Users/bedwards/rig/assets/cupcake.blend"
    log(f"Saving to {output_path}")
    bpy.ops.wm.save_as_mainfile(filepath=output_path)

    print(f"\n{'='*50}")
    log("Cupcake created successfully!")
    log(f"  Parts: {len(parts)}")
    log(f"  File: {output_path}")
    print(f"{'='*50}\n")

if __name__ == "__main__":
    main()
