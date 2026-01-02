#!/usr/bin/env python3
"""
Animate a bouncing ball with realistic physics.
Uses parabolic motion for natural bounce.
"""

import bpy
import math

def create_bounce_animation():
    """Create bouncing animation with physics."""

    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = 120  # 5 seconds at 24fps
    scene.frame_current = 1

    # Get ball
    ball = bpy.data.objects.get("Ball")
    if not ball:
        print("Error: Ball not found!")
        return

    # Animation parameters
    gravity = 9.8
    initial_height = 2.0
    bounce_damping = 0.7  # Energy loss per bounce
    forward_speed = 3.0   # Units per second
    fps = 24

    print("Creating bounce animation...")

    for frame in range(1, 121):
        scene.frame_set(frame)

        # Time in seconds
        time = frame / fps

        # Forward movement (constant)
        ball.location.x = time * forward_speed

        # Vertical bounce (parabolic with damping)
        # Calculate which bounce we're in
        bounce_time = 0
        remaining_height = initial_height
        current_time = time

        while current_time > 0:
            # Time for this bounce
            fall_time = math.sqrt(2 * remaining_height / gravity)

            if current_time <= fall_time:
                # During this bounce
                bounce_time = current_time
                break

            # Move to next bounce
            current_time -= fall_time
            remaining_height *= bounce_damping ** 2

            if remaining_height < 0.01:  # Ball settled
                bounce_time = 0
                remaining_height = 0
                break

        # Calculate height using parabolic motion
        if remaining_height > 0.01:
            velocity = math.sqrt(2 * gravity * remaining_height)
            height = remaining_height - 0.5 * gravity * bounce_time ** 2
            height = max(0.5, height)  # Ball radius
        else:
            height = 0.5  # Resting on ground

        ball.location.z = height

        # Rotation (rolling)
        # Circumference = 2πr, r=0.5
        circumference = math.pi
        rotations = (ball.location.x / circumference) * 2 * math.pi
        ball.rotation_euler.y = -rotations

        # Squash and stretch during impact
        impact_threshold = 0.6
        if height < impact_threshold:
            # Squash when close to ground
            squash = 1.0 - (impact_threshold - height) * 0.5
            ball.scale.z = squash
            ball.scale.x = ball.scale.y = 1.0 + (1.0 - squash) * 0.5
        else:
            # Normal shape
            ball.scale = (1.0, 1.0, 1.0)

        # Keyframe everything
        ball.keyframe_insert(data_path="location", frame=frame)
        ball.keyframe_insert(data_path="rotation_euler", frame=frame)
        ball.keyframe_insert(data_path="scale", frame=frame)

    print("✓ Bounce animation created!")
    print(f"  Duration: 120 frames (5 seconds at 24fps)")
    print(f"  Ball travels {forward_speed * 5:.1f} units forward")

def setup_camera_tracking():
    """Set up camera to follow the ball."""
    camera = bpy.data.objects.get("Camera")
    ball = bpy.data.objects.get("Ball")

    if camera and ball:
        # Make camera track the ball
        constraint = camera.constraints.new(type='TRACK_TO')
        constraint.target = ball
        constraint.track_axis = 'TRACK_NEGATIVE_Z'
        constraint.up_axis = 'UP_Y'

        # Animate camera position to follow
        for frame in range(1, 121):
            bpy.context.scene.frame_set(frame)
            time = frame / 24.0
            camera.location.x = time * 3.0 + 8
            camera.keyframe_insert(data_path="location", frame=frame)

        print("✓ Camera tracking setup!")

def main():
    """Main animation function."""
    print("Adding bounce animation...")

    create_bounce_animation()
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
    print("  ./animate.sh render bouncing_ball --samples 64")

if __name__ == "__main__":
    main()
