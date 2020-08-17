//
//  Created by Tapash Majumder on 7/30/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

enum IterableTaskResult {
    case success(detail: TaskSuccessDetail?)
    case failureWithRetry(retryAfter: TimeInterval?, detail: TaskFailureDetail?)
    case failureWithNoRetry(detail: TaskFailureDetail?)
}

protocol TaskSuccessDetail {}

struct APICallTaskSuccessDetail: TaskSuccessDetail {
    let json: SendRequestValue
}

protocol TaskFailureDetail {}

struct APICallTaskFailureDetail: TaskFailureDetail {
    let httpStatusCode: Int?
    let reason: String?
    let data: Data?
}
