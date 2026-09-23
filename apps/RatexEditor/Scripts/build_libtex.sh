#!/bin/bash
set -e

# Resolve repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ENGINE_DIR="$REPO_ROOT/vendor/ratex"

if [ ! -d "$ENGINE_DIR" ]; then
    echo "Error: Ratex submodule not found at $ENGINE_DIR" >&2
    echo "Run 'git submodule update --init --recursive' first." >&2
    exit 1
fi

echo "=== Building libtex (Rust C ABI) from vendor/ratex ==="
cd "$ENGINE_DIR"
export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-14.0}"
cargo build --profile ffi-release -p libtex

LIB_PATH="$ENGINE_DIR/target/ffi-release/libtex.a"
if [ ! -f "$LIB_PATH" ]; then
    echo "Error: Failed to find libtex.a at $LIB_PATH" >&2
    exit 1
fi

echo "Successfully verified libtex.a at $LIB_PATH"

