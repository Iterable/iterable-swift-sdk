#!/bin/sh

rm -rf "build"

xcodebuild -target "swift-sdk" -configuration Release ONLY_ACTIVE_ARCH=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES BUILD_DIR="build" BUILD_ROOT="build" BITCODE_GENERATION_MODE=bitcode build -sdk iphoneos
xcodebuild -target "swift-sdk" -configuration Release ONLY_ACTIVE_ARCH=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES BUILD_DIR="build" BUILD_ROOT="build" BITCODE_GENERATION_MODE=bitcode build -sdk iphonesimulator
xcodebuild -target "notification-extension" -configuration Release ONLY_ACTIVE_ARCH=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES BUILD_DIR="build" BUILD_ROOT="build" BITCODE_GENERATION_MODE=bitcode build -sdk iphoneos
xcodebuild -target "notification-extension" -configuration Release ONLY_ACTIVE_ARCH=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES BUILD_DIR="build" BUILD_ROOT="build" BITCODE_GENERATION_MODE=bitcode build -sdk iphonesimulator

xcodebuild -create-xcframework -output "build/IterableSDK.xcframework" -framework "build/Release-iphoneos/IterableSDK.framework" -framework "build/Release-iphonesimulator/IterableSDK.framework"
xcodebuild -create-xcframework -output "build/IterableAppExtensions.xcframework" -framework "build/Release-iphoneos/IterableAppExtensions.framework" -framework  "build/Release-iphonesimulator/IterableAppExtensions.framework"

zip -r "build/IterableSDK.zip" "build/IterableSDK.xcframework"
zip -r "build/IterableAppExtensions.zip" "build/IterableAppExtensions.xcframework"