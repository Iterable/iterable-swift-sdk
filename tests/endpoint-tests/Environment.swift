//
//  Created by Tapash Majumder on 6/30/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

/// Read from ProcessInfo
/// These values come from scheme arguments.
/// If values are mising from scheme, they will read from generated CI.swift file.
struct Environment {
    enum Key: String {
        case apiKey = "api_key"
        case pushCampaignId = "push_campaign_id"
        case pushTemplateId = "push_template_id"
        case inAppCampaignId = "in_app_campaign_id"
        case inAppTemplateId = "in_app_template_id"
    }
    
    static var apiKey: String? {
        getFromEnv(key: .apiKey) ?? CI.apiKey
    }
    
    static var pushCampaignId: NSNumber? {
        getNSNumberFromEnv(key: .pushCampaignId) ?? CI.pushCampaignId
    }
    
    static var pushTemplateId: NSNumber? {
        getNSNumberFromEnv(key: .pushTemplateId) ?? CI.pushTemplateId
    }
    
    static var inAppCampaignId: NSNumber? {
        getNSNumberFromEnv(key: .inAppCampaignId) ?? CI.inAppCampaignId
    }
    
    static var inAppTemplateId: NSNumber? {
        getNSNumberFromEnv(key: .inAppTemplateId) ?? CI.inAppTemplateId
    }
    
    private static func getFromEnv(key: Key) -> String? {
        ProcessInfo.processInfo.environment[key.rawValue]
    }
    
    private static func getBoolFromEnv(key: Key) -> Bool {
        guard let strValue = getFromEnv(key: key) else {
            return false
        }
        return Bool(strValue) ?? false
    }
    
    private static func getNSNumberFromEnv(key: Key) -> NSNumber? {
        if let strValue = getFromEnv(key: key), let intValue = Int(strValue) {
            return NSNumber(value: intValue)
        } else {
            return nil
        }
    }
}
