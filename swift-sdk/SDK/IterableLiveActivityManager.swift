//
//  Copyright © 2025 Iterable. All rights reserved.
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

#if canImport(ActivityKit)
@available(iOS 16.1, *)
public class IterableLiveActivityManager: NSObject {
    public static let shared = IterableLiveActivityManager()
    
    private override init() {}
    
    public func start(
        vital: String,
        duration: TimeInterval,
        title: String,
        pushType: PushType? = nil
    ) {
        let attributes = IterableLiveActivityAttributes()
        let contentState = IterableLiveActivityAttributes.ContentState(
            vital: vital,
            duration: duration,
            title: title
        )
        
        do {
            let activity = try Activity<IterableLiveActivityAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: pushType
            )
            
            Task {
                for await pushToken in activity.pushTokenUpdates {
                    let tokenString = pushToken.map { String(format: "%02x", $0) }.joined()
                    print("Iterable Live Activity Token: \(tokenString)")
                    // TODO: Send token to Iterable
                }
            }
            
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    @available(iOS 17.2, *)
    public func getPushToStartToken() -> Data? {
        return Activity<IterableLiveActivityAttributes>.pushToStartToken
    }
}
#endif


