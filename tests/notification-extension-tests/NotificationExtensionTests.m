//
//  Created by Victor Babenko on 4/18/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UserNotifications/UserNotifications.h>
#import <MobileCoreServices/MobileCoreServices.h>

@import IterableAppExtensions;

static CGFloat const IterableNotificationCenterRequestDelay = 0.05;
static CGFloat const IterableNotificationCenterExpectationTimeout = 15.0;

@interface NotificationExtensionTests : XCTestCase

@property (nonatomic) ITBNotificationServiceExtension *extension;

@end

@implementation NotificationExtensionTests

- (void)setUp {
    [super setUp];
    NSSet<UNNotificationCategory *> *categories = [[NSSet alloc] initWithArray:@[]];
    [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:categories];
    self.extension = [[ITBNotificationServiceExtension alloc] init];
}

- (void)tearDown {
    self.extension = nil;
    [super tearDown];
}

- (void)testPushIncorrectAttachemnt {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.userInfo = @{
                         @"itbl" : @{
                                 @"messageId": @"12345",
                                 @"attachment-url": @"Invalid URL!"
                                 }
                         };
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"request" content:content trigger:nil];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"contentHandler is called"];
    
    [self.extension didReceiveNotificationRequest:request withContentHandler:^(UNNotificationContent *contentToDeliver) {
        XCTAssertEqual(contentToDeliver.attachments.count, 0);
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:IterableNotificationCenterExpectationTimeout];
}

- (void)testPushImageAttachemnt {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.userInfo = @{
                         @"itbl" : @{
                                 @"messageId": @"12345",
                                 @"attachment-url": @"https://iterable.com/wp-content/uploads/2016/12/Iterable_Logo_transparent-tight.png"
                                 }
                         };
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"request" content:content trigger:nil];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"contentHandler is called"];
    
    [self.extension didReceiveNotificationRequest:request withContentHandler:^(UNNotificationContent *contentToDeliver) {
        XCTAssertEqual(contentToDeliver.attachments.count, 1);
        XCTAssertNotNil(contentToDeliver.attachments.firstObject.URL);
        XCTAssertEqualObjects(contentToDeliver.attachments.firstObject.URL.scheme, @"file");
        XCTAssertEqualObjects(contentToDeliver.attachments.firstObject.type, (NSString *)kUTTypePNG);
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:IterableNotificationCenterExpectationTimeout];
}

- (void)testPushVideoAttachment {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.userInfo = @{
                         @"itbl" : @{
                                 @"messageId": @"12345",
                                 @"attachment-url": @"https://framework.realtime.co/blog/img/ios10-video.mp4"
                                 }
                         };
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"request" content:content trigger:nil];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"contentHandler is called"];
    
    [self.extension didReceiveNotificationRequest:request withContentHandler:^(UNNotificationContent *contentToDeliver) {
        XCTAssertEqual(contentToDeliver.attachments.count, 1);
        XCTAssertNotNil(contentToDeliver.attachments.firstObject.URL);
        XCTAssertEqualObjects(contentToDeliver.attachments.firstObject.URL.scheme, @"file");
        XCTAssertEqualObjects(contentToDeliver.attachments.firstObject.type, (NSString *)kUTTypeMPEG4);
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:IterableNotificationCenterExpectationTimeout];
}

- (void)testPushDynamicCategory {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.userInfo = @{
                         @"itbl" : @{
                                 @"messageId": [[NSUUID UUID] UUIDString],
                                 @"actionButtons": @[@{
                                                         @"identifier": @"openAppButton",
                                                         @"title": @"Open App",
                                                         @"buttonType": @"default",
                                                         @"openApp": @YES,
                                                         @"action": @{
                                                                 }
                                                         }, @{
                                                         @"identifier": @"deeplinkButton",
                                                         @"title": @"Open Deeplink",
                                                         @"buttonType": @"default",
                                                         @"openApp": @YES,
                                                         @"action": @{
                                                                 @"type": @"openUrl",
                                                                 @"data": @"http://maps.apple.com/?ll=37.7828,-122.3984"
                                                                 }
                                                         }, @{
                                                         @"identifier": @"silentActionButton",
                                                         @"title": @"Silent Action",
                                                         @"buttonType": @"default",
                                                         @"openApp": @NO,
                                                         @"action": @{
                                                                 @"type": @"customActionName"
                                                                 }
                                                         }, @{
                                                         @"identifier": @"textInputButton",
                                                         @"title": @"Text input",
                                                         @"buttonType": @"textInput",
                                                         @"openApp": @NO,
                                                         @"inputPlaceholder": @"Type your message here",
                                                         @"inputTitle": @"Send",
                                                         @"action": @{
                                                                 @"type": @"handleTextInput"
                                                                 }
                                                         }]
                                 }
                         };
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"request" content:content trigger:nil];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"contentHandler is called"];
    
    [self.extension didReceiveNotificationRequest:request withContentHandler:^(UNNotificationContent *contentToDeliver) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, IterableNotificationCenterRequestDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
            [center getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> * _Nonnull categories) {
                UNNotificationCategory *createdCategory = nil;
                for (UNNotificationCategory *category in categories) {
                    if ([category.identifier isEqualToString:content.userInfo[@"itbl"][@"messageId"]]) {
                        createdCategory = category;
                    }
                }
                XCTAssertNotNil(createdCategory, "Category exists");
                
                NSArray *buttons = content.userInfo[@"itbl"][@"actionButtons"];
                XCTAssertEqual(createdCategory.actions.count, 4, "Number of buttons matches");
                for (int i = 0; i < 4; i++) {
                    NSDictionary *buttonPayload = buttons[i];
                    UNNotificationAction *actionButton = createdCategory.actions[i];
                    
                    XCTAssertEqualObjects(actionButton.identifier, buttonPayload[@"identifier"], "Identifiers match");
                    XCTAssertEqualObjects(actionButton.title, buttonPayload[@"title"], "Button titles match");
                }
                
                [expectation fulfill];
            }];
        });
    }];
    
    [self waitForExpectations:@[expectation] timeout:IterableNotificationCenterExpectationTimeout];
}

