//
//  JWTGenerator.swift
//  swift-sample-app
//
//  Created by HARDIK MASHRU on 22/05/24.
//  Copyright © 2024 Iterable. All rights reserved.
//

import Foundation
import CommonCrypto

public class JWTGenerator {
    static func getJWT(userId: String?, email: String?, expirationSeconds: Int?) -> String {
        let encoding = String.Encoding.utf8
        let secret = "34992609011249b410db9e1a568db9b65063c73e618bdb0229a674aeed7db7fba1bdc06e9b42d021120b9c88f795a734c18ab88ff7b6ecbccc50a945899d3666".data(using: encoding)!

        // Generate iat (issued at) timestamp as the current time
        let iat = Int(Date().timeIntervalSince1970)

        // Generate exp (expiration) timestamp as 5 minutes from now
        var exp = iat + 10  // 300 seconds = 5 minutes
        if let _exp = expirationSeconds {
            exp = iat + _exp
        }
            
        let header = ["alg": "HS256", "typ": "JWT"]
        var payload = [:] as [String : Any]
        if let _userId = userId {
            payload = ["userId": _userId, "iat": iat, "exp": exp] as [String : Any]
        } else {
            if let _email = email {
                payload = ["email": _email, "iat": iat, "exp": exp] as [String : Any]
            }
        }

        let headerData = try! JSONSerialization.data(withJSONObject: header)
        let payloadData = try! JSONSerialization.data(withJSONObject: payload)

        // Base64 URL-safe encode the header and payload data
        let encodedHeader = headerData.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))
        let encodedPayload = payloadData.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))

        let message = "\(encodedHeader).\(encodedPayload)"

        var hmacDigest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), (secret as NSData).bytes, secret.count, message, message.count, &hmacDigest)

        let encodedSignature = Data(hmacDigest).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))

        return "\(encodedHeader).\(encodedPayload).\(encodedSignature)"
    }

}


