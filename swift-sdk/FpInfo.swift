//
//  FpInfo.swift
//  swift-sdk
//
//  Created by Tapash Majumder on 8/8/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

struct FpInfo : Codable {
    let isMatch: Bool
    let destinationUrl: String?
    let campaignId: String?
    let templateId: String?
    let messageId: String?
}
