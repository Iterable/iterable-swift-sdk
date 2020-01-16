//
//  Created by Tapash Majumder on 1/14/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import UIKit

@testable import IterableSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        DataManager.initializeIterableApi(launchOptions: launchOptions)
        
        return true
    }
}

