//
//  IterableConstants.h
//  Iterable-iOS-SDK
//
//  Created by David Truong on 9/9/16.
//  Copyright © 2016 Iterable. All rights reserved.
//

@interface IterableConstants : NSObject


@end


//MISC
#define ITBL_KEY_GET @"GET"
#define ITBL_KEY_POST @"POST"

#define ITBL_KEY_APNS @"APNS"
#define ITBL_KEY_APNS_SANDBOX @"APNS_SANDBOX"
#define ITBL_KEY_PAD @"Pad"
#define ITBL_KEY_PHONE @"Phone"
#define ITBL_KEY_UNSPECIFIED @"Unspecified"

#define ITBL_VALUE_DEFAULT_PUSH_OPEN_ACTION_ID @"default"

#define ITBL_PLATFORM_IOS @"iOS"


#define ITBL_DEEPLINK_IDENTIFIER @"/a/[a-zA-Z0-9]+"


//Push Payload
#define ITBL_PAYLOAD_METADATA @"itbl"
#define ITBL_PAYLOAD_MESSAGE_ID @"messageId"
#define ITBL_PAYLOAD_DEEP_LINK_URL @"url"
#define ITBL_PAYLOAD_ATTACHMENT_URL @"attachment-url"
#define ITBL_PAYLOAD_ACTION_BUTTONS @"actionButtons"
#define ITBL_PAYLOAD_DEFAULT_ACTION @"defaultAction"

//UserDefaults Keys
#define ITBL_USER_DEFAULTS_OBJECT_TAG @"itbl_user_defaults_object"
#define ITBL_USER_DEFAULTS_EXPIRATION_TAG @"itbl_user_defaults_expiration"
#define ITBL_USER_DEFAULTS_PAYLOAD_KEY @"itbl_payload_key"
#define ITBL_USER_DEFAULTS_PAYLOAD_EXPIRATION_HOURS 24
#define ITBL_USER_DEFAULTS_ATTRIBUTION_INFO_KEY @"itbl_attribution_info_key"
#define ITBL_USER_DEFAULTS_ATTRIBUTION_INFO_EXPIRATION_HOURS 24
#define ITBL_USER_DEFAULTS_EMAIL_KEY @"itbl_email"
#define ITBL_USER_DEFAULTS_USERID_KEY @"itbl_userid"
#define ITBL_USER_DEFAULTS_DDL_CHECKED @"itbl_ddl_checked"
#define ITBL_USER_DEFAULTS_DEVICE_ID @"itbl_device_id"
#define ITBL_USER_DEFAULTS_SDK_VERSION @"itbl_sdk_version"

//Action Buttons
#define ITBL_BUTTON_IDENTIFIER @"identifier"
#define ITBL_BUTTON_TYPE @"buttonType"
#define ITBL_BUTTON_TITLE @"title"
#define ITBL_BUTTON_OPEN_APP @"openApp"
#define ITBL_BUTTON_REQUIRES_UNLOCK @"requiresUnlock"
#define ITBL_BUTTON_INPUT_TITLE @"inputTitle"
#define ITBL_BUTTON_INPUT_PLACEHOLDER @"inputPlaceholder"
#define ITBL_BUTTON_ACTION @"action"

#define ITBL_ACTION_TYPE @"type"
#define ITBL_ACTION_DATA @"data"

//In-App Constants
#define ITERABLE_IN_APP_CLICK_URL @"urlClick"

#define ITERABLE_IN_APP_TITLE @"title"
#define ITERABLE_IN_APP_BODY @"body"
#define ITERABLE_IN_APP_IMAGE @"mainImage"
#define ITERABLE_IN_APP_BUTTON_INDEX @"buttonIndex"
#define ITERABLE_IN_APP_BUTTONS @"buttons"
#define ITERABLE_IN_APP_MESSAGE @"inAppMessages"

#define ITERABLE_IN_APP_TYPE @"displayType"
#define ITERABLE_IN_APP_TYPE_TOP @"TOP"
#define ITERABLE_IN_APP_TYPE_BOTTOM @"BOTTOM"
#define ITERABLE_IN_APP_TYPE_CENTER @"MIDDLE"
#define ITERABLE_IN_APP_TYPE_FULL @"FULL"
#define ITERABLE_IN_APP_TEXT @"text"
#define ITERABLE_IN_APP_TEXT_FONT @"font"
#define ITERABLE_IN_APP_TEXT_COLOR @"color"

#define ITERABLE_IN_APP_BACKGROUND_COLOR @"backgroundColor"
#define ITERABLE_IN_APP_BUTTON_ACTION @"action"
#define ITERABLE_IN_APP_CONTENT @"content"

//In-App HTML Constants
#define ITERABLE_IN_APP_BACKGROUND_ALPHA @"backgroundAlpha"
#define ITERABLE_IN_APP_HTML @"html"
#define ITERABLE_IN_APP_HREF @"href"
#define ITERABLE_IN_APP_DISPLAY_SETTINGS @"inAppDisplaySettings"

typedef void (^ITEActionBlock)(NSString *);

typedef void (^ITBURLCallback)(NSURL *);

/**
 The prototype for the completion handler block that gets called when an Iterable call is successful
 */
typedef void (^OnSuccessHandler)(NSDictionary *data);

/**
 The prototype for the completion handler block that gets called when an Iterable call fails
 */
typedef void (^OnFailureHandler)(NSString *reason, NSData *_Nullable data);

/**
 Enum representing push platform; apple push notification service, production vs sandbox
 */
typedef NS_ENUM(NSInteger, PushServicePlatform) {
    /** The sandbox push service */
    APNS_SANDBOX,
    /** The production push service */
    APNS,
    /** Detect automatically */
    AUTO
};
