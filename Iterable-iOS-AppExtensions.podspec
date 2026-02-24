Pod::Spec.new do |s|
  s.name         = "Iterable-iOS-AppExtensions"
  s.module_name  = "IterableAppExtensions"
  s.version      = "6.6.7"
  s.summary      = "App Extensions for Iterable SDK"

  s.description  = <<-DESC
                   App extensions for rich push notifications with Iterable's iOS SDK
                   DESC

  s.homepage     = "https://github.com/Iterable/iterable-swift-sdk.git"
  s.license      = "MIT"
  s.author       = { "Jay Kim" => "jay.kim@iterable.com" }

  s.platform     = :ios, "12.0"
  s.source       = { :git => "https://github.com/Iterable/iterable-swift-sdk.git", :tag => s.version }
  s.source_files = "notification-extension/*.{h,m,swift}"

  s.documentation_url = "https://support.iterable.com/hc/en-us/articles/360035018152-Iterable-s-iOS-SDK"

  s.pod_target_xcconfig = {
    'SWIFT_VERSION' => '5.3'
  }

  s.swift_version = '5.3'
end
