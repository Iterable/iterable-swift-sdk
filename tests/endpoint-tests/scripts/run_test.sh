#!/bin/bash

set -eo pipefail

e2e_folder=./tests/endpoint-tests
scripts_folder=$e2e_folder/scripts
env_vars_file=$scripts_folder/env_vars.sh
echo env_vars_file=$env_vars_file
if [ -f $env_vars_file ]
then
  echo env vars exist 
  source $env_vars_file
fi

echo Generating CI.swift
sed -e "s/\(apiKey = \).*$/\1\"$api_key\"/" \
-e "s/\(serverApiKey = \).*$/\1\"$server_api_key\"/" \
-e "s/\(pushCampaignId = \).*$/\1\NSNumber($push_campaign_id)/" \
-e "s/\(pushTemplateId = \).*$/\1\NSNumber($push_template_id)/" \
-e "s/\(inAppCampaignId = \).*$/\1\NSNumber($in_app_campaign_id)/" \
-e "s/\(inAppTemplateId = \).*$/\1\NSNumber($in_app_template_id)/" $e2e_folder/CI.swift.template > $e2e_folder/CI.swift

echo "Available runtimes:"
xcrun simctl list runtimes

echo "Detecting latest available iOS version..."
# First try to find iOS 18.x that's available
LATEST_IOS=$(xcrun simctl list runtimes | grep "iOS 18" | grep -v "watchOS" | grep -v "beta" | grep -v "Beta" | grep -v "unavailable" | tail -1 | sed 's/.*iOS \([0-9]*\.[0-9]*\).*/\1/')

# If no iOS 18.x available, fall back to any available iOS version
if [ -z "$LATEST_IOS" ]; then
    echo "No iOS 18.x available, falling back to latest available iOS version..."
    LATEST_IOS=$(xcrun simctl list runtimes | grep "iOS" | grep -v "watchOS" | grep -v "beta" | grep -v "Beta" | grep -v "unavailable" | tail -1 | sed 's/.*iOS \([0-9]*\.[0-9]*\).*/\1/')
fi

echo "Using iOS version: $LATEST_IOS"

xcodebuild -project swift-sdk.xcodeproj \
           -scheme endpoint-tests \
           -sdk iphonesimulator \
           -destination "platform=iOS Simulator,OS=$LATEST_IOS,name=iPhone 16 Pro" \
           -resultBundlePath TestResults.xcresult \
           test | xcpretty