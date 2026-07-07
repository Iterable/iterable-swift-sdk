import UIKit
import FirebaseCore
import FirebaseMessaging
import IterableSDK

/// Registers this device with Iterable via FCM (platform GCM) instead of direct APNS.
///
/// Flow: enable FCM mode -> request push authorization -> APNS token arrives in AppDelegate and is
/// handed to Firebase -> Firebase mints an FCM registration token -> that token is registered with
/// Iterable via `IterableAPI.register(fcmToken:)`. Requires GoogleService-Info.plist in the bundle
/// and an FCM push integration for this app in the Iterable project.
final class FCMRegistrationManager: NSObject {

    static let shared = FCMRegistrationManager()

    /// Iterable push integration name for the FCM path. A separate integration entry from the
    /// APNS one (Iterable allows one credential per mobile-app entry), holding the Firebase
    /// service-account (GCM) credential. The Firebase app itself keeps the real bundle ID.
    static let fcmIntegrationName = "com.sumeru.IterableSDK-Integration-Tester-Firebase"

    private static let fcmModeKey = "bcit_fcm_registration_mode"
    private static let fcmTokenKey = "IterableFCMToken"

    private(set) var isFcmModeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.fcmModeKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.fcmModeKey) }
    }

    var lastFcmToken: String? {
        UserDefaults.standard.string(forKey: Self.fcmTokenKey)
    }

    /// Call from `didFinishLaunching`. If FCM mode was enabled in a previous session, configures
    /// Firebase up front so the APNS token that arrives during startup registration is forwarded
    /// to FCM instead of being dropped. No-op when FCM mode is off (keeps APNS-only runs Firebase-free).
    func configureAtLaunchIfNeeded() {
        guard isFcmModeEnabled,
              Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else { return }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 [FCM] FirebaseApp configured at launch (FCM mode persisted on)")
        }
        Messaging.messaging().delegate = self
    }

    /// Kicks off FCM-based registration. Calls back with a user-presentable result message.
    func registerViaFCM(completion: @escaping (Bool, String) -> Void) {
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            completion(false, "GoogleService-Info.plist not found in the app bundle. Add the Firebase iOS app config for this bundle ID first.")
            return
        }

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 [FCM] FirebaseApp configured")
        }

        Messaging.messaging().delegate = self
        isFcmModeEnabled = true
        pendingCompletion = completion

        // Re-initialize the SDK so the config picks up the FCM integration name
        // (the config built at launch used the bundle-ID fallback while FCM mode was off).
        AppDelegate.reinitializeSDKWithCurrentMode()

        // Request authorization + APNS registration; AppDelegate forwards the APNS token to
        // Firebase via handleApnsToken(_:) because FCM mode is now enabled.
        AppDelegate.registerForPushNotifications()
        print("🔥 [FCM] FCM mode enabled; waiting for APNS token to mint FCM token")
    }

    /// Called from AppDelegate when the APNS device token arrives and FCM mode is enabled.
    func handleApnsToken(_ deviceToken: Data) {
        guard isFcmModeEnabled, FirebaseApp.app() != nil else { return }
        Messaging.messaging().apnsToken = deviceToken
        print("🔥 [FCM] APNS token handed to Firebase; fetching FCM registration token")
        fetchAndRegisterFcmToken()
    }

    private var pendingCompletion: ((Bool, String) -> Void)?

    private func fetchAndRegisterFcmToken() {
        Messaging.messaging().token { [weak self] token, error in
            if let error = error {
                print("❌ [FCM] Failed to fetch FCM token: \(error.localizedDescription)")
                self?.finish(false, "Failed to fetch FCM token: \(error.localizedDescription)")
                return
            }
            guard let token = token else {
                self?.finish(false, "Firebase returned no FCM token")
                return
            }
            self?.registerWithIterable(fcmToken: token)
        }
    }

    private func registerWithIterable(fcmToken: String) {
        print("🔥 [FCM] Registering FCM token with Iterable (platform GCM): \(fcmToken.prefix(16))...")
        UserDefaults.standard.set(fcmToken, forKey: Self.fcmTokenKey)
        IterableAPI.register(fcmToken: fcmToken, onSuccess: { [weak self] _ in
            print("✅ [FCM] FCM token registered with Iterable")
            self?.finish(true, "Registered via FCM (platform GCM).\nToken: \(fcmToken.prefix(24))...")
        }, onFailure: { [weak self] reason, _ in
            print("❌ [FCM] Iterable registration failed: \(reason ?? "unknown")")
            self?.finish(false, "Iterable registration failed: \(reason ?? "unknown")")
        })
    }

    private func finish(_ success: Bool, _ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.pendingCompletion?(success, message)
            self?.pendingCompletion = nil
        }
    }
}

extension FCMRegistrationManager: MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard isFcmModeEnabled, let fcmToken = fcmToken else { return }
        // Fires on token refresh; keep Iterable in sync with the current token.
        print("🔥 [FCM] didReceiveRegistrationToken: \(fcmToken.prefix(16))...")
        registerWithIterable(fcmToken: fcmToken)
    }
}
