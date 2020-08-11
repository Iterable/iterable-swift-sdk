//
//  Created by Tapash Majumder on 7/30/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

enum IterableTaskResult {
    case success(TaskSuccess)
    case failure(TaskFailure)
}

protocol TaskSuccess {}

struct APICallTaskSuccess: TaskSuccess {
    let json: SendRequestValue
}

protocol TaskFailure {}

struct APICallTaskFailure: TaskFailure {
    let responseCode: Int?
    let reason: String?
    let data: Data?
}
