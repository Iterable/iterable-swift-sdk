import Foundation

final class IterableAPIMobileFrameworkDetector {
    private struct FrameworkClasses {
        static let flutter = [
            "FlutterViewController",
            "GeneratedPluginRegistrant",
            "FlutterEngine",
            "FlutterPluginRegistry"
        ]
        
        static let reactNative = [
            "RCTBridge",
            "RCTRootView",
            "RCTBundleURLProvider",
            "RCTEventEmitter"
        ]
    }
    
    private struct BundleIdentifiers {
        static let executableKey = "CFBundleExecutable"
        static let flutterTargetKey = "FlutterDeploymentTarget"
        static let reactNativeProviderKey = "RNBundleURLProvider"
        static let flutterExecutableName = "Runner"
    }
    
    private static var cachedFrameworkType: IterableAPIMobileFrameworkType = {
        detectFramework()
    }()
    
    static func detectFramework() -> IterableAPIMobileFrameworkType {
        let bundle = Bundle.main
        
        // Helper function to check for framework classes
        func hasFrameworkClasses(_ classNames: [String]) -> Bool {
            guard !classNames.isEmpty else { return false }
            return classNames.contains { className in
                guard IterableUtil.isNotNullOrEmpty(string: className) else { return false }
                return bundle.classNamed(className) != nil
            }
        }
        
        // Safely check frameworks
        let hasFlutter = hasFrameworkClasses(FrameworkClasses.flutter)
        let hasReactNative = hasFrameworkClasses(FrameworkClasses.reactNative)
        
        switch (hasFlutter, hasReactNative) {
            case (true, true):
                ITBError("Both Flutter and React Native frameworks detected. This is unexpected.")
                if let mainBundle = Bundle.main.infoDictionary,
                   let executableName = mainBundle[BundleIdentifiers.executableKey] as? String,
                   !executableName.isEmpty,
                   executableName == BundleIdentifiers.flutterExecutableName {
                    return .flutter
                } else {
                    return .reactNative
                }
                
            case (true, false):
                return .flutter
                
            case (false, true):
                return .reactNative
                
            case (false, false):
                if let mainBundle = Bundle.main.infoDictionary {
                    if let _ = mainBundle[BundleIdentifiers.flutterTargetKey] as? String {
                        return .flutter
                    }
                    if let _ = mainBundle[BundleIdentifiers.reactNativeProviderKey] as? String {
                        return .reactNative
                    }
                }
                return .native
        }
    }
    
    public static func frameworkType() -> IterableAPIMobileFrameworkType {
        return cachedFrameworkType
    }
}
