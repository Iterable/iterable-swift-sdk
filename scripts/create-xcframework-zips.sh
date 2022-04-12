#!/bin/bash

set -eE
trap 'printf "\e[31m%s: %s\e[m\n" "ERROR($?): $BASH_SOURCE:$LINENO $BASH_COMMAND"' ERR

if [ ! -d *".xcodeproj" ]
then
    echo "ERROR: no Xcode project file exists at this path to make builds from"
    exit 1
fi

OUTPUT_FOLDER=build2
CURRENT_FOLDER=`pwd`
FULL_OUTPUT_PATH=${CURRENT_FOLDER}/${OUTPUT_FOLDER}

rm -rf "${OUTPUT_FOLDER}"

xcodebuild archive -scheme "swift-sdk" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES BITCODE_GENERATION_MODE=bitcode SUPPORTS_MACCATALYST=NO -archivePath "./${OUTPUT_FOLDER}/IterableSDK-iOS" -sdk iphoneos -destination "generic/platform=iOS" -configuration Release
xcodebuild archive -scheme "swift-sdk" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES BITCODE_GENERATION_MODE=bitcode SUPPORTS_MACCATALYST=NO -archivePath "./${OUTPUT_FOLDER}/IterableSDK-Simulator" -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -configuration Release
xcodebuild archive -scheme "swift-sdk" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES BITCODE_GENERATION_MODE=bitcode SUPPORTS_MACCATALYST=YES -archivePath "./${OUTPUT_FOLDER}/IterableSDK-MC" -sdk iphoneos -destination "generic/platform=macOS,variant=Mac Catalyst" -configuration Release

# create IterableSDK.xcframework
# -debug-symbols requires a full path specified
# TODO: add the contents of BCSymbolMaps as -debug-symbols parameters -- maybe like in https://developer.apple.com/forums/thread/655768?answerId=645657022#645657022
xcodebuild -create-xcframework \
    -output "./${OUTPUT_FOLDER}/IterableSDK.xcframework" \
    -framework "./${OUTPUT_FOLDER}/IterableSDK-iOS.xcarchive/Products/Library/Frameworks/IterableSDK.framework" \
    -debug-symbols "${FULL_OUTPUT_PATH}/IterableSDK-iOS.xcarchive/dSYMs/IterableSDK.framework.dSYM" \
    -framework "./${OUTPUT_FOLDER}/IterableSDK-Simulator.xcarchive/Products/Library/Frameworks/IterableSDK.framework" \
    -debug-symbols "${FULL_OUTPUT_PATH}/IterableSDK-Simulator.xcarchive/dSYMs/IterableSDK.framework.dSYM" \
    -framework "./${OUTPUT_FOLDER}/IterableSDK-MC.xcarchive/Products/Library/Frameworks/IterableSDK.framework" \
    -debug-symbols "${FULL_OUTPUT_PATH}/IterableSDK-MC.xcarchive/dSYMs/IterableSDK.framework.dSYM"

# create IterableAppExtensions.xcframework
# -debug-symbols requires a full path specified
# TODO: add the contents of BCSymbolMaps as -debug-symbols parameters -- maybe like in https://developer.apple.com/forums/thread/655768?answerId=645657022#645657022
xcodebuild -create-xcframework \
    -output "./${OUTPUT_FOLDER}/IterableAppExtensions.xcframework" \
    -framework "./${OUTPUT_FOLDER}/IterableSDK-iOS.xcarchive/Products/Library/Frameworks/IterableAppExtensions.framework" \
    -debug-symbols "${FULL_OUTPUT_PATH}/IterableSDK-Simulator.xcarchive/dSYMs/IterableAppExtensions.framework.dSYM" \
    -framework "./${OUTPUT_FOLDER}/IterableSDK-Simulator.xcarchive/Products/Library/Frameworks/IterableAppExtensions.framework" \
    -debug-symbols "${FULL_OUTPUT_PATH}/IterableSDK-Simulator.xcarchive/dSYMs/IterableAppExtensions.framework.dSYM" \
    -framework "./${OUTPUT_FOLDER}/IterableSDK-MC.xcarchive/Products/Library/Frameworks/IterableAppExtensions.framework" \
    -debug-symbols "${FULL_OUTPUT_PATH}/IterableSDK-MC.xcarchive/dSYMs/IterableAppExtensions.framework.dSYM"

# create zips of both XCFrameworks
cd "${OUTPUT_FOLDER}"

zip -r -q "IterableSDK.xcframework.zip" "IterableSDK.xcframework"
zip -r -q "IterableAppExtensions.xcframework.zip" "IterableAppExtensions.xcframework"

echo "----------------------------------------------------------------"

swift package compute-checksum "IterableSDK.xcframework.zip"
swift package compute-checksum "IterableAppExtensions.xcframework.zip"

echo "----------------------------------------------------------------"
