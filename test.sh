#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
mkdir -p "$BUILD_DIR"

SDK="$(xcrun --sdk macosx --show-sdk-path)"
ARCH="$(uname -m)"

echo "==> Compiling test app..."
swiftc \
    -target "${ARCH}-apple-macos12.0" \
    -sdk "$SDK" \
    -framework ScreenSaver \
    -framework Cocoa \
    "$SCRIPT_DIR/Sources/NeoMatrixConfig.swift" \
    "$SCRIPT_DIR/Sources/NeoMatrixConfigSheet.swift" \
    "$SCRIPT_DIR/Sources/NeoMatrixView.swift" \
    "$SCRIPT_DIR/Sources/TestApp.swift" \
    "$SCRIPT_DIR/Sources/main.swift" \
    -o "$BUILD_DIR/neo-matrix-test"

echo "==> Running..."
"$BUILD_DIR/neo-matrix-test"
