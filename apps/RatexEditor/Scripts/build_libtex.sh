#!/bin/bash
set -e

# Resolve repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "=== Building libtex (Rust C ABI) ==="
cd "$REPO_ROOT"
export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-14.0}"
cargo build --profile ffi-release -p libtex

LIB_PATH="$REPO_ROOT/target/ffi-release/libtex.a"
if [ ! -f "$LIB_PATH" ]; then
    echo "Error: Failed to find libtex.a at $LIB_PATH" >&2
    exit 1
fi

echo "Successfully verified libtex.a at $LIB_PATH"

