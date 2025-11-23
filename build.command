#!/bin/bash


PROJECT_NAME="Neocord"
OUTPUT_FOLDER="build"
BUILD_DIR="./build"
ARCHIVE_PATH="$BUILD_DIR/${PROJECT_NAME}.xcarchive"
APP_PATH="$ARCHIVE_PATH/Products/Applications/${PROJECT_NAME}.app"
IPA_NAME="${PROJECT_NAME}.ipa"
PAYLOAD_DIR="$BUILD_DIR/Payload"

# Adjust this to your Swift 5.1.5 toolchain CFBundleIdentifier
TOOLCHAIN_ID="org.swift.5101202406041a"  

# Path to your Swift 5.1.5 dylibs
SWIFT_LIB_PATH="/Library/Developer/Toolchains/swift-5.1.5-RELEASE.xctoolchain/usr/lib/swift/iphoneos"

echo "🧹 Cleaning old build artifacts..."
rm -rf "$BUILD_DIR" "$IPA_NAME"

echo "📦 Archiving project: $PROJECT_NAME (unsigned) using Swift 5.1.5)..."

xcodebuild archive \
  -scheme "$PROJECT_NAME" \
  -configuration Release \
  -sdk iphoneos \
  TOOLCHAINS="$TOOLCHAIN_ID" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  -archivePath "$ARCHIVE_PATH" \
  clean archive

if [ ! -d "$APP_PATH" ]; then
  echo "❌ Archive failed or .app not found at $APP_PATH"
  exit 1
fi

# --- Force copy Swift 5.1.5 dylibs into the app ---
FRAMEWORKS_DIR="$APP_PATH/Frameworks"
mkdir -p "$FRAMEWORKS_DIR"
echo "📌 Overwriting Swift dylibs with Swift 5.1.5 versions..."
for dylib in "$SWIFT_LIB_PATH"/*.dylib; do
  cp -f "$dylib" "$FRAMEWORKS_DIR/"
done

# --- Update MinimumOSVersion to 6.0 ---
PLIST_PATH="$APP_PATH/Info.plist"
if [ -f "$PLIST_PATH" ]; then
  echo "🔧 Updating MinimumOSVersion to 6.0 in $PLIST_PATH..."
  /usr/libexec/PlistBuddy -c "Set :MinimumOSVersion 6.0" "$PLIST_PATH"
else
  echo "⚠️ Info.plist not found at $PLIST_PATH"
fi

echo "📦 Creating Payload directory and packaging IPA..."
rm -rf "$PAYLOAD_DIR"
mkdir -p "$PAYLOAD_DIR"
cp -R "$APP_PATH" "$PAYLOAD_DIR/"

pushd "$BUILD_DIR" >/dev/null
zip -qry "$IPA_NAME" Payload
popd >/dev/null

rm -rf "$PAYLOAD_DIR"
rm -rf "$ARCHIVE_PATH"  # delete archive files

mkdir -p "$OUTPUT_FOLDER"
mv "$BUILD_DIR/$IPA_NAME" "$OUTPUT_FOLDER/"

echo "✅ Done! IPA exported to: $OUTPUT_FOLDER/$IPA_NAME"
