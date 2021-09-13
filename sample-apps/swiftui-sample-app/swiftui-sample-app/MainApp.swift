import SwiftUI

@main
struct MainApp: App {
  @UIApplicationDelegateAdaptor
  private var appDelegate: AppDelegate
 
  init() {
    // Ask for permission for notifications and setup delegate
    NotificationsHelper.shared.setupNotifications()
    
    IterableHelper.initialize()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb){ userActivity in
          guard let url = userActivity.webpageURL else {
              return
          }
          
          return IterableHelper.handle(universalLink: url)
        }
    }
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                   fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    IterableHelper.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }
  
  func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
      IterableHelper.register(token: deviceToken)
  }
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    fatalError()
  }
}
