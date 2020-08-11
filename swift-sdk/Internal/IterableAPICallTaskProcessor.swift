//
//  Created by Tapash Majumder on 7/30/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

struct IterableAPICallTaskProcessor: IterableTaskProcessor {
    let networkSession: NetworkSessionProtocol
    
    func process(task: IterableTask) throws -> Future<IterableTaskResult, IterableTaskError> {
        guard let data = task.data else {
            return IterableTaskError.createErroredFuture(reason: "expecting data")
        }
        
        let iterableRequest = try JSONDecoder().decode(IterableAPICallRequest.self, from: data)
        guard let urlRequest = iterableRequest.convertToURLRequest() else {
            return IterableTaskError.createErroredFuture(reason: "could not convert to url request")
        }
        
        let result = Promise<IterableTaskResult, IterableTaskError>()
        NetworkHelper.sendRequest(urlRequest, usingSession: networkSession)
            .onSuccess { json in
                result.resolve(with: .success(APICallTaskSuccess(json: json)))
            }
            .onError { networkError in
                result.resolve(with: .failure(APICallTaskFailure(responseCode: nil, reason: networkError.reason, data: networkError.data)))
            }
        
        return result
    }
}
