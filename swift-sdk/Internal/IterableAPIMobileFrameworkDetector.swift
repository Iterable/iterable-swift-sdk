import Foundation

public final class IterableAPIMobileFrameworkDetector {
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
    
    private static var cachedFrameworkType: IterableAPIMobileFrameworkType = {
        detectFramework()
    }()
    
    static func detectFramework() -> IterableAPIMobileFrameworkType {
        let bundle = Bundle.main
        
        // Helper function to check for framework classes
        func hasFrameworkClasses(_ classNames: [String]) -> Bool {
            classNames.contains { className in
                bundle.classNamed(className) != nil
            }
        }
        
        let hasFlutter = hasFrameworkClasses(FrameworkClasses.flutter)
        let hasReactNative = hasFrameworkClasses(FrameworkClasses.reactNative)
        
        switch (hasFlutter, hasReactNative) {
        case (true, true):
            ITBError("Both Flutter and React Native frameworks detected. This is unexpected.")
            if let mainBundle = Bundle.main.infoDictionary,
               mainBundle["CFBundleExecutable"] as? String == "Runner" {
                return .flutter
            }
            return .reactNative
            
        case (true, false):
            return .flutter
            
        case (false, true):
            return .reactNative
            
        case (false, false):
            if let mainBundle = Bundle.main.infoDictionary {
                if mainBundle["FlutterDeploymentTarget"] != nil {
                    return .flutter
                }
                if mainBundle["RNBundleURLProvider"] != nil {
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
