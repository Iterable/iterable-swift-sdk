#!/bin/sh

if [ ! -d *".xcodeproj" ]
then
    echo "ERROR: no Xcode project file exists at this path to make builds from"
    exit 1
fi

OUTPUT_FOLDER=build2
CURRENT_FOLDER=`pwd`
FULL_OUTPUT_PATH=${CURRENT_FOLDER}/${OUTPUT_FOLDER}

rm -rf "${OUTPUT_FOLDER}"

# -destination="iOS" -- seems like "-sdk iphoneos" is needed and not this?
# proper format might be -destination "generic/platform=iOS"
xcodebuild archive -scheme "swift-sdk" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES BITCODE_GENERATION_MODE=bitcode -archivePath "./${OUTPUT_FOLDER}/IterableSDK-iOS" -sdk iphoneos

# -destination="iOS Simulator" -- seems like "-sdk iphonesimulator" is needed and not this?
# proper format might be -destination "generic/platform=iOS Simulator"
xcodebuild archive -scheme "swift-sdk" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES BITCODE_GENERATION_MODE=bitcode -archivePath "./${OUTPUT_FOLDER}/IterableSDK-Simulator" -sdk iphonesimulator

# create IterableSDK.xcframework
# -debug-symbols requires a full path specified
# TODO: add the contents of BCSymbolMaps as -debug-symbols parameters -- maybe like in https://developer.apple.com/forums/thread/655768?answerId=645657022#645657022
xcodebuild -create-xcframework \
    -output "./${OUTPUT_FOLDER}/IterableSDK.xcframework" \
    -framework "./${OUTPUT_FOLDER}/IterableSDK-iOS.xcarchive/Products/Library/Frameworks/IterableSDK.framework" \
    -debug-symbols "${FULL_OUTPUT_PATH}/IterableSDK-iOS.xcarchive/dSYMs/IterableSDK.framework.dSYM" \
    -framework "./${OUTPUT_FOLDER}/IterableSDK-Simulator.xcarchive/Products/Library/Frameworks/IterableSDK.framework" \
    -debug-symbols "${FULL_OUTPUT_PATH}/IterableSDK-Simulator.xcarchive/dSYMs/IterableSDK.framework.dSYM" \

# create IterableAppExtensions.xcframework
# -debug-symbols requires a full path specified
# TODO: add the contents of BCSymbolMaps as -debug-symbols parameters -- maybe like in https://developer.apple.com/forums/thread/655768?answerId=645657022#645657022
xcodebuild -create-xcframework \
    -output "./${OUTPUT_FOLDER}/IterableAppExtensions.xcframework" \
    -framework "./${OUTPUT_FOLDER}/IterableSDK-iOS.xcarchive/Products/Library/Frameworks/IterableAppExtensions.framework" \
    -debug-symbols "${FULL_OUTPUT_PATH}/IterableSDK-Simulator.xcarchive/dSYMs/IterableAppExtensions.framework.dSYM" \
    -framework "./${OUTPUT_FOLDER}/IterableSDK-Simulator.xcarchive/Products/Library/Frameworks/IterableAppExtensions.framework" \
    -debug-symbols "${FULL_OUTPUT_PATH}/IterableSDK-Simulator.xcarchive/dSYMs/IterableAppExtensions.framework.dSYM" \

# create zips of both XCFrameworks
cd "${OUTPUT_FOLDER}"

zip -r -q "IterableSDK.xcframework.zip" "IterableSDK.xcframework"
zip -r -q "IterableAppExtensions.xcframework.zip" "IterableAppExtensions.xcframework"

echo "----------------------------------------------------------------"

swift package compute-checksum "IterableSDK.xcframework.zip"
swift package compute-checksum "IterableAppExtensions.xcframework.zip"

echo "----------------------------------------------------------------"