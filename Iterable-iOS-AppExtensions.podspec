Pod::Spec.new do |s|
  s.name         = "Iterable-iOS-AppExtensions"
  s.module_name  = "IterableAppExtensions"
  s.version      = "6.2.2"
  s.summary      = "App Extensions for Iterable SDK"

  s.description  = <<-DESC
                   App Extensions for Rich Push notifications with Iterable SDK
                   DESC

  s.homepage     = "https://github.com/Iterable/swift-sdk.git"
  s.license      = "MIT"
  s.author      = { "Tapash Majumder" => "tapash@iterable.com",
                    "Jay Kim" => "jay.kim@iterable.com" }

  s.platform     = :ios, "10.0"
  s.source       = { :git => "https://github.com/Iterable/swift-sdk.git", :tag => s.version }
  s.source_files  = "notification-extension/*.{h,m,swift}"

  s.pod_target_xcconfig = {
    'SWIFT_VERSION' => '5.2'
  }

  s.swift_version = '5.2'
end
