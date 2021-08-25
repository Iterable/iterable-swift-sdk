//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation

final class AppExtensionHelper {
    static var application: UIApplication? {
        sharedInsance?.appProvider()
    }
    
    static var applicationStateProvider: ApplicationStateProviderProtocol {
        sharedInsance ?? FallbackApplcationStateProvider()
    }
    
    static func open(url: URL) {
        sharedInsance?.urlOpener(url)
    }

    @available(iOSApplicationExtension, unavailable)
    static func initialize() {
        let urlOpener: (URL) -> Void = { url in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if !success {
                        ITBError("Could not open url: \(url)")
                    }
                }
            } else {
                _ = UIApplication.shared.openURL(url)
            }

        }
        sharedInsance = AppExtensionHelper(appProvider: UIApplication.shared,
                                           urlOpener: urlOpener)
    }

    private init(appProvider: @escaping @autoclosure () -> UIApplication,
                 urlOpener: @escaping (URL) -> Void) {
        self.appProvider = appProvider
        self.urlOpener = urlOpener
    }
    
    private let appProvider: () -> UIApplication
    private let urlOpener: (URL) -> Void

    private static var sharedInsance: AppExtensionHelper?
    
    private class FallbackApplcationStateProvider: ApplicationStateProviderProtocol {
        let applicationState = UIApplication.State.active
    }
}

extension AppExtensionHelper: ApplicationStateProviderProtocol {
    var applicationState: UIApplication.State {
        appProvider().applicationState
    }
}
