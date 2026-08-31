//
//  Copyright © 2026 Iterable. All rights reserved.
//

import Foundation

/// The outcome of `IterableAPI.switchProject(project:callback:)`.
///
/// Both cases mean the SDK is on the new project. They differ only in whether leaving the previous
/// project was tidy. Neither is a failure, and neither is a reason to retry the switch or to show the
/// user an error: the response to both is the same, carry on and re-identify the user.
@objc
public enum IterableProjectSwitchResult: Int {
    /// Every teardown step completed cleanly at the point the callback fired.
    ///
    /// This is not a guarantee that the outgoing project's device disable reached the network. The
    /// disable is handed to the request layer, which may queue it for later delivery, and the callback
    /// is not held open for the response.
    case switchedCleanly

    /// The SDK is on the new project, but leaving the previous one was not completely tidy: either a
    /// cleanup step was noisy, or no device disable could be confirmed for the previous project.
    ///
    /// This is expected in normal operation rather than exceptional. An app that does not use push
    /// registration, or that has no device token yet, will always see it, because there was no device
    /// disable to confirm. Check the logs for the specific step if you need to know which one it was.
    case switchedWithWarnings

    /// Internal plumbing carries a boolean for "was the teardown clean", set by the individual
    /// teardown steps. This converts at the callback boundary so the public contract is the named
    /// result rather than a boolean whose meaning has to be explained.
    static func from(cleanTeardown: Bool) -> IterableProjectSwitchResult {
        cleanTeardown ? .switchedCleanly : .switchedWithWarnings
    }
}
