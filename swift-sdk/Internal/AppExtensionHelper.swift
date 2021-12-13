//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation
import UIKit

final class AppExtensionHelper {
    static var application: UIApplication? {
        sharedInstance?.appWrapper.provideApp()
    }
    
    static var applicationStateProvider: ApplicationStateProviderProtocol {
        sharedInstance?.appWrapper.provideApp() ?? FallbackApplcationStateProvider()
    }
    
    static func open(url: URL) {
        sharedInstance?.appWrapper.openUrl(url: url)
    }

    @available(iOSApplicationExtension, unavailable)
    static func initialize() {
        sharedInstance = AppExtensionHelper(appWrapper: AppWrapper())
    }

    static func initialize(appWrapper: AppWrapperProtocol) {
        sharedInstance = AppExtensionHelper(appWrapper: appWrapper)
    }

    private init(appWrapper: AppWrapperProtocol) {
        self.appWrapper = appWrapper
    }
    
    private let appWrapper: AppWrapperProtocol
    private static var sharedInstance: AppExtensionHelper?
    
    private class FallbackApplcationStateProvider: ApplicationStateProviderProtocol {
        let applicationState = UIApplication.State.active
    }
}

protocol AppWrapperProtocol {
    func openUrl(url: URL)
    func provideApp() -> UIApplication
}

@available(iOSApplicationExtension, unavailable)
class AppWrapper: AppWrapperProtocol {
    func openUrl(url: URL) {
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                ITBError("Could not open url: \(url)")
            }
        }
    }
    
    func provideApp() -> UIApplication {
        UIApplication.shared
    }
}

