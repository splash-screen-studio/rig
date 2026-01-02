#!/usr/bin/env python3
"""
Upload to Roblox Cloud v1.0.0
Uploads FBX model and PBR textures, outputs asset IDs for MCP setup.
"""

import subprocess
import json
import sys
import os
import time
import argparse
from pathlib import Path

VERSION = "1.0.0"

def log(msg):
    print(f"[upload_to_roblox v{VERSION}] {msg}")

def upload_asset(filepath, asset_type, display_name, description, api_key, creator_id, creator_type="user"):
    """Upload an asset and return the operation info."""
    log(f"Uploading {asset_type}: {filepath}")

    cmd = [
        "rbxcloud", "assets", "create",
        "--asset-type", asset_type,
        "--display-name", display_name,
        "--description", description,
        "--creator-id", creator_id,
        "--creator-type", creator_type,
        "--filepath", str(filepath),
        "--api-key", api_key,
        "--pretty"
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        log(f"ERROR: {result.stderr}")
        return None

    try:
        data = json.loads(result.stdout)
        log(f"  Operation: {data.get('path', 'unknown')}")
        return data
    except json.JSONDecodeError:
        log(f"  Response: {result.stdout}")
        return {"raw": result.stdout}

def get_operation_status(operation_path, api_key):
    """Check operation status and get asset ID when done."""
    cmd = [
        "rbxcloud", "assets", "get-operation",
        "--operation-id", operation_path,
        "--api-key", api_key,
        "--pretty"
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        return None

    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        return None

def wait_for_asset(operation_path, api_key, timeout=120):
    """Poll operation until asset is ready."""
    log(f"Waiting for asset processing...")
    start = time.time()

    while time.time() - start < timeout:
        status = get_operation_status(operation_path, api_key)
        if status and status.get("done"):
            if "response" in status:
                asset_id = status["response"].get("assetId")
                log(f"  Asset ready: {asset_id}")
                return asset_id
            elif "error" in status:
                log(f"  ERROR: {status['error']}")
                return None
        time.sleep(2)

    log("  TIMEOUT waiting for asset")
    return None

def upload_workflow(scene_name, exports_dir, api_key, creator_id):
    """Upload FBX and textures, return asset IDs."""
    exports_path = Path(exports_dir)

    results = {
        "scene": scene_name,
        "version": VERSION,
        "assets": {}
    }

    # Upload FBX model
    fbx_file = exports_path / f"{scene_name}.fbx"
    if fbx_file.exists():
        log(f"Found FBX: {fbx_file}")
        op = upload_asset(
            fbx_file, "model-fbx",
            f"{scene_name} Model",
            f"Animated {scene_name} from Blender",
            api_key, creator_id
        )
        if op and "path" in op:
            asset_id = wait_for_asset(op["path"], api_key)
            if asset_id:
                results["assets"]["model"] = asset_id
    else:
        log(f"No FBX found at {fbx_file}")

    # Upload PBR textures
    texture_types = {
        "ColorMap": "decal-png",
        "NormalMap": "decal-png",
        "RoughnessMap": "decal-png",
        "MetalnessMap": "decal-png"
    }

    for tex_name, asset_type in texture_types.items():
        # Check multiple naming patterns
        patterns = [
            f"{scene_name}_{tex_name}.png",
            f"{scene_name.replace('_', '')}_{tex_name}.png",
            f"Body_{tex_name}.png"  # Common Blender export name
        ]

        tex_file = None
        for pattern in patterns:
            candidate = exports_path / "textures" / pattern
            if candidate.exists():
                tex_file = candidate
                break
            candidate = exports_path / pattern
            if candidate.exists():
                tex_file = candidate
                break

        if tex_file:
            log(f"Found texture: {tex_file}")
            op = upload_asset(
                tex_file, asset_type,
                f"{scene_name} {tex_name}",
                f"{tex_name} texture for {scene_name}",
                api_key, creator_id
            )
            if op and "path" in op:
                asset_id = wait_for_asset(op["path"], api_key)
                if asset_id:
                    results["assets"][tex_name] = asset_id
        else:
            log(f"No {tex_name} texture found")

    return results

def load_env_file(env_path=".env"):
    """Load environment variables from .env file."""
    env_vars = {}
    if os.path.exists(env_path):
        with open(env_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    env_vars[key.strip()] = value.strip()
    return env_vars

def main():
    print(f"=== Upload to Roblox v{VERSION} ===")

    parser = argparse.ArgumentParser(description="Upload assets to Roblox Cloud")
    parser.add_argument("--scene", required=True, help="Scene name")
    parser.add_argument("--exports-dir", default="exports", help="Exports directory")
    parser.add_argument("--output", help="Output JSON file for asset IDs")

    args = parser.parse_args()

    # Load env from file first, then check environment
    env_file = load_env_file()
    api_key = os.environ.get("ROBLOX_API_KEY") or env_file.get("ROBLOX_API_KEY")
    creator_id = os.environ.get("ROBLOX_CREATOR_ID") or env_file.get("ROBLOX_CREATOR_ID", "5514421781")

    if not api_key:
        log("ERROR: ROBLOX_API_KEY not set")
        log("Run: source .env")
        sys.exit(1)

    results = upload_workflow(args.scene, args.exports_dir, api_key, creator_id)

    # Output results
    print("\n=== UPLOAD RESULTS ===")
    print(json.dumps(results, indent=2))

    if args.output:
        with open(args.output, 'w') as f:
            json.dump(results, f, indent=2)
        log(f"Saved to {args.output}")

    # Generate MCP command
    if results["assets"]:
        print("\n=== MCP SETUP COMMAND ===")
        print("Use these asset IDs in MCP run_code to setup SurfaceAppearance:")
        for name, asset_id in results["assets"].items():
            print(f"  {name}: rbxassetid://{asset_id}")

if __name__ == "__main__":
    main()
