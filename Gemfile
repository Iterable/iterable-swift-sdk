source "https://rubygems.org"

# Pinned to the current minor to allow patch-level bug fixes while protecting
# release day from a major-version upstream regression. Bump the ceiling
# intentionally as a separate change after testing locally.
gem "cocoapods", "~> 1.16"
gem "fastlane",  "~> 2.236"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
