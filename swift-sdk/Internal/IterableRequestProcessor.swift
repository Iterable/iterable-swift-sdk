//
//  Created by Tapash Majumder on 8/10/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

struct IterableRequestProcessor {
    let apiClient: ApiClientProtocol!
    
    struct RegisterTokenInfo {
        let hexToken: String
        let appName: String
        let pushServicePlatform: PushServicePlatform
        let apnsType: APNSType
        let deviceId: String
        let deviceAttributes: [String: String]
        let sdkVersion: String?
    }
    
    @discardableResult
    func register(registerTokenInfo: RegisterTokenInfo,
                  notificationStateProvider: NotificationStateProviderProtocol,
                  onSuccess: OnSuccessHandler? = IterableRequestProcessor.defaultOnSuccess("registerToken"),
                  onFailure: OnFailureHandler? = IterableRequestProcessor.defaultOnFailure("registerToken")) -> Future<SendRequestValue, SendRequestError> {
        // check notificationsEnabled then call register with enabled/not-enabled
        notificationStateProvider.notificationsEnabled
            .mapFailure(SendRequestError.from(error:))
            .replaceError(with: false)
            .flatMap { enabled in
                self.register(registerTokenInfo: registerTokenInfo,
                              notificationsEnabled: enabled,
                              onSuccess: onSuccess,
                              onFailure: onFailure)
            }
    }
    
    @discardableResult
    private func register(registerTokenInfo: RegisterTokenInfo,
                          notificationsEnabled: Bool,
                          onSuccess: OnSuccessHandler?,
                          onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        let pushServicePlatformString = IterableRequestProcessor.pushServicePlatformToString(registerTokenInfo.pushServicePlatform, apnsType: registerTokenInfo.apnsType)
        
        return IterableRequestProcessor.call(successHandler: onSuccess,
                                             andFailureHandler: onFailure,
                                             forResult: apiClient.register(hexToken: registerTokenInfo.hexToken,
                                                                           appName: registerTokenInfo.appName,
                                                                           deviceId: registerTokenInfo.deviceId,
                                                                           sdkVersion: registerTokenInfo.sdkVersion,
                                                                           deviceAttributes: registerTokenInfo.deviceAttributes,
                                                                           pushServicePlatform: pushServicePlatformString,
                                                                           notificationsEnabled: notificationsEnabled))
    }
    
//    private func disableDevice(forAllUsers allUsers: Bool,
//                               onSuccess: OnSuccessHandler? = IterableAPIInternal.defaultOnSuccess("disableDevice"),
//                               onFailure: OnFailureHandler? = IterableAPIInternal.defaultOnFailure("disableDevice")) {
//        guard let hexToken = hexToken else {
//            ITBError("Device not registered.")
//            onFailure?("Device not registered.", nil)
//            return
//        }
//
//        guard !(allUsers == false && email == nil && userId == nil) else {
//            ITBError("Emal or userId must be set.")
//            onFailure?("Email or userId must be set.", nil)
//            return
//        }
//
//        IterableAPIInternal.call(successHandler: onSuccess,
//                                 andFailureHandler: onFailure,
//                                 forResult: apiClient.disableDevice(forAllUsers: allUsers, hexToken: hexToken))
//    }
    
    private static func pushServicePlatformToString(_ pushServicePlatform: PushServicePlatform, apnsType: APNSType) -> String {
        switch pushServicePlatform {
        case .production:
            return JsonValue.apnsProduction.jsonStringValue
        case .sandbox:
            return JsonValue.apnsSandbox.jsonStringValue
        case .auto:
            return apnsType == .sandbox ? JsonValue.apnsSandbox.jsonStringValue : JsonValue.apnsProduction.jsonStringValue
        }
    }
    
    @discardableResult
    private static func call(successHandler onSuccess: OnSuccessHandler? = nil,
                             andFailureHandler onFailure: OnFailureHandler? = nil,
                             forResult result: Future<SendRequestValue, SendRequestError>) -> Future<SendRequestValue, SendRequestError> {
        result.onSuccess { json in
            onSuccess?(json)
        }.onError { error in
            onFailure?(error.reason, error.data)
        }
        return result
    }
    
    static func defaultOnSuccess(_ identifier: String) -> OnSuccessHandler {
        { data in
            if let data = data {
                ITBInfo("\(identifier) succeeded, got response: \(data)")
            } else {
                ITBInfo("\(identifier) succeeded.")
            }
        }
    }
    
    static func defaultOnFailure(_ identifier: String) -> OnFailureHandler {
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
