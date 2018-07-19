#!/bin/sh

BUILDER=`dirname $0`/build-target-module-framework.sh
BUILD_DIR=build

# clean build dir
rm -rf "${BUILD_DIR}"

# generate the framework files
"${BUILDER}" "swift-sdk" "IterableSDK"
"${BUILDER}" "notification-extension" "IterableAppExtensions"

# generate archive
cd "${BUILD_DIR}"
zip -r IterableSDK.zip IterableSDK.framework
zip -r IterableAppExtensions.zip IterableAppExtensions.framework

