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
                result.resolve(with: .success(detail: APICallTaskSuccessDetail(json: json)))
            }
            .onError { sendRequestError in
                if IterableAPICallTaskProcessor.isNetworkUnavailable(sendRequestError: sendRequestError) {
                    let failureDetail = APICallTaskFailureDetail(httpStatusCode: sendRequestError.httpStatusCode,
                                                                 reason: sendRequestError.reason,
                                                                 data: sendRequestError.data)
                    result.resolve(with: .failureWithRetry(retryAfter: nil, detail: failureDetail))
                } else {
                    let failureDetail = APICallTaskFailureDetail(httpStatusCode: sendRequestError.httpStatusCode,
                                                                 reason: sendRequestError.reason,
                                                                 data: sendRequestError.data)
                    result.resolve(with: .failureWithNoRetry(detail: failureDetail))
                }
            }
        
        return result
    }
    
    private static func isNetworkUnavailable(sendRequestError: SendRequestError) -> Bool {
        if let originalError = sendRequestError.originalError as? LocalizedError {
            return originalError.localizedDescription.lowercased().contains("unavailable")
        } else {
            return false
        }
    }
}
