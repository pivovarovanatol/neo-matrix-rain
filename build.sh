#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
SAVER_NAME="NeoMatrixRain"
SAVER_BUNDLE="$BUILD_DIR/$SAVER_NAME.saver"

echo "==> Cleaning..."
rm -rf "$BUILD_DIR"
mkdir -p "$SAVER_BUNDLE/Contents/MacOS"

SDK="$(xcrun --sdk macosx --show-sdk-path)"
ARCH="$(uname -m)"
TARGET="${ARCH}-apple-macos12.0"

echo "==> Compiling ($ARCH)..."
swiftc \
    -parse-as-library \
    -module-name "$SAVER_NAME" \
    -target "$TARGET" \
    -sdk "$SDK" \
    -framework ScreenSaver \
    -framework Cocoa \
    -Xlinker -bundle \
    "$SCRIPT_DIR/Sources/NeoMatrixView.swift" \
    -o "$SAVER_BUNDLE/Contents/MacOS/$SAVER_NAME"

echo "==> Copying resources..."
# ditto preserves no unwanted metadata that blocks codesign
ditto "$SCRIPT_DIR/Info.plist" "$SAVER_BUNDLE/Contents/Info.plist"

echo "==> Signing..."
# Strip extended attributes the compiler leaves behind
xattr -cr "$SAVER_BUNDLE"
xattr -c  "$SAVER_BUNDLE/Contents/MacOS/$SAVER_NAME"
codesign --force --sign - "$SAVER_BUNDLE/Contents/MacOS/$SAVER_NAME"
codesign --force --sign - "$SAVER_BUNDLE"

echo "==> Installing to ~/Library/Screen Savers/..."
rm -rf ~/Library/Screen\ Savers/"$SAVER_NAME.saver"
ditto "$SAVER_BUNDLE" ~/Library/Screen\ Savers/"$SAVER_NAME.saver"

echo ""
echo "Done. Open System Settings → Screen Saver and select 'Neo Matrix Rain'."
