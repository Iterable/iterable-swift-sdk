//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@objc public class IterableAttributionInfo: NSObject, Codable {
    enum CodingKeys: String, CodingKey {
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
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        campaignId = NSNumber(value: try values.decode(Int.self, forKey: .campaignId))
        templateId = NSNumber(value: try values.decode(Int.self, forKey: .templateId))
        messageId = try values.decode(String.self, forKey: .messageId)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(campaignId.intValue, forKey: .campaignId)
        try container.encode(templateId.intValue, forKey: .templateId)
        try container.encode(messageId, forKey: .messageId)
    }
    
    override public var description: String {
        "campaignId: \(campaignId), templateId: \(templateId), messageId: \(messageId)"
    }
}

func == (lhs: IterableAttributionInfo, rhs: IterableAttributionInfo) -> Bool {
    lhs.campaignId == rhs.campaignId && lhs.templateId == rhs.templateId && lhs.messageId == rhs.messageId
}
