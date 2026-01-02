#!/usr/bin/env python3
"""
FORCE vibrant colors with extreme emission - no more pale!
"""

import bpy

# Get all camel materials (not eyes)
for obj in bpy.data.objects:
    if obj.type == 'MESH' and not obj.name.startswith('Eye'):
        for slot in obj.material_slots:
            if slot.material:
                mat = slot.material
                if mat.node_tree:
                    nodes = mat.node_tree.nodes

                    # Find Principled BSDF
                    for node in nodes:
                        if node.type == 'BSDF_PRINCIPLED':
                            # EXTREME VIBRANT ORANGE
                            node.inputs['Base Color'].default_value = (1.0, 0.3, 0.0, 1)

                            # MASSIVE EMISSION to force visibility
                            node.inputs['Emission Color'].default_value = (1.0, 0.4, 0.0, 1)
                            node.inputs['Emission Strength'].default_value = 2.0  # VERY HIGH!

                            print(f"✓ Forced vibrant on {obj.name}")

# Kill environment lighting completely
world = bpy.data.worlds.get('World')
if world and world.node_tree:
    for node in world.node_tree.nodes:
        if node.type == 'BACKGROUND':
            node.inputs['Strength'].default_value = 0.1  # Nearly black

# Save
bpy.ops.wm.save_mainfile()
print("\n✓ EXTREME vibrant colors applied!")
