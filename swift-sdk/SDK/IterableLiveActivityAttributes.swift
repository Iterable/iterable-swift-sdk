//
//  Copyright © 2025 Iterable. All rights reserved.
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

#if canImport(ActivityKit)
@available(iOS 16.1, *)
/// Attributes for the Iterable Live Activity.
///
/// To use this in your Widget Extension:
/// 1. Import IterableSDK
/// 2. Create an `ActivityConfiguration` using `IterableLiveActivityAttributes`:
///
/// ```swift
/// struct MyLiveActivityWidget: Widget {
///     var body: some WidgetConfiguration {
///         ActivityConfiguration(for: IterableLiveActivityAttributes.self) { context in
///             // ... Build your UI using context.state (ContentState) ...
///         } dynamicIsland: { context in
///             // ... Build your Dynamic Island UI ...
///         }
///     }
/// }
/// ```
public struct IterableLiveActivityAttributes: ActivityAttributes, Codable {
    public struct ContentState: Codable, Hashable {
        public var vital: String
        public var duration: TimeInterval
        public var title: String
        
        public init(vital: String, duration: TimeInterval, title: String) {
            self.vital = vital
            self.duration = duration
            self.title = title
        }
    }
    
    public init() {}
}
#endif

