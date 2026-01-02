#!/usr/bin/env python3
"""
Batch Animation Rendering for Blender CLI
Renders animations with configurable settings for production pipelines.
"""

import bpy
import sys
import argparse
from pathlib import Path


def setup_render_settings(engine='CYCLES', samples=128, resolution_x=1920, resolution_y=1080):
    """Configure render settings."""
    scene = bpy.context.scene

    # Map legacy names to Blender 5.0 names
    engine_map = {
        'CYCLES': 'CYCLES',
        'EEVEE': 'BLENDER_EEVEE',
        'BLENDER_EEVEE': 'BLENDER_EEVEE',
        'WORKBENCH': 'BLENDER_WORKBENCH'
    }

    # Render engine
    scene.render.engine = engine_map.get(engine, engine)

    if scene.render.engine == 'CYCLES':
        scene.cycles.samples = samples
        scene.cycles.device = 'GPU'
        scene.cycles.use_denoising = True
    elif scene.render.engine == 'BLENDER_EEVEE':
        scene.eevee.taa_render_samples = samples

    # Resolution
    scene.render.resolution_x = resolution_x
    scene.render.resolution_y = resolution_y
    scene.render.resolution_percentage = 100

    # Output
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.image_settings.compression = 15

    print(f"✓ Render settings configured:")
    print(f"  Engine: {engine}")
    print(f"  Samples: {samples}")
    print(f"  Resolution: {resolution_x}x{resolution_y}")


def render_animation(output_dir, start_frame=None, end_frame=None, frame_step=1):
    """Render animation frames."""
    scene = bpy.context.scene
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # Set frame range
    if start_frame is not None:
        scene.frame_start = start_frame
    if end_frame is not None:
        scene.frame_end = end_frame
    scene.frame_step = frame_step

    # Set output path
    scene.render.filepath = str(output_path / "frame_####")

    total_frames = (scene.frame_end - scene.frame_start + 1) // frame_step

    print(f"\n▶ Rendering animation:")
    print(f"  Frames: {scene.frame_start} to {scene.frame_end} (step: {frame_step})")
    print(f"  Total: {total_frames} frames")
    print(f"  Output: {output_path}")

    # Render
    bpy.ops.render.render(animation=True)

    print(f"\n✓ Rendering complete!")
    print(f"  Output location: {output_path}")


def render_single_frame(frame_number, output_path):
    """Render a single frame."""
    scene = bpy.context.scene
    scene.frame_set(frame_number)

    output_file = Path(output_path)
    output_file.parent.mkdir(parents=True, exist_ok=True)

    scene.render.filepath = str(output_file)

    print(f"▶ Rendering frame {frame_number}...")
    bpy.ops.render.render(write_still=True)
    print(f"✓ Saved: {output_file}")


def main():
    """Main entry point when run from CLI."""
    # Remove Blender args
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []

    parser = argparse.ArgumentParser(
        description="Batch render Blender animations"
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Output directory for rendered frames"
    )
    parser.add_argument(
        "--engine",
        choices=['CYCLES', 'EEVEE', 'BLENDER_EEVEE', 'WORKBENCH'],
        default='CYCLES',
        help="Render engine (default: CYCLES)"
    )
    parser.add_argument(
        "--samples",
        type=int,
        default=128,
        help="Render samples (default: 128)"
    )
    parser.add_argument(
        "--resolution",
        nargs=2,
        type=int,
        default=[1920, 1080],
        metavar=('WIDTH', 'HEIGHT'),
        help="Resolution (default: 1920 1080)"
    )
    parser.add_argument(
        "--start",
        type=int,
        help="Start frame (default: scene setting)"
    )
    parser.add_argument(
        "--end",
        type=int,
        help="End frame (default: scene setting)"
    )
    parser.add_argument(
        "--step",
        type=int,
        default=1,
        help="Frame step (default: 1)"
    )
    parser.add_argument(
        "--frame",
        type=int,
        help="Render single frame instead of animation"
    )

    args = parser.parse_args(argv)

    try:
        # Setup
        setup_render_settings(
            engine=args.engine,
            samples=args.samples,
            resolution_x=args.resolution[0],
            resolution_y=args.resolution[1]
        )

        # Render
        if args.frame is not None:
            output_file = f"{args.output}/frame_{args.frame:04d}.png"
            render_single_frame(args.frame, output_file)
        else:
            render_animation(
                args.output,
                start_frame=args.start,
                end_frame=args.end,
                frame_step=args.step
            )

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
