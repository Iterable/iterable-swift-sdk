//
//  AnonymousUserMergeProtocol.swift
//  swift-sdk
//
//  Created by Hani Vora on 29/12/23.
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation
@objc public protocol AnonymousUserMergeProtocol {
    func mergeUserUsingUserId(destinationUserId: String, sourceUserId: String, destinationEmail: String)
    func mergeUserUsingEmail(destinationUserId: String, destinationEmail: String, sourceEmail: String)
}
