//
//  IterableAttributionInfo.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/5/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@objc public class IterableAttributionInfo : NSObject, NSCoding {
    private enum Keys : String {
        case campaignId
        case templateId
        case messageId
    }
    
    @objc public var campaignId: NSNumber
    
    @objc public var templateId: NSNumber
    
    @objc public var messageId: String
    
    @objc public init(campaignId: NSNumber, templateId: NSNumber, messageId: String) {
        self.campaignId = campaignId
        self.templateId = templateId
        self.messageId = messageId
    }
    
    @objc public required init?(coder decoder: NSCoder) {
        guard let campaignId = decoder.decodeObject(forKey: Keys.campaignId.rawValue) as? NSNumber  else {
            return nil
        }
        self.campaignId = campaignId
        guard let templateId = decoder.decodeObject(forKey: Keys.templateId.rawValue) as? NSNumber else {
            return nil
        }
        self.templateId = templateId
        guard let messageId = decoder.decodeObject(forKey: Keys.messageId.rawValue) as? String else {
            return nil
        }
        self.messageId = messageId
    }
    
    @objc public func encode(with encoder: NSCoder) {
        encoder.encode(campaignId, forKey: Keys.campaignId.rawValue)
        encoder.encode(templateId, forKey: Keys.templateId.rawValue)
        encoder.encode(messageId, forKey: Keys.messageId.rawValue)
    }
}
