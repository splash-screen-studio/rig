#!/bin/bash
#
# animate.sh - Unified CLI Workflow for 3D Animation Pipeline
#
# This script orchestrates the complete animation workflow:
# 1. Create/modify Blender scene with Python script
# 2. Apply animation
# 3. Render frames to PNG
# 4. Generate MP4 video
# 5. Output verification info for Claude Code to read frames
#
# Usage examples:
#   ./animate.sh create baby_camel      # Create scene
#   ./animate.sh render baby_camel      # Render existing scene
#   ./animate.sh full baby_camel        # Full workflow (create + render)
#   ./animate.sh verify baby_camel 10   # Verify every 10th frame
#

set -e  # Exit on error

# Configuration
BLENDER="${BLENDER_BIN:-blender}"
ASSETS_DIR="assets"
SCRIPTS_DIR="scripts"
RENDERS_DIR="renders"
DEFAULT_ENGINE="EEVEE"
DEFAULT_SAMPLES=64
DEFAULT_FPS=24

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

show_usage() {
    cat << EOF
Usage: $0 <command> <scene_name> [options]

Commands:
  create <name>              Create new scene using creation script
  animate <name>             Apply animation to existing scene
  render <name>              Render scene to PNG frames
  video <name>               Generate MP4 from existing frames
  full <name>                Full workflow: create + animate + render + video
  verify <name> [interval]   Show frames for Claude to verify (every Nth frame)
  clean <name>               Clean up rendered files for scene
  export <name>              Export FBX for Roblox
  bake <name>                Bake PBR textures (ColorMap, NormalMap, etc.)
  upload <name>              Upload FBX + textures to Roblox Cloud
  deploy <name>              Full pipeline: export + bake + upload + output MCP commands

Options:
  --engine <ENGINE>          Render engine: EEVEE, CYCLES (default: $DEFAULT_ENGINE)
  --samples <N>              Render samples (default: $DEFAULT_SAMPLES)
  --fps <N>                  Frames per second (default: $DEFAULT_FPS)
  --start <N>                Start frame (default: 1)
  --end <N>                  End frame (default: 60)
  --resolution <W> <H>       Resolution (default: 1920 1080)
  --no-video                 Skip video generation
  --force                    Overwrite existing files

Examples:
  $0 create baby_camel
  $0 full baby_camel --engine CYCLES --samples 128
  $0 render baby_camel --start 1 --end 120
  $0 verify baby_camel 15

Environment Variables:
  BLENDER_BIN               Path to Blender executable (default: blender)
EOF
}

# Parse arguments
if [ $# -lt 2 ]; then
    show_usage
    exit 1
fi

COMMAND=$1
SCENE_NAME=$2
shift 2

# Default options
ENGINE=$DEFAULT_ENGINE
SAMPLES=$DEFAULT_SAMPLES
FPS=$DEFAULT_FPS
START_FRAME=1
END_FRAME=60
RESOLUTION_W=1920
RESOLUTION_H=1080
GENERATE_VIDEO=true
FORCE=false
VERIFY_INTERVAL=10

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        --engine)
            ENGINE="$2"
            shift 2
            ;;
        --samples)
            SAMPLES="$2"
            shift 2
            ;;
        --fps)
            FPS="$2"
            shift 2
            ;;
        --start)
            START_FRAME="$2"
            shift 2
            ;;
        --end)
            END_FRAME="$2"
            shift 2
            ;;
        --resolution)
            RESOLUTION_W="$2"
            RESOLUTION_H="$3"
            shift 3
            ;;
        --no-video)
            GENERATE_VIDEO=false
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        *)
            if [[ "$COMMAND" == "verify" && "$1" =~ ^[0-9]+$ ]]; then
                VERIFY_INTERVAL=$1
                shift
            else
                log_error "Unknown option: $1"
                show_usage
                exit 1
            fi
            ;;
    esac
done

# File paths
BLEND_FILE="$ASSETS_DIR/${SCENE_NAME}.blend"
CREATE_SCRIPT="$SCRIPTS_DIR/create_${SCENE_NAME}.py"
ANIMATE_SCRIPT="$SCRIPTS_DIR/animate_${SCENE_NAME}_walk.py"
OUTPUT_DIR="$RENDERS_DIR/$SCENE_NAME"
VIDEO_FILE="$RENDERS_DIR/${SCENE_NAME}_walking.mp4"
FBX_FILE="exports/${SCENE_NAME}.fbx"
EXPORTS_DIR="exports"

# Functions for each command

