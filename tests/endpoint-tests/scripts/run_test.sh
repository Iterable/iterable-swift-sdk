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
-e "s/\(pushCampaignId = \).*$/\1\NSNumber($push_campaign_id)/" \
-e "s/\(pushTemplateId = \).*$/\1\NSNumber($push_template_id)/" \
-e "s/\(inAppCampaignId = \).*$/\1\NSNumber($in_app_campaign_id)/" \
-e "s/\(inAppTemplateId = \).*$/\1\NSNumber($in_app_template_id)/" $e2e_folder/CI.swift.template > $e2e_folder/CI.swift

xcodebuild -project swift-sdk.xcodeproj \
           -scheme endpoint-tests \
           -sdk iphonesimulator \
           -destination 'platform=iOS Simulator,name=iPhone 11' \
           test | xcpretty