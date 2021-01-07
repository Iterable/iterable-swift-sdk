//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

enum IterableTaskResult {
    case success(detail: TaskSuccessDetail?)
    case failureWithRetry(retryAfter: TimeInterval?, detail: TaskFailureDetail?)
    case failureWithNoRetry(detail: TaskFailureDetail?)
}

protocol TaskSuccessDetail {}

extension SendRequestValue: TaskSuccessDetail {}

protocol TaskFailureDetail {}

extension SendRequestError: TaskFailureDetail {}
