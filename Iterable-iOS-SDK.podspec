Pod::Spec.new do |s|
  s.name         = "Iterable-iOS-SDK"
  s.module_name  = "IterableSDK"
  s.version      = "6.2.2"
  s.summary      = "Iterable's official SDK for iOS"

  s.description  = <<-DESC
                   iOS SDK containing a wrapper around Iterable's API, in addition
                   to some utility functions
                   DESC

  s.homepage     = "https://github.com/Iterable/swift-sdk.git"
  s.license      = "MIT"
  s.author       = { "Tapash Majumder" => "tapash@iterable.com",
                     "Jay Kim" => "jay.kim@iterable.com" }

  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/Iterable/swift-sdk.git", :tag => s.version }
  s.source_files = "swift-sdk/**/*.{h,m,swift}"

  s.resource_bundles = {'Iterable-iOS-SDK' => 'swift-sdk/Resources/**/*.{storyboard,xib,xcassets}' }

  s.pod_target_xcconfig = {
    'SWIFT_VERSION' => '5.2'
  }

  s.swift_version = '5.2'
end
