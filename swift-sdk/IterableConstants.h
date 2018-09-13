//
//  IterableConstants.h
//  Iterable-iOS-SDK
//
//  Created by David Truong on 9/9/16.
//  Copyright © 2016 Iterable. All rights reserved.
//

@interface IterableConstants : NSObject

@end

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
