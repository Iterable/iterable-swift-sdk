//
//  IterableTokenGenerator.swift
//  swift-sdk
//
//  Created by Apple on 22/10/24.
//  Copyright © 2024 Iterable. All rights reserved.
//

import UIKit
import CryptoKit

@objcMembers public final class IterableTokenGenerator: NSObject {

    public static func generateJwtForEial(secret: String, iat:Int, exp: Int, email:String) -> String {
        struct Header: Encodable {
            let alg = "HS256"
            let typ = "JWT"
        }

        struct Payload: Encodable {
            var email = ""
            var iat = Int(Date().timeIntervalSince1970)
            var exp = Int(Date().timeIntervalSince1970) + 60

        }
        let headerJsonData = try! JSONEncoder().encode(Header())
        let headerBase64 = headerJsonData.urlEncodedBase64()

        let payloadJsonData = try! JSONEncoder().encode(Payload(email: email, iat: iat, exp: exp))
        let payloadBase64 = payloadJsonData.urlEncodedBase64()

        let toSign = Data((headerBase64 + "." + payloadBase64).utf8)

        if #available(iOS 13.0, *) {
            let privateKey = SymmetricKey(data: Data(secret.utf8))
            let signature = HMAC<SHA256>.authenticationCode(for: toSign, using: privateKey)
            let signatureBase64 = Data(signature).urlEncodedBase64()

            let token = [headerBase64, payloadBase64, signatureBase64].joined(separator: ".")

            return token
        }
        return ""
    }

    public static func generateJwtForUserId(secret: String, iat:Int, exp: Int, userId:String) -> String {
        struct Header: Encodable {
            let alg = "HS256"
            let typ = "JWT"
        }

        struct Payload: Encodable {
            var userId = ""
            var iat = Int(Date().timeIntervalSince1970)
            var exp = Int(Date().timeIntervalSince1970) + 60

        }
        let headerJsonData = try! JSONEncoder().encode(Header())
        let headerBase64 = headerJsonData.urlEncodedBase64()

        let payloadJsonData = try! JSONEncoder().encode(Payload(userId: userId, iat: iat, exp: exp))
        let payloadBase64 = payloadJsonData.urlEncodedBase64()

        let toSign = Data((headerBase64 + "." + payloadBase64).utf8)

        if #available(iOS 13.0, *) {
            let privateKey = SymmetricKey(data: Data(secret.utf8))
            let signature = HMAC<SHA256>.authenticationCode(for: toSign, using: privateKey)
            let signatureBase64 = Data(signature).urlEncodedBase64()

            let token = [headerBase64, payloadBase64, signatureBase64].joined(separator: ".")

            return token
        }
        return ""
    }

}

extension Data {
    func urlEncodedBase64() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
