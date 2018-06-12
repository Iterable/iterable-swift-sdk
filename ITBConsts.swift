//
//  ITBConsts.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/10/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@objc public class ITBConsts : NSObject {
    // MARK: Only for Objective C compability
    
    public class Payload {
        public static let metadata = "itbl"
        public static let messageId = "messageId"
        public static let attachmentUrl = "attachment-url"
        public static let actionButtons = "actionButtons"
        public static let defaultAction = "defaultAction"
    }
    
    public class Button {
        public static let identifier = "identifier"
        public static let type = "buttonType"
        public static let title = "title"
        public static let openApp = "openApp"
        public static let requiresUnlock = "requiresUnlock"
        public static let inputTitle = "inputTitle"
        public static let inputPlaceholder = "inputPlaceholder"
        public static let action = "action"
    }
}
