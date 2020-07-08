#!/bin/bash

set -eo pipefail

cd ./tests/endpoint-tests
sed -e "s/\(apiKey = \).*$/\1\"$api_key\"/" \
-e "s/\(pushCampaignId = \).*$/\1\NSNumber($push_campaign_id)/" \
-e "s/\(pushTemplateId = \).*$/\1\NSNumber($push_template_id)/" \
-e "s/\(inAppCampaignId = \).*$/\1\NSNumber($in_app_campaign_id)/" \
-e "s/\(inAppTemplateId = \).*$/\1\NSNumber($in_app_template_id)/" CI.swift.template > CI.swift


