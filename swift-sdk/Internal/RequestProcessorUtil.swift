//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

struct RequestProcessorUtil {
    @discardableResult
    static func apply(successHandler onSuccess: OnSuccessHandler? = nil,
                      andFailureHandler onFailure: OnFailureHandler? = nil,
                      andAuthManager authManager: IterableAuthManagerProtocol? = nil,
                      toResult result: Future<SendRequestValue, SendRequestError>,
                      withIdentifier identifier: String) -> Future<SendRequestValue, SendRequestError> {
        result.onSuccess { json in
            if let onSuccess = onSuccess {
                onSuccess(json)
            } else {
                defaultOnSuccess(identifier)(json)
            }
        }.onError { error in
            if error.httpStatusCode == 401, error.iterableCode == JsonValue.Code.invalidJwtPayload {
                ITBError(error.reason)
                authManager?.requestNewAuthToken(hasFailedPriorAuth: true, onSuccess: nil)
            } else if error.httpStatusCode == 401, error.iterableCode == JsonValue.Code.badApiKey {
                ITBError(error.reason)
            }
            
            if let onFailure = onFailure {
                onFailure(error.reason, error.data)
            } else {
                defaultOnFailure(identifier)(error.reason, error.data)
            }
        }
        return result
    }
    
    private static func defaultOnSuccess(_ identifier: String) -> OnSuccessHandler {
    { data in
        if let data = data {
            ITBInfo("\(identifier) succeeded, got response: \(data)")
        } else {
            ITBInfo("\(identifier) succeeded.")
        }
        }
    }
    
    private static func defaultOnFailure(_ identifier: String) -> OnFailureHandler {
    { reason, data in
        var toLog = "\(identifier) failed:"
        if let reason = reason {
            toLog += ", \(reason)"
        }
        if let data = data {
            toLog += ", got response \(String(data: data, encoding: .utf8) ?? "nil")"
        }
        ITBError(toLog)
        }
    }
}
