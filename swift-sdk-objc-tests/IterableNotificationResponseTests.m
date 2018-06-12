//
//  IterableNotificationResponseTests.m
//  Iterable-iOS-SDKTests
//
//  Created by Victor Babenko on 5/14/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

@import UserNotifications;
@import IterableSDK;

@interface IterableNotificationResponseTests : XCTestCase

@end

@implementation IterableNotificationResponseTests

- (void)setUp {
    [super setUp];
    [IterableAPI sharedInstanceWithApiKey:@"" andEmail:@"" launchOptions:nil];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (UNNotificationResponse *)notificationResponseWithUserInfo:(NSDictionary *)userInfo actionIdentifier:(NSString *)actionIdentifier {
    UNNotification *notification = [UNNotification alloc];
    UNNotificationRequest *notificationRequest = [UNNotificationRequest alloc];
    UNNotificationContent *notificationContent = [UNNotificationContent alloc];
    UNNotificationResponse *notificationResponse = [UNNotificationResponse alloc];
    
    [notificationResponse setValue:actionIdentifier forKeyPath:@"actionIdentifier"];
    [notificationResponse setValue:notification forKeyPath:@"notification"];
    
    [notificationRequest setValue:[UNPushNotificationTrigger alloc] forKey:@"trigger"];
    
    [notification setValue:notificationRequest forKeyPath:@"request"];
    [notificationRequest setValue:notificationContent forKeyPath:@"content"];
    [notificationContent setValue:userInfo forKey:@"userInfo"];
    
    return notificationResponse;
}

- (void)testTrackOpenPushWithCustomAction {
    if (@available(iOS 10, *)) {
        id actionRunnerMock = OCMClassMock([IterableActionRunner class]);
        id apiMock = OCMPartialMock(IterableAPI.sharedInstance);
        NSString *messageId = [[NSUUID UUID] UUIDString];
        
        NSDictionary *userInfo = @{
                                   @"itbl": @{
                                           @"campaignId": @1234,
                                           @"templateId": @4321,
                                           @"isGhostPush": @NO,
                                           @"messageId": messageId,
                                           @"defaultAction": @{
                                                   @"type": @"customAction"
                                                   }
                                           }
                                   };
        
        UNNotificationResponse *response = [self notificationResponseWithUserInfo:userInfo actionIdentifier:UNNotificationDefaultActionIdentifier];

        [IterableAppIntegration userNotificationCenter:nil didReceive:response withCompletionHandler:^{
            
        }];
        
        OCMVerify([actionRunnerMock executeAction:[OCMArg checkWithBlock:^BOOL(IterableAction *action) {
            XCTAssertEqual(action.type, @"customAction");
            return YES;
        }]]);
        
        OCMVerify([apiMock trackPushOpen:[OCMArg isEqual:@1234]
                              templateId:[OCMArg isEqual:@4321]
                               messageId:[OCMArg isEqual:messageId]
                       appAlreadyRunning:NO
                              dataFields:[OCMArg checkWithBlock:^BOOL(NSDictionary *dataFields) {
            XCTAssertEqualObjects(dataFields[ITBL_KEY_ACTION_IDENTIFIER], ITBL_VALUE_DEFAULT_PUSH_OPEN_ACTION_ID);
            return YES;
        }]
                               onSuccess:[OCMArg any]
                               onFailure:[OCMArg any]]);
        
        [actionRunnerMock stopMocking];
        [apiMock stopMocking];
    }
}

- (void)testSavePushPayload {
    id apiMock = OCMPartialMock(IterableAPI.sharedInstance);
    id dateUtilMock = OCMClassMock([IterableDateUtil class]);
    NSString *messageId = [[NSUUID UUID] UUIDString];
    
    NSDictionary *userInfo = @{
                               @"itbl": @{
                                       @"campaignId": @1234,
                                       @"templateId": @4321,
                                       @"isGhostPush": @NO,
                                       @"messageId": messageId,
                                       @"defaultAction": @{
                                               @"type": @"customAction"
                                               }
                                       }
                               };
    
    // call track push open
    [apiMock trackPushOpen:[OCMArg isEqual:userInfo]];
    
    // check the push payload for messageId
    NSDictionary *pushPayload = [apiMock lastPushPayload];
    XCTAssertEqualObjects(pushPayload[@"itbl"][@"messageId"], messageId);
    
    // 23 hours, not expired, still present
    OCMExpect([dateUtilMock currentDate]).andReturn([[NSDate date] dateByAddingTimeInterval:23*60*60]);
    pushPayload = [apiMock lastPushPayload];
    XCTAssertEqualObjects(pushPayload[@"itbl"][@"messageId"], messageId);
    
    // 24 hours, expired, nil payload
    OCMExpect([dateUtilMock currentDate]).andReturn([[NSDate date] dateByAddingTimeInterval:24*60*60]);
    pushPayload = [apiMock lastPushPayload];
    XCTAssertNil(pushPayload);
    
    [apiMock stopMocking];
    [dateUtilMock stopMocking];
}

- (void)testSaveAttributionInfo {
    id apiMock = OCMPartialMock(IterableAPI.sharedInstance);
    id dateUtilMock = OCMClassMock([IterableDateUtil class]);
    NSString *messageId = [[NSUUID UUID] UUIDString];
    NSNumber *campaignId = [NSNumber numberWithInt:1234];
    NSNumber *templateId = [NSNumber numberWithInteger:4321];
    
    NSDictionary *userInfo = @{
                               @"itbl": @{
                                       @"campaignId": campaignId,
                                       @"templateId": templateId,
                                       @"isGhostPush": @NO,
                                       @"messageId": messageId,
                                       @"defaultAction": @{
                                               @"type": @"customAction"
                                               }
                                       }
                               };
    
    // call track push open
    [apiMock trackPushOpen:[OCMArg isEqual:userInfo]];
    
    // check attribution info
    IterableAttributionInfo *attributionInfo = IterableAPI.sharedInstance.attributionInfo;
    XCTAssertEqualObjects(attributionInfo.campaignId, campaignId);
    XCTAssertEqualObjects(attributionInfo.templateId, templateId);
    XCTAssertEqualObjects(attributionInfo.messageId, messageId);
    
    // 23 hours, not expired, still present
    OCMExpect([dateUtilMock currentDate]).andReturn([[NSDate date] dateByAddingTimeInterval:23*60*60]);
    attributionInfo = IterableAPI.sharedInstance.attributionInfo;
    XCTAssertEqualObjects(attributionInfo.campaignId, campaignId);
    XCTAssertEqualObjects(attributionInfo.templateId, templateId);
    XCTAssertEqualObjects(attributionInfo.messageId, messageId);
    
    // 24 hours, expired, nil attributioninfo
    OCMExpect([dateUtilMock currentDate]).andReturn([[NSDate date] dateByAddingTimeInterval:24*60*60]);
    attributionInfo = IterableAPI.sharedInstance.attributionInfo;
    XCTAssertNil(attributionInfo);
    
    [apiMock stopMocking];
    [dateUtilMock stopMocking];
}


- (void)testActionButtonDismiss {
    if (@available(iOS 10, *)) {
        id actionRunnerMock = OCMClassMock([IterableActionRunner class]);
        id apiMock = OCMPartialMock(IterableAPI.sharedInstance);
        [IterableAPI sharedInstanceWithApiKey:@"" andEmail:@"" launchOptions:nil];
        
        NSDictionary *userInfo = @{
                                   @"itbl": @{
                                           @"actionButtons": @[@{
                                                                   @"identifier": @"buttonIdentifier",
                                                                   @"buttonType": @"dismiss",
                                                                   @"action": @{
                                                                           @"type": @"customAction"
                                                                           }
                                                                   }]
                                           }
                                   };
        
        UNNotificationResponse *response = [self notificationResponseWithUserInfo:userInfo actionIdentifier:@"buttonIdentifier"];
        
        [IterableAppIntegration userNotificationCenter:nil didReceive:response withCompletionHandler:^{
            
        }];
        
        OCMVerify([actionRunnerMock executeAction:[OCMArg checkWithBlock:^BOOL(IterableAction *action) {
            XCTAssertEqual(action.type, @"customAction");
            return YES;
        }]]);
        
        OCMVerify([apiMock trackPushOpen:[OCMArg any] dataFields:[OCMArg checkWithBlock:^BOOL(NSDictionary *dataFields) {
            XCTAssertEqualObjects(dataFields[ITBL_KEY_ACTION_IDENTIFIER], @"buttonIdentifier");
            return YES;
        }]]);
        
        [actionRunnerMock stopMocking];
        [apiMock stopMocking];
    }
}

- (void)testForegroundPushActionBeforeiOS10 {
    if (@available(iOS 10, *)) {
        // Do nothing
    } else {
        id actionRunnerMock = OCMClassMock([IterableActionRunner class]);
        id apiMock = OCMPartialMock(IterableAPI.sharedInstance);
        id applicationMock = OCMPartialMock([UIApplication sharedApplication]);
        NSString *messageId = [[NSUUID UUID] UUIDString];
        
        NSDictionary *userInfo = @{
                                   @"itbl": @{
                                           @"campaignId": @1234,
                                           @"templateId": @4321,
                                           @"isGhostPush": @NO,
                                           @"messageId": messageId,
                                           @"defaultAction": @{
                                                   @"type": @"customAction"
                                                   }
                                           }
                                   };
        
        OCMStub([applicationMock applicationState]).andReturn(UIApplicationStateInactive);
        
        [IterableAppIntegration application:[UIApplication sharedApplication] didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result) {
            
        }];
        
        OCMVerify([actionRunnerMock executeAction:[OCMArg checkWithBlock:^BOOL(IterableAction *action) {
            XCTAssertEqual(action.type, @"customAction");
            return YES;
        }]]);
        
        OCMVerify([apiMock trackPushOpen:[OCMArg isEqual:@1234]
                              templateId:[OCMArg isEqual:@4321]
                               messageId:[OCMArg isEqual:messageId]
                       appAlreadyRunning:NO
                              dataFields:[OCMArg any]
                               onSuccess:[OCMArg any]
                               onFailure:[OCMArg any]]);
        
        [actionRunnerMock stopMocking];
        [apiMock stopMocking];
        [applicationMock stopMocking];
    }
}


