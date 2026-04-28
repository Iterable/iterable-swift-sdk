//
//  Untitled.swift
//  swift-sdk
//
//  Created by Evan Greer on 9/19/24.
//  Copyright © 2024 Iterable. All rights reserved.
//

import Foundation
@objc public class IterableIdentityResolution: NSObject {

    /// When true, replays locally saved visitor data to the known user profile on identification.
    public var replayOnVisitorToKnown: Bool?

    /// When true, merges the unknown user profile with the known user profile on identification.
    public let mergeOnUnknownToKnown: Bool?

    public init(replayOnVisitorToKnown: Bool?,
                mergeOnUnknownToKnown: Bool?) {
        self.replayOnVisitorToKnown = replayOnVisitorToKnown
        self.mergeOnUnknownToKnown = mergeOnUnknownToKnown
    }

    // MARK: - Deprecated alias (remove in next major)

    /// - Note: This property is kept for backward compatibility. Use ``mergeOnUnknownToKnown`` instead.
    @available(*, deprecated, renamed: "mergeOnUnknownToKnown")
    public var mergeOnUnknownUserToKnown: Bool? { mergeOnUnknownToKnown }

    @available(*, deprecated, renamed: "init(replayOnVisitorToKnown:mergeOnUnknownToKnown:)")
    public convenience init(replayOnVisitorToKnown: Bool?,
                            mergeOnUnknownUserToKnown: Bool?) {
        self.init(replayOnVisitorToKnown: replayOnVisitorToKnown,
                  mergeOnUnknownToKnown: mergeOnUnknownUserToKnown)
    }
}
