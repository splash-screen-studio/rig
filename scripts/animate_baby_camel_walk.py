#!/usr/bin/env python3
"""
Create a walk cycle animation for the baby camel.
Simple procedural animation using keyframes.
"""

import bpy
import math

def create_walk_cycle():
    """Create a simple walk cycle for the baby camel."""

    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = 60  # 2.5 seconds at 24fps
    scene.frame_current = 1

    # Get the rig
    rig = bpy.data.objects.get("CamelRig")
    if rig:
        animate_with_rig()
    else:
        # Fallback: animate body parts directly
        animate_direct()

def animate_direct():
    """Animate the camel directly without rig."""

    # Get leg objects
    legs = {
        'FL': [],  # Front left
        'FR': [],  # Front right
        'BL': [],  # Back left
        'BR': []   # Back right
    }

    for i in range(4):
        upper = bpy.data.objects.get(f"LegUpper_{i}")
        lower = bpy.data.objects.get(f"LegLower_{i}")
        hoof = bpy.data.objects.get(f"Hoof_{i}")

        if upper and lower and hoof:
            if i == 0:
                legs['FL'] = [upper, lower, hoof]
            elif i == 1:
                legs['FR'] = [upper, lower, hoof]
            elif i == 2:
                legs['BL'] = [upper, lower, hoof]
            elif i == 3:
                legs['BR'] = [upper, lower, hoof]

    # Get body and head for bobbing motion
    body = bpy.data.objects.get("Body")
    head = bpy.data.objects.get("Head")
    neck = bpy.data.objects.get("Neck")
    tail = bpy.data.objects.get("Tail")

    # Create walk cycle (60 frames = 2.5 seconds)
    # Camel walk: move front left + back right together, then front right + back left

    # Calculate base forward movement (entire camel moves together)
    for frame in range(1, 61):
        bpy.context.scene.frame_set(frame)

        # Calculate walk phase (0 to 2π)
        phase = (frame / 30.0) * math.pi  # Complete cycle every 30 frames

        # GLOBAL forward movement - ALL parts move together
        forward_offset = (frame / 60.0) * 3.0

        # Body forward movement (walking forward)
        if body:
            body.location.x = forward_offset
            # Body bobbing (up and down)
            body.location.z = 1.2 + math.sin(phase * 2) * 0.1
            body.keyframe_insert(data_path="location", frame=frame)

        # Head - moves forward WITH body + bobbing
        if head:
            head.location.x = 1.2 + forward_offset  # Original X + forward movement
            head.location.z = 1.9 + math.sin(phase * 2) * 0.08
            head.keyframe_insert(data_path="location", frame=frame)

        # Neck - moves forward WITH body
        if neck:
            neck.location.x = 0.8 + forward_offset  # Original X + forward movement
            neck.rotation_euler.y = math.radians(30) + math.sin(phase * 2) * 0.1
            neck.keyframe_insert(data_path="location", frame=frame)
            neck.keyframe_insert(data_path="rotation_euler", frame=frame)

        # Tail - moves forward WITH body
        if tail:
            tail.location.x = -1.0 + forward_offset  # Original X + forward movement
            tail.rotation_euler.z = math.sin(phase * 2) * 0.3
            tail.keyframe_insert(data_path="location", frame=frame)
            tail.keyframe_insert(data_path="rotation_euler", frame=frame)

        # Hump - MUST move forward WITH body!
        hump = bpy.data.objects.get("Hump")
        if hump:
            hump.location.x = -0.2 + forward_offset
            hump.keyframe_insert(data_path="location", frame=frame)

        # Eyes - MUST move forward WITH head!
        eye_l = bpy.data.objects.get("Eye_L")
        eye_r = bpy.data.objects.get("Eye_R")
        if eye_l:
            eye_l.location.x = 1.25 + forward_offset
            eye_l.keyframe_insert(data_path="location", frame=frame)
        if eye_r:
            eye_r.location.x = 1.25 + forward_offset
            eye_r.keyframe_insert(data_path="location", frame=frame)

        # Ears - MUST move forward WITH head!
        ear_l = bpy.data.objects.get("Ear_L")
        ear_r = bpy.data.objects.get("Ear_R")
        if ear_l:
            ear_l.location.x = 1.1 + forward_offset
            ear_l.keyframe_insert(data_path="location", frame=frame)
        if ear_r:
            ear_r.location.x = 1.1 + forward_offset
            ear_r.keyframe_insert(data_path="location", frame=frame)

        # Snout - MUST move forward WITH head!
        snout = bpy.data.objects.get("Snout")
        if snout:
            snout.location.x = 1.45 + forward_offset
            snout.keyframe_insert(data_path="location", frame=frame)

        # Leg animation - proper walking with forward/back swing + lift
        leg_height = 0.15
        leg_swing = 0.3  # How far forward/back legs swing

        # Get original leg positions
        leg_base_x = {
            'FL': 0.5,
            'FR': 0.5,
            'BL': -0.5,
            'BR': -0.5
        }

        leg_pairs = [
            (['FL', 'BR'], phase),           # Pair 1
            (['FR', 'BL'], phase + math.pi)  # Pair 2 (opposite phase)
        ]

        for pair, leg_phase in leg_pairs:
            # Lift when moving forward, down when pushing back
            lift = max(0, math.sin(leg_phase)) * leg_height
            # Swing: negative = back (planted), positive = forward (lifted)
            swing = math.cos(leg_phase) * leg_swing

            for leg_id in pair:
                if leg_id in legs and legs[leg_id]:
                    upper, lower, hoof = legs[leg_id]
                    base_x = leg_base_x[leg_id]

                    # Move legs forward with body + add swing motion
                    upper.location.x = base_x + forward_offset + swing
                    lower.location.x = base_x + forward_offset + swing
                    hoof.location.x = base_x + forward_offset + swing

                    # Lift legs
                    upper.location.z = 0.85 + lift
                    lower.location.z = 0.3 + lift
                    hoof.location.z = 0.05 + lift

                    # Slight rotation for natural movement
                    upper.rotation_euler.y = math.sin(leg_phase) * 0.2
                    lower.rotation_euler.y = -math.sin(leg_phase) * 0.15

                    upper.keyframe_insert(data_path="location", frame=frame)
                    lower.keyframe_insert(data_path="location", frame=frame)
                    hoof.keyframe_insert(data_path="location", frame=frame)
                    upper.keyframe_insert(data_path="rotation_euler", frame=frame)
                    lower.keyframe_insert(data_path="rotation_euler", frame=frame)

    print("✓ Walk cycle animation created!")
    print(f"  Duration: 60 frames (2.5 seconds at 24fps)")
    print(f"  Body travels 3 units forward")

