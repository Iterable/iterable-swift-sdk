//
//  AuthFailureReason.swift
//  swift-sdk
//
//  Created by HARDIK MASHRU on 21/05/24.
//  Copyright © 2024 Iterable. All rights reserved.
//

import Foundation
@objc public enum AuthFailureReason: Int, CustomDebugStringConvertible {
    case authTokenExpired
    case authTokenGenericError
    case authTokenExpirationInvalid
    case authTokenSignatureInvalid
    case authTokenFormatInvalid
    case authTokenInvalidated
    case authTokenPayloadInvalid
    case authTokenUserKeyInvalid
    case authTokenNull
    case authTokenGenerationError
    case authTokenMissing

    public var debugDescription: String {
        switch self {
        case .authTokenExpired: return "authTokenExpired"
        case .authTokenGenericError: return "authTokenGenericError"
        case .authTokenExpirationInvalid: return "authTokenExpirationInvalid"
        case .authTokenSignatureInvalid: return "authTokenSignatureInvalid"
        case .authTokenFormatInvalid: return "authTokenFormatInvalid"
        case .authTokenInvalidated: return "authTokenInvalidated"
        case .authTokenPayloadInvalid: return "authTokenPayloadInvalid"
        case .authTokenUserKeyInvalid: return "authTokenUserKeyInvalid"
        case .authTokenNull: return "authTokenNull"
        case .authTokenGenerationError: return "authTokenGenerationError"
        case .authTokenMissing: return "authTokenMissing"
        }
    }
}
