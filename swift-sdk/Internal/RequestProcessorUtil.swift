//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

struct RequestProcessorUtil {
    @discardableResult
    static func sendRequest(requestProvider: @escaping () -> Pending<SendRequestValue, SendRequestError>,
                            successHandler onSuccess: OnSuccessHandler? = nil,
                            failureHandler onFailure: OnFailureHandler? = nil,
                            authManager: IterableAuthManagerProtocol? = nil,
                            requestIdentifier identifier: String) -> Pending<SendRequestValue, SendRequestError> {
        let result = Fulfill<SendRequestValue, SendRequestError>()
        requestProvider().onSuccess { json in
            resetAuthRetries(authManager: authManager, requestIdentifier: identifier)
            reportSuccess(result: result, value: json, successHandler: onSuccess, identifier: identifier)
        }
        .onError { error in
            ITBDebug("🔐 [JWT] sendRequest error - status: \(error.httpStatusCode ?? 0), code: \(error.iterableCode ?? "nil"), reason: \(error.reason ?? "nil")")
            if error.httpStatusCode == 401, matchesJWTErrorCode(error.iterableCode) {
                ITBError("invalid JWT token, trying again: \(error.reason ?? "")")
                ITBDebug("🔐 [JWT] JWT error detected, calling handleAuthFailure - token: \(authManager?.getAuthToken()?.prefix(20) ?? "nil")..., reason: \(getMappedErrorCodeForMessage(error.reason ?? "").rawValue)")
                authManager?.handleAuthFailure(failedAuthToken: authManager?.getAuthToken(), reason: getMappedErrorCodeForMessage(error.reason ?? ""))
                authManager?.setIsLastAuthTokenValid(false)
                let retryInterval = authManager?.getNextRetryInterval() ?? 1
                ITBDebug("🔐 [JWT] Scheduling retry with interval: \(retryInterval)")
                DispatchQueue.main.async {
                    authManager?.scheduleAuthTokenRefreshTimer(interval: retryInterval, isScheduledRefresh: false, successCallback: { _ in
                        sendRequest(requestProvider: requestProvider, successHandler: onSuccess, failureHandler: onFailure, authManager: authManager, requestIdentifier: identifier)
                    })
                }
            } else if error.httpStatusCode == 401, error.iterableCode == JsonValue.Code.badApiKey {
                ITBError(error.reason)
                reportFailure(result: result, error: error, failureHandler: onFailure, identifier: identifier)
            } else {
                ITBError(error.reason)
                reportFailure(result: result, error: error, failureHandler: onFailure, identifier: identifier)
            }
        }
        return result
    }

    @discardableResult
    static func apply(successHandler onSuccess: OnSuccessHandler? = nil,
                      andFailureHandler onFailure: OnFailureHandler? = nil,
                      andAuthManager authManager: IterableAuthManagerProtocol? = nil,
                      toResult result: Pending<SendRequestValue, SendRequestError>,
                      withIdentifier identifier: String) -> Pending<SendRequestValue, SendRequestError> {
        result.onSuccess { json in
            resetAuthRetries(authManager: authManager, requestIdentifier: identifier)
            if let onSuccess = onSuccess {
                onSuccess(json)
            } else {
                defaultOnSuccess(identifier)(json)
            }
        }.onError { error in
            if error.httpStatusCode == 401, matchesJWTErrorCode(error.iterableCode) {
                ITBError(error.reason)
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
    
    private static func reportSuccess(result: Fulfill<SendRequestValue, SendRequestError>,
                                      value: SendRequestValue,
                                      successHandler onSuccess: OnSuccessHandler?,
                                      identifier: String) {
        
        if let onSuccess = onSuccess {
            onSuccess(value)
        } else {
            Self.defaultOnSuccess(identifier)(value)
        }
        result.resolve(with: value)
    }
    
    public static func getMappedErrorCodeForMessage(_ reason: String) -> AuthFailureReason {
        let result: AuthFailureReason
        switch reason.lowercased() {
            case "exp must be less than 1 year from iat":
                result = .authTokenExpirationInvalid
            case "jwt format is invalid":
                result = .authTokenFormatInvalid
            case "jwt token is expired":
                result = .authTokenExpired
            case "jwt is invalid":
                result = .authTokenSignatureInvalid
            case "jwt payload requires a value for userid or email", "email could not be found":
                result = .authTokenUserKeyInvalid
            case "jwt token has been invalidated":
                result = .authTokenInvalidated
            case "invalid payload":
                result = .authTokenPayloadInvalid
            case "jwt authorization header is not set":
                result = .authTokenMissing
            default:
            result = .authTokenGenericError
        }
        ITBDebug("🔐 [JWT] Mapping error message: '\(reason)' -> \(result.rawValue)")
        return result
    }

    private static func reportFailure(result: Fulfill<SendRequestValue, SendRequestError>,
                                      error: SendRequestError,
                                      failureHandler onFailure: OnFailureHandler?,
                                      identifier: String) {
        
        if let onFailure = onFailure {
            onFailure(error.reason, error.data)
        } else {
            defaultOnFailure(identifier)(error.reason, error.data)
        }
        result.reject(with: error)
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
    
    private static func resetAuthRetries(authManager: IterableAuthManagerProtocol?, requestIdentifier: String) {
        if requestIdentifier != "disableDevice" {
            authManager?.resetFailedAuthCount()
            authManager?.pauseAuthRetries(false)
            authManager?.setIsLastAuthTokenValid(true)
        }
    }
    
    public static func matchesJWTErrorCode(_ errorCode: String?) -> Bool {
        let result = errorCode == JsonValue.Code.invalidJwtPayload || errorCode == JsonValue.Code.badAuthorizationHeader || errorCode == JsonValue.Code.jwtUserIdentifiersMismatched
        ITBDebug("🔐 [JWT] Checking JWT error code: '\(errorCode ?? "nil")' -> \(result)")
        return result
    }
}