- (void)testPushDestructiveSilentActionButton {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.userInfo = @{
                         @"itbl" : @{
                                 @"messageId": [[NSUUID UUID] UUIDString],
                                 @"actionButtons": @[@{
                                                         @"identifier": @"destructiveButton",
                                                         @"title": @"Unsubscribe",
                                                         @"buttonType": @"destructive",
                                                         @"openApp": @NO,
                                                         @"action": @{
                                                                 }
                                                         }]
                                 }
                         };
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"request" content:content trigger:nil];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"contentHandler is called"];
    
    [self.extension didReceiveNotificationRequest:request withContentHandler:^(UNNotificationContent *contentToDeliver) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, IterableNotificationCenterRequestDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
            [center getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> * _Nonnull categories) {
                UNNotificationCategory *createdCategory = nil;
                for (UNNotificationCategory *category in categories) {
                    if ([category.identifier isEqualToString:content.userInfo[@"itbl"][@"messageId"]]) {
                        createdCategory = category;
                    }
                }
                XCTAssertNotNil(createdCategory, "Category exists");
                
                XCTAssertEqual(createdCategory.actions.count, 1, "Number of buttons matches");
                XCTAssertTrue(createdCategory.actions.firstObject.options & UNNotificationActionOptionDestructive, "Action is destructive");
                XCTAssertFalse(createdCategory.actions.firstObject.options & UNNotificationActionOptionForeground, "Action is not foreground");
                
                [expectation fulfill];
            }];
        });
    }];
    
    [self waitForExpectations:@[expectation] timeout:IterableNotificationCenterExpectationTimeout];
}

- (void)testPushTextInputSilentButton {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.userInfo = @{
                         @"itbl" : @{
                                 @"messageId": [[NSUUID UUID] UUIDString],
                                 @"actionButtons": @[@{
                                                         @"identifier": @"textInputButton",
                                                         @"title": @"Text Input",
                                                         @"buttonType": @"textInput",
                                                         @"openApp": @NO,
                                                         @"action": @{
                                                                 
                                                                 }
                                                         }]
                                 }
                         };
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"request" content:content trigger:nil];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"contentHandler is called"];
    
    [self.extension didReceiveNotificationRequest:request withContentHandler:^(UNNotificationContent *contentToDeliver) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, IterableNotificationCenterRequestDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
            [center getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> * _Nonnull categories) {
                UNNotificationCategory *createdCategory = nil;
                for (UNNotificationCategory *category in categories) {
                    if ([category.identifier isEqualToString:content.userInfo[@"itbl"][@"messageId"]]) {
                        createdCategory = category;
                    }
                }
                XCTAssertNotNil(createdCategory, "Category exists");
                
                XCTAssertEqual(createdCategory.actions.count, 1, "Number of buttons matches");
                XCTAssertFalse(createdCategory.actions.firstObject.options & UNNotificationActionOptionForeground, "Action is not foreground");
                XCTAssertTrue([createdCategory.actions.firstObject isKindOfClass:[UNTextInputNotificationAction class]], "Action type is UNTextInputNotificationAction");
                
                [expectation fulfill];
            }];
        });
    }];
    
    [self waitForExpectations:@[expectation] timeout:IterableNotificationCenterExpectationTimeout];
}

- (void)testPushTextInputForegroundButton {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.userInfo = @{
                         @"itbl" : @{
                                 @"messageId": [[NSUUID UUID] UUIDString],
                                 @"actionButtons": @[@{
                                                         @"identifier": @"textInputButton",
                                                         @"title": @"Text Input",
                                                         @"buttonType": @"textInput",
                                                         @"openApp": @YES,
                                                         @"action": @{
                                                                 
                                                                 }
                                                         }]
                                 }
                         };
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"request" content:content trigger:nil];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"contentHandler is called"];
    
    [self.extension didReceiveNotificationRequest:request withContentHandler:^(UNNotificationContent *contentToDeliver) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, IterableNotificationCenterRequestDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
            [center getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> * _Nonnull categories) {
                UNNotificationCategory *createdCategory = nil;
                for (UNNotificationCategory *category in categories) {
                    if ([category.identifier isEqualToString:content.userInfo[@"itbl"][@"messageId"]]) {
                        createdCategory = category;
                    }
                }
                XCTAssertNotNil(createdCategory, "Category exists");
                
                XCTAssertEqual(createdCategory.actions.count, 1, "Number of buttons matches");
                XCTAssertTrue(createdCategory.actions.firstObject.options & UNNotificationActionOptionForeground, "Action is foreground");
                XCTAssertTrue([createdCategory.actions.firstObject isKindOfClass:[UNTextInputNotificationAction class]], "Action type is UNTextInputNotificationAction");
                
                [expectation fulfill];
            }];
        });
    }];
    
    [self waitForExpectations:@[expectation] timeout:IterableNotificationCenterExpectationTimeout];
}

- (void)testPushActionButtons {
    
}

@end
