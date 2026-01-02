#!/usr/bin/env python3
"""
FORCE vibrant color using EMISSION ONLY shader.
No more Principled BSDF - pure glowing color!
"""

import bpy

print("FORCING vibrant color with EMISSION ONLY shader...")

camel_parts = ['Body', 'Head', 'Neck', 'Hump', 'Snout', 'Tail',
               'Ear_L', 'Ear_R',
               'LegUpper_0', 'LegUpper_1', 'LegUpper_2', 'LegUpper_3',
               'LegLower_0', 'LegLower_1', 'LegLower_2', 'LegLower_3',
               'Hoof_0', 'Hoof_1', 'Hoof_2', 'Hoof_3']

# Create PURE EMISSION material - just glowing orange!
glow_mat = bpy.data.materials.new(name="GlowingOrange")
glow_mat.use_nodes = True
nodes = glow_mat.node_tree.nodes
links = glow_mat.node_tree.links
nodes.clear()

# Output
output = nodes.new('ShaderNodeOutputMaterial')
output.location = (400, 0)

# Mix Shader - combine emission with diffuse for some shading
mix = nodes.new('ShaderNodeMixShader')
mix.location = (200, 0)
mix.inputs[0].default_value = 0.3  # 30% diffuse, 70% emission

# EMISSION - PURE GLOWING ORANGE
emission = nodes.new('ShaderNodeEmission')
emission.location = (0, 100)
emission.inputs['Color'].default_value = (1.0, 0.5, 0.0, 1)  # BRIGHT ORANGE
emission.inputs['Strength'].default_value = 3.0  # VERY BRIGHT!

# Diffuse for some shading/depth
diffuse = nodes.new('ShaderNodeBsdfDiffuse')
diffuse.location = (0, -100)
diffuse.inputs['Color'].default_value = (1.0, 0.4, 0.0, 1)  # Orange diffuse

# Connect
links.new(diffuse.outputs['BSDF'], mix.inputs[1])
links.new(emission.outputs['Emission'], mix.inputs[2])
links.new(mix.outputs['Shader'], output.inputs['Surface'])

print("✓ Created GLOWING ORANGE emission material")

# Apply to all camel parts
for part_name in camel_parts:
    obj = bpy.data.objects.get(part_name)
    if obj:
        obj.data.materials.clear()
        obj.data.materials.append(glow_mat)

print(f"✓ Applied to {len(camel_parts)} camel parts")

# Save
bpy.ops.wm.save_mainfile()
print("✓ Saved! Camel should now GLOW ORANGE!")
