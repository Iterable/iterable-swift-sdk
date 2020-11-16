#!/bin/sh

if [ ! -d *".xcodeproj" ]
then
    echo "ERROR: no Xcode project file exists at this path to make builds from"
    exit 1
fi

OUTPUT_FOLDER=build

rm -rf "${OUTPUT_FOLDER}"

# -destination="iOS" -- seems like "-sdk iphoneos" is needed and not this?
xcodebuild archive -scheme "swift-sdk" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES BITCODE_GENERATION_MODE=bitcode -archivePath "./${OUTPUT_FOLDER}/IterableSDK-iOS" -sdk iphoneos

# -destination="iOS Simulator" -- seems like "-sdk iphonesimulator" is needed and not this?
xcodebuild archive -scheme "swift-sdk" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES BITCODE_GENERATION_MODE=bitcode -archivePath "./${OUTPUT_FOLDER}/IterableSDK-Simulator" -sdk iphonesimulator

# create IterableSDK.xcframework
xcodebuild -create-xcframework \
-output "./${OUTPUT_FOLDER}/IterableSDK.xcframework" \
-framework "./${OUTPUT_FOLDER}/IterableSDK-iOS.xcarchive/Products/Library/Frameworks/IterableSDK.framework" \
-framework "./${OUTPUT_FOLDER}/IterableSDK-Simulator.xcarchive/Products/Library/Frameworks/IterableSDK.framework"

# create IterableAppExtensions.xcframework
xcodebuild -create-xcframework \
-output "./${OUTPUT_FOLDER}/IterableAppExtensions.xcframework" \
-framework "./${OUTPUT_FOLDER}/IterableSDK-iOS.xcarchive/Products/Library/Frameworks/IterableAppExtensions.framework" \
-framework "./${OUTPUT_FOLDER}/IterableSDK-Simulator.xcarchive/Products/Library/Frameworks/IterableAppExtensions.framework"

cd "${OUTPUT_FOLDER}"

zip -r "IterableSDK.xcframework.zip" "IterableSDK.xcframework"
zip -r "IterableAppExtensions.xcframework.zip" "IterableAppExtensions.xcframework"

echo "----------------------------------------------------------------"

swift package compute-checksum "IterableSDK.xcframework.zip"
swift package compute-checksum "IterableAppExtensions.xcframework.zip"

echo "----------------------------------------------------------------"