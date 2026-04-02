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
    public let mergeOnUnknownUserToKnown: Bool?

    public init(replayOnVisitorToKnown: Bool?,
                                  mergeOnUnknownUserToKnown: Bool?) {
        self.replayOnVisitorToKnown = replayOnVisitorToKnown
        self.mergeOnUnknownUserToKnown = mergeOnUnknownUserToKnown
    }
}