cmd_create() {
    log_info "Creating scene: $SCENE_NAME"

    if [ ! -f "$CREATE_SCRIPT" ]; then
        log_error "Creation script not found: $CREATE_SCRIPT"
        exit 1
    fi

    if [ -f "$BLEND_FILE" ] && [ "$FORCE" = false ]; then
        log_warning "Scene already exists: $BLEND_FILE"
        log_info "Use --force to overwrite"
        exit 1
    fi

    $BLENDER --background --python "$CREATE_SCRIPT"
    log_success "Scene created: $BLEND_FILE"
}

cmd_animate() {
    log_info "Applying animation: $SCENE_NAME"

    if [ ! -f "$BLEND_FILE" ]; then
        log_error "Scene file not found: $BLEND_FILE"
        exit 1
    fi

    if [ ! -f "$ANIMATE_SCRIPT" ]; then
        log_error "Animation script not found: $ANIMATE_SCRIPT"
        exit 1
    fi

    $BLENDER --background "$BLEND_FILE" --python "$ANIMATE_SCRIPT"
    log_success "Animation applied"
}

cmd_render() {
    log_info "Rendering: $SCENE_NAME"
    log_info "  Engine: $ENGINE"
    log_info "  Samples: $SAMPLES"
    log_info "  Frames: $START_FRAME-$END_FRAME"
    log_info "  Resolution: ${RESOLUTION_W}x${RESOLUTION_H}"

    if [ ! -f "$BLEND_FILE" ]; then
        log_error "Scene file not found: $BLEND_FILE"
        exit 1
    fi

    # Clean old renders if force
    if [ "$FORCE" = true ] && [ -d "$OUTPUT_DIR" ]; then
        log_warning "Removing old renders"
        rm -rf "$OUTPUT_DIR"
    fi

    # Render
    $BLENDER -b "$BLEND_FILE" --python "$SCRIPTS_DIR/batch_render.py" -- \
        --output "$OUTPUT_DIR" \
        --engine "$ENGINE" \
        --samples "$SAMPLES" \
        --resolution "$RESOLUTION_W" "$RESOLUTION_H" \
        --start "$START_FRAME" \
        --end "$END_FRAME"

    # Count frames
    FRAME_COUNT=$(ls "$OUTPUT_DIR"/*.png 2>/dev/null | wc -l | tr -d ' ')
    log_success "Rendered $FRAME_COUNT frames to: $OUTPUT_DIR"
}

cmd_video() {
    log_info "Generating video: $SCENE_NAME"

    if [ ! -d "$OUTPUT_DIR" ]; then
        log_error "Frames directory not found: $OUTPUT_DIR"
        exit 1
    fi

    FRAME_COUNT=$(ls "$OUTPUT_DIR"/*.png 2>/dev/null | wc -l | tr -d ' ')
    if [ "$FRAME_COUNT" -eq 0 ]; then
        log_error "No frames found in: $OUTPUT_DIR"
        exit 1
    fi

    # Generate video
    ffmpeg -y -framerate "$FPS" \
        -i "$OUTPUT_DIR/frame_%04d.png" \
        -c:v libx264 \
        -pix_fmt yuv420p \
        -crf 18 \
        "$VIDEO_FILE" 2>&1 | grep -E "frame=|video:" | tail -3

    VIDEO_SIZE=$(ls -lh "$VIDEO_FILE" | awk '{print $5}')
    log_success "Video created: $VIDEO_FILE ($VIDEO_SIZE)"
}

cmd_verify() {
    log_info "Verification frames for Claude Code to read:"
    echo ""
    echo "# Frame Verification for: $SCENE_NAME"
    echo "# Read these frames to verify animation:"
    echo ""

    if [ ! -d "$OUTPUT_DIR" ]; then
        log_error "Frames directory not found: $OUTPUT_DIR"
        exit 1
    fi

    FRAME_COUNT=$(ls "$OUTPUT_DIR"/*.png 2>/dev/null | wc -l | tr -d ' ')

    for ((i=1; i<=FRAME_COUNT; i+=VERIFY_INTERVAL)); do
        FRAME_FILE=$(printf "$OUTPUT_DIR/frame_%04d.png" $i)
        if [ -f "$FRAME_FILE" ]; then
            echo "$FRAME_FILE"
        fi
    done

    echo ""
    log_info "Total frames: $FRAME_COUNT"
    log_info "Showing every ${VERIFY_INTERVAL}th frame"
    echo ""
    echo "# To read these frames in Claude Code, use:"
    echo "# Read tool with each file path above"
}

cmd_clean() {
    log_warning "Cleaning renders for: $SCENE_NAME"

    if [ -d "$OUTPUT_DIR" ]; then
        rm -rf "$OUTPUT_DIR"
        log_success "Removed: $OUTPUT_DIR"
    fi

    if [ -f "$VIDEO_FILE" ]; then
        rm -f "$VIDEO_FILE"
        log_success "Removed: $VIDEO_FILE"
    fi

    log_success "Cleanup complete"
}

cmd_export() {
    log_info "Exporting FBX: $SCENE_NAME"

    if [ ! -f "$BLEND_FILE" ]; then
        log_error "Scene file not found: $BLEND_FILE"
        exit 1
    fi

    mkdir -p "$EXPORTS_DIR"

    $BLENDER -b "$BLEND_FILE" --python "$SCRIPTS_DIR/export_fbx.py" -- \
        --output "$FBX_FILE"

    if [ -f "$FBX_FILE" ]; then
        FBX_SIZE=$(ls -lh "$FBX_FILE" | awk '{print $5}')
        log_success "Exported: $FBX_FILE ($FBX_SIZE)"
    else
        log_error "FBX export failed"
        exit 1
    fi
}

cmd_bake() {
    log_info "Baking PBR textures: $SCENE_NAME"

    if [ ! -f "$BLEND_FILE" ]; then
        log_error "Scene file not found: $BLEND_FILE"
        exit 1
    fi

    TEXTURE_DIR="$EXPORTS_DIR/textures"
    mkdir -p "$TEXTURE_DIR"

    # Bake for Body (main mesh) - can be extended for multiple objects
    $BLENDER -b "$BLEND_FILE" --python "$SCRIPTS_DIR/bake_pbr.py" -- \
        --object "Body" \
        --output "$TEXTURE_DIR" \
        --resolution 1024

    log_success "PBR textures baked to: $TEXTURE_DIR"
}

cmd_upload() {
    log_info "Uploading to Roblox Cloud: $SCENE_NAME"

    # Load environment
    if [ -f ".env" ]; then
        source .env
        export ROBLOX_API_KEY
        export ROBLOX_CREATOR_ID
    else
        log_error ".env file not found"
        log_info "Create .env with ROBLOX_API_KEY, ROBLOX_CREATOR_ID"
        exit 1
    fi

    if [ -z "$ROBLOX_API_KEY" ]; then
        log_error "ROBLOX_API_KEY not set in .env"
        exit 1
    fi

    # Use Python upload script
    python3 "$SCRIPTS_DIR/upload_to_roblox.py" \
        --scene "$SCENE_NAME" \
        --exports-dir "$EXPORTS_DIR" \
        --output "$EXPORTS_DIR/${SCENE_NAME}_assets.json"

    if [ -f "$EXPORTS_DIR/${SCENE_NAME}_assets.json" ]; then
        log_success "Asset IDs saved to: $EXPORTS_DIR/${SCENE_NAME}_assets.json"
    fi
}

cmd_deploy() {
    log_info "=== Full Deploy Pipeline: $SCENE_NAME ==="
    echo ""

    log_info "Step 1/3: Export FBX"
    cmd_export
    echo ""

    log_info "Step 2/3: Bake PBR Textures"
    cmd_bake
    echo ""

    log_info "Step 3/3: Upload to Roblox Cloud"
    cmd_upload
    echo ""

    log_success "=== Deploy Complete ==="
    echo ""
    log_info "Next: Use MCP to setup model in Studio"
    log_info "Asset IDs in: $EXPORTS_DIR/${SCENE_NAME}_assets.json"
}

cmd_full() {
    log_info "=== Full Workflow: $SCENE_NAME ==="
    echo ""

    cmd_create
    echo ""

    cmd_animate
    echo ""

    cmd_render
    echo ""

    if [ "$GENERATE_VIDEO" = true ]; then
        cmd_video
        echo ""
    fi

    log_success "=== Workflow Complete ==="
    echo ""
    log_info "Output locations:"
    echo "  Scene:  $BLEND_FILE"
    echo "  Frames: $OUTPUT_DIR/"
    if [ "$GENERATE_VIDEO" = true ]; then
        echo "  Video:  $VIDEO_FILE"
    fi
    echo ""
    log_info "Next steps:"
    echo "  1. Watch video: open $VIDEO_FILE"
    echo "  2. Verify frames: $0 verify $SCENE_NAME"
}

# Execute command
case $COMMAND in
    create)
        cmd_create
        ;;
    animate)
        cmd_animate
        ;;
    render)
        cmd_render
        ;;
    video)
        cmd_video
        ;;
    full)
        cmd_full
        ;;
    verify)
        cmd_verify
        ;;
    clean)
        cmd_clean
        ;;
    export)
        cmd_export
        ;;
    bake)
        cmd_bake
        ;;
    upload)
        cmd_upload
        ;;
    deploy)
        cmd_deploy
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac
