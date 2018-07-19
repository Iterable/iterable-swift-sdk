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
xcodebuild -target "${TARGET}" ONLY_ACTIVE_ARCH=NO -configuration ${CONFIGURATION} -sdk iphoneos  BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_DIR}" clean build
xcodebuild -target "${TARGET}" -configuration ${CONFIGURATION} -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_DIR}" clean build

# Step 2. Copy the framework structure (from iphoneos build) to the universal folder
cp -R "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${MODULE_NAME}.framework" "${UNIVERSAL_OUTPUTFOLDER}/"

# Step 3. Copy Swift modules from iphonesimulator build (if it exists) to the copied framework directory
SIMULATOR_SWIFT_MODULES_DIR="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${MODULE_NAME}.framework/Modules/${MODULE_NAME}.swiftmodule/."
if [ -d "${SIMULATOR_SWIFT_MODULES_DIR}" ]; then
cp -R "${SIMULATOR_SWIFT_MODULES_DIR}" "${UNIVERSAL_OUTPUTFOLDER}/${MODULE_NAME}.framework/Modules/${MODULE_NAME}.swiftmodule"
fi

# Step 4. Create universal binary file using lipo and place the combined executable in the copied framework directory
lipo -create -output "${UNIVERSAL_OUTPUTFOLDER}/${MODULE_NAME}.framework/${MODULE_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${MODULE_NAME}.framework/${MODULE_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${MODULE_NAME}.framework/${MODULE_NAME}"

# Step 5. Convenience step to copy the framework to the build directory
cp -R "${UNIVERSAL_OUTPUTFOLDER}/${MODULE_NAME}.framework" "${BUILD_DIR}"
