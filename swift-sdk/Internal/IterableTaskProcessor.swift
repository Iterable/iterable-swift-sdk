//
//  Created by Tapash Majumder on 7/30/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

enum IterableTaskType: String {
    case apiCall
}

struct IterableTaskContext {
    let blocking: Bool
}

protocol IterableTaskProcessor {
    func process(task: IterableTask) throws -> Future<IterableTaskResult, IterableTaskError>
}