- (void)testAppLaunchPushActionBeforeiOS10 {
    if (@available(iOS 10, *)) {
        // Do nothing
    } else {
        id actionRunnerMock = OCMClassMock([IterableActionRunner class]);
        id appIntegrationMock = OCMClassMock([IterableAppIntegration class]);
        NSString *messageId = [[NSUUID UUID] UUIDString];
        
        NSDictionary *userInfo = @{
                                   @"itbl": @{
                                           @"campaignId": @1234,
                                           @"templateId": @4321,
                                           @"isGhostPush": @NO,
                                           @"messageId": messageId,
                                           @"defaultAction": @{
                                                   @"type": @"customAction"
                                                   }
                                           }
                                   };
        
        [IterableAPI clearSharedInstance];
        [IterableAPI sharedInstanceWithApiKey:@"" andEmail:@"" launchOptions:@{ UIApplicationLaunchOptionsRemoteNotificationKey: userInfo }];
        
        OCMVerify([actionRunnerMock executeAction:[OCMArg checkWithBlock:^BOOL(IterableAction *action) {
            XCTAssertEqual(action.type, @"customAction");
            return YES;
        }]]);

        OCMVerify([appIntegrationMock performDefaultNotificationAction:[OCMArg isEqual:userInfo] api:[OCMArg isNotNil]]);
        
        [actionRunnerMock stopMocking];
    }
}

@end
