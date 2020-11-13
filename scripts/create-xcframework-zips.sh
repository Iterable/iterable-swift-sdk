#!/bin/sh

if [ ! -d *".xcodeproj" ]
then
    echo "ERROR: no Xcode project file exists at this path to make builds from"
    exit 1
fi

OUTPUT_FOLDER=build

rm -rf "${OUTPUT_FOLDER}"

xcodebuild -target "swift-sdk" -configuration Release ONLY_ACTIVE_ARCH=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES BUILD_DIR="${OUTPUT_FOLDER}" BUILD_ROOT="${OUTPUT_FOLDER}" BITCODE_GENERATION_MODE=bitcode build -sdk iphoneos
xcodebuild -target "swift-sdk" -configuration Release ONLY_ACTIVE_ARCH=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES BUILD_DIR="${OUTPUT_FOLDER}" BUILD_ROOT="${OUTPUT_FOLDER}" BITCODE_GENERATION_MODE=bitcode build -sdk iphonesimulator
xcodebuild -target "notification-extension" -configuration Release ONLY_ACTIVE_ARCH=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES BUILD_DIR="${OUTPUT_FOLDER}" BUILD_ROOT="${OUTPUT_FOLDER}" BITCODE_GENERATION_MODE=bitcode build -sdk iphoneos
xcodebuild -target "notification-extension" -configuration Release ONLY_ACTIVE_ARCH=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES BUILD_DIR="${OUTPUT_FOLDER}" BUILD_ROOT="${OUTPUT_FOLDER}" BITCODE_GENERATION_MODE=bitcode build -sdk iphonesimulator

xcodebuild -create-xcframework \
-output "${OUTPUT_FOLDER}/IterableSDK.xcframework" \
-framework "${OUTPUT_FOLDER}/Release-iphoneos/IterableSDK.framework" \
-framework "${OUTPUT_FOLDER}/Release-iphonesimulator/IterableSDK.framework"

xcodebuild -create-xcframework \
-output "${OUTPUT_FOLDER}/IterableAppExtensions.xcframework" \
-framework "${OUTPUT_FOLDER}/Release-iphoneos/IterableAppExtensions.framework" \
-framework  "${OUTPUT_FOLDER}/Release-iphonesimulator/IterableAppExtensions.framework"

cd "${OUTPUT_FOLDER}"

zip -r "IterableSDK.xcframework.zip" "IterableSDK.xcframework"
zip -r "IterableAppExtensions.xcframework.zip" "IterableAppExtensions.xcframework"

swift package compute-checksum "IterableSDK.xcframework.zip"
swift package compute-checksum "IterableAppExtensions.xcframework.zip"

echo "end"