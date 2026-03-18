#!/bin/bash
#
# Creates a simulator .app bundle for the BCIT Integration Tester.
# The output .zip can be shared with teammates — they install it with:
#   unzip IterableSDK-Integration-Tester.zip
#   xcrun simctl install booted IterableSDK-Integration-Tester.app
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$SCRIPT_DIR/IterableSDK-Integration-Tester.xcodeproj"
SCHEME="IterableSDK-Integration-Tester"
BUILD_DIR="$SCRIPT_DIR/build"
OUTPUT_DIR="$BUILD_DIR/Build/Products/Debug-iphonesimulator"
APP_NAME="IterableSDK-Integration-Tester.app"
ZIP_NAME="IterableSDK-Integration-Tester.zip"

echo "Building $SCHEME for iOS Simulator..."

xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$BUILD_DIR" \
  ONLY_ACTIVE_ARCH=NO \
  -quiet

if [ ! -d "$OUTPUT_DIR/$APP_NAME" ]; then
  echo "Error: Build succeeded but .app not found at $OUTPUT_DIR/$APP_NAME"
  exit 1
fi

echo "Zipping .app bundle..."
cd "$OUTPUT_DIR"
rm -f "$ZIP_NAME"
zip -r "$ZIP_NAME" "$APP_NAME" -x "*.DS_Store"

echo ""
echo "Done! Simulator build is at:"
echo "  $OUTPUT_DIR/$ZIP_NAME"
echo ""
echo "To install on a simulator:"
echo "  unzip $ZIP_NAME"
echo "  xcrun simctl install booted $APP_NAME"
