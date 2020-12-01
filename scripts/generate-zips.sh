#!/bin/sh

APP_DIR=`dirname $0`/..
cd $APP_DIR
APP_DIR=`pwd`

SCRIPTS_DIR=${APP_DIR}/scripts

BUILDER=${SCRIPTS_DIR}/build-target-module-framework.sh
XCFRAMEWORK_BUILDER=${SCRIPTS_DIR}/create-xcframework-zips.sh
BUILD_DIR=${APP_DIR}/build

# clean build dir
rm -rf "${BUILD_DIR}"

# generate the framework files
"${BUILDER}" "swift-sdk" "IterableSDK"
"${BUILDER}" "notification-extension" "IterableAppExtensions"

# generate archive
cd "${BUILD_DIR}"
zip -r IterableSDK.zip IterableSDK.framework
zip -r IterableAppExtensions.zip IterableAppExtensions.framework

# create xcframework zips
cd ${APP_DIR}
${XCFRAMEWORK_BUILDER}

