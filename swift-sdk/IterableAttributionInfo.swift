//
//  IterableAttributionInfo.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/5/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@objc public class IterableAttributionInfo : NSObject, NSCoding, Codable {
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
    
    enum CodingKeys: String, CodingKey {
        case campaignId
        case templateId
        case messageId
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.campaignId = NSNumber(value: try values.decode(Int.self, forKey: .campaignId))
        self.templateId = NSNumber(value: try values.decode(Int.self, forKey: .templateId))
        self.messageId = try values.decode(String.self, forKey: .messageId)
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.campaignId.intValue, forKey: .campaignId)
        try container.encode(self.templateId.intValue, forKey: .templateId)
        try container.encode(self.messageId, forKey: .messageId)
    }
    
    public override var description: String {
        return "campaignId: \(campaignId), templateId: \(templateId), messageId: \(messageId)"
    }
}

func ==(lhs: IterableAttributionInfo, rhs: IterableAttributionInfo) -> Bool {
    return lhs.campaignId == rhs.campaignId && lhs.templateId == rhs.templateId && lhs.messageId == rhs.messageId
}

