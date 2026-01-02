#!/usr/bin/env python3
"""
Make baby camel RADICAL and FUN with contrasting colors for kids!
These colors will transfer to Roblox via PBR texture baking.
"""

import bpy

print("Making baby camel RADICAL and FUN for kids!")

# ============================================
# 1. FIX GROUND - BRIGHT GREEN GRASS
# ============================================
ground = bpy.data.objects.get("Ground")
if ground:
    ground.data.materials.clear()
    mat = bpy.data.materials.new(name="BrightGrass")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    # BRIGHT LIME GREEN - fun for kids!
    bsdf.inputs['Base Color'].default_value = (0.3, 0.9, 0.2, 1)
    bsdf.inputs['Roughness'].default_value = 0.8
    ground.data.materials.append(mat)
    print("✓ Ground: BRIGHT LIME GREEN")

# ============================================
# 2. CAMEL - SUPER VIBRANT ORANGE/GOLD FUR
# ============================================
camel_parts = ['Body', 'Head', 'Neck', 'Hump', 'Snout', 'Tail',
               'Ear_L', 'Ear_R',
               'LegUpper_0', 'LegUpper_1', 'LegUpper_2', 'LegUpper_3',
               'LegLower_0', 'LegLower_1', 'LegLower_2', 'LegLower_3',
               'Hoof_0', 'Hoof_1', 'Hoof_2', 'Hoof_3']

# Create RADICAL fur material
fur_mat = bpy.data.materials.new(name="RadicalCamelFur")
fur_mat.use_nodes = True
nodes = fur_mat.node_tree.nodes
links = fur_mat.node_tree.links
nodes.clear()

# Output
output = nodes.new('ShaderNodeOutputMaterial')
output.location = (600, 0)

# Principled BSDF
bsdf = nodes.new('ShaderNodeBsdfPrincipled')
bsdf.location = (300, 0)

# RADICAL BRIGHT ORANGE - eye-popping!
bsdf.inputs['Base Color'].default_value = (1.0, 0.5, 0.0, 1)  # PURE BRIGHT ORANGE
bsdf.inputs['Roughness'].default_value = 0.4
bsdf.inputs['Metallic'].default_value = 0.0
bsdf.inputs['Specular IOR Level'].default_value = 0.5

# STRONG EMISSION for maximum vibrancy
bsdf.inputs['Emission Color'].default_value = (1.0, 0.6, 0.1, 1)  # Golden glow
bsdf.inputs['Emission Strength'].default_value = 2.0  # VERY STRONG!

# Sheen for fuzzy fur look
bsdf.inputs['Sheen Weight'].default_value = 1.0

# Noise texture for visible fur pattern
noise = nodes.new('ShaderNodeTexNoise')
noise.location = (-400, 200)
noise.inputs['Scale'].default_value = 20.0  # Visible fur detail
noise.inputs['Detail'].default_value = 8.0
noise.inputs['Roughness'].default_value = 0.6

# Color ramp for dramatic fur variation
ramp = nodes.new('ShaderNodeValToRGB')
ramp.location = (-200, 200)
ramp.color_ramp.elements[0].position = 0.35
ramp.color_ramp.elements[0].color = (0.95, 0.35, 0.0, 1)  # Deep orange
ramp.color_ramp.elements[1].position = 0.65
ramp.color_ramp.elements[1].color = (1.0, 0.7, 0.2, 1)   # Bright golden

# Mix colors
mix = nodes.new('ShaderNodeMix')
mix.location = (0, 100)
mix.data_type = 'RGBA'
mix.inputs[0].default_value = 0.5  # Strong mix
mix.inputs[6].default_value = (1.0, 0.5, 0.0, 1)  # Base orange

# Bump for fur surface
bump = nodes.new('ShaderNodeBump')
bump.location = (0, -150)
bump.inputs['Strength'].default_value = 0.4

# Connect
links.new(noise.outputs['Fac'], ramp.inputs['Fac'])
links.new(ramp.outputs['Color'], mix.inputs[7])
links.new(mix.outputs[2], bsdf.inputs['Base Color'])
links.new(noise.outputs['Fac'], bump.inputs['Height'])
links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])
links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])

print("✓ Camel: RADICAL ORANGE with fur texture")

# Apply to all camel parts
for part_name in camel_parts:
    obj = bpy.data.objects.get(part_name)
    if obj:
        obj.data.materials.clear()
        obj.data.materials.append(fur_mat)

print(f"  Applied to {len(camel_parts)} body parts")

# ============================================
# 3. BRIGHT BLUE SKY
# ============================================
world = bpy.data.worlds['World']
world.use_nodes = True
bg = world.node_tree.nodes['Background']
bg.inputs['Color'].default_value = (0.3, 0.6, 1.0, 1)  # Bright cheerful blue
bg.inputs['Strength'].default_value = 1.0
print("✓ Sky: BRIGHT BLUE")

# ============================================
# 4. WARM SUNLIGHT
# ============================================
for obj in bpy.data.objects:
    if obj.type == 'LIGHT':
        if obj.data.type == 'SUN':
            obj.data.energy = 2.5
            obj.data.color = (1.0, 0.95, 0.85)
        elif obj.data.type == 'AREA':
            obj.data.energy = 80

print("✓ Lighting: WARM SUN")

# Save
bpy.ops.wm.save_mainfile()

print("\n" + "="*50)
print("✓ RADICAL FUN baby camel ready!")
print("  🧡 BRIGHT ORANGE camel with fur")
print("  💚 LIME GREEN grass ground")
print("  💙 BRIGHT BLUE sky")
print("  ☀️  WARM sunlight")
print("="*50)
print("\nThese colors will bake into Roblox PBR textures!")