def animate_with_rig():
    """Animate using armature rig (if available)."""
    print("Rig-based animation would go here")
    # Fall back to direct animation for now
    animate_direct()

def setup_camera_tracking():
    """Set up camera to follow the walking camel."""
    camera = bpy.data.objects.get("Camera")
    body = bpy.data.objects.get("Body")

    if camera and body:
        # Make camera track the body
        constraint = camera.constraints.new(type='TRACK_TO')
        constraint.target = body
        constraint.track_axis = 'TRACK_NEGATIVE_Z'
        constraint.up_axis = 'UP_Y'

        # Animate camera position to follow
        for frame in range(1, 61):
            bpy.context.scene.frame_set(frame)
            camera.location.x = (frame / 60.0) * 3.0 + 5
            camera.keyframe_insert(data_path="location", frame=frame)

        print("✓ Camera tracking setup!")

def main():
    """Main animation function."""
    print("Adding walk cycle animation to baby camel...")

    # Set up animation
    create_walk_cycle()
    setup_camera_tracking()

    # Set render settings
    scene = bpy.context.scene
    scene.render.fps = 24
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080

    # Save
    bpy.ops.wm.save_mainfile()

    print("\n✓ Animation complete!")
    print("\nRender with:")
    print("  blender -b assets/baby_camel.blend --python scripts/batch_render.py -- \\")
    print("    --output renders/baby_camel \\")
    print("    --engine EEVEE \\")
    print("    --samples 64")

if __name__ == "__main__":
    main()
