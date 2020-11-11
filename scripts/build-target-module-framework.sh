#!/bin/sh

print_usage() {
    echo Usage `basename $0` target_name module_name
    exit 1
}

if [ "$1" == "" ] || [ "$2" == "" ]; then
    print_usage
fi

TARGET="$1"
MODULE_NAME="$2"
BUILD_DIR=build
CONFIGURATION=Release
UNIVERSAL_OUTPUTFOLDER=${BUILD_DIR}/${CONFIGURATION}-universal

# make sure the output directory exists
mkdir -p "${UNIVERSAL_OUTPUTFOLDER}"

# Step 1. Build Device and Simulator versions
xcodebuild -target "${TARGET}" -configuration ${CONFIGURATION} ONLY_ACTIVE_ARCH=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_DIR}" BITCODE_GENERATION_MODE=bitcode clean build -sdk iphoneos
xcodebuild -target "${TARGET}" -configuration ${CONFIGURATION} ONLY_ACTIVE_ARCH=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_DIR}" BITCODE_GENERATION_MODE=bitcode EXCLUDED_ARCHS="arm64" clean build -sdk iphonesimulator

# Step 2. Copy the framework structure (from iphoneos build) to the universal folder
cp -R "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${MODULE_NAME}.framework" "${UNIVERSAL_OUTPUTFOLDER}/"

# Step 3. Copy Swift modules from iphonesimulator build (if it exists) to the copied framework directory
SIMULATOR_SWIFT_MODULES_DIR="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${MODULE_NAME}.framework/Modules/${MODULE_NAME}.swiftmodule/."
if [ -d "${SIMULATOR_SWIFT_MODULES_DIR}" ]; then
    cp -R "${SIMULATOR_SWIFT_MODULES_DIR}" "${UNIVERSAL_OUTPUTFOLDER}/${MODULE_NAME}.framework/Modules/${MODULE_NAME}.swiftmodule"
fi

# Step 4. Create universal binary file using lipo and place the combined executable in the copied framework directory
lipo -create -output "${UNIVERSAL_OUTPUTFOLDER}/${MODULE_NAME}.framework/${MODULE_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${MODULE_NAME}.framework/${MODULE_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${MODULE_NAME}.framework/${MODULE_NAME}"

# Step 4.5 Xcode10.2 Fix IterableSDK-Swift.h
# Workaround for known issue in Xcode 10.2: https://developer.apple.com/documentation/xcode_release_notes/xcode_10_2_release_notes#3136806
# Merge the simulator and device headers for the now-merged framework.
DEVICE_HEADER_PATH="${BUILD_DIR}/${CONFIGURATION}-iphoneos/${MODULE_NAME}.framework/Headers/${MODULE_NAME}-Swift.h"
SIMULATOR_HEADER_PATH="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${MODULE_NAME}.framework/Headers/${MODULE_NAME}-Swift.h"
OUTPUT_HEADER_PATH="${UNIVERSAL_OUTPUTFOLDER}/${MODULE_NAME}.framework/Headers/${MODULE_NAME}-Swift.h"
cat "${DEVICE_HEADER_PATH}" > "${OUTPUT_HEADER_PATH}"
cat "${SIMULATOR_HEADER_PATH}" >> "${OUTPUT_HEADER_PATH}"

# Step 5. Convenience step to copy the framework to the build directory
cp -R "${UNIVERSAL_OUTPUTFOLDER}/${MODULE_NAME}.framework" "${BUILD_DIR}"
