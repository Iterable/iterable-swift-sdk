//
//  IterableDataRegionObjCTests.m
//  unit-tests
//
//  Copyright © 2024 Iterable. All rights reserved.
//

#import <XCTest/XCTest.h>
@import IterableSDK;

@interface LegacyInAppDelegate : NSObject <IterableInAppDelegate>
@end

@implementation LegacyInAppDelegate

- (enum InAppShowResponse)onNewMessage:(IterableInAppMessage * _Nonnull)message {
    return InAppShowResponseShow;
}

@end

@interface JsonOnlyInAppDelegate : NSObject <IterableInAppDelegate>
@end

@implementation JsonOnlyInAppDelegate

- (enum InAppShowResponse)onNewMessage:(IterableInAppMessage * _Nonnull)message {
    return InAppShowResponseShow;
}

- (void)onJsonOnlyMessageAvailable:(IterableInAppMessage * _Nonnull)message {
}

@end

@interface IterableDataRegionObjCTests : XCTestCase

@end

@implementation IterableDataRegionObjCTests

- (void)testIterableDataRegionIsAccessibleFromObjectiveC {
    // Setup a config
    IterableConfig *config = [[IterableConfig alloc] init];
    
    // Test that we can set the data region
    config.dataRegion = IterableDataRegion.US;
    XCTAssertEqualObjects(config.dataRegion, @"https://api.iterable.com/api/");
    
    // Test changing to EU region
    config.dataRegion = IterableDataRegion.EU;
    XCTAssertEqualObjects(config.dataRegion, @"https://api.eu.iterable.com/api/");
}

- (void)testLegacyInAppDelegateConformanceRemainsValid {
    IterableConfig *config = [[IterableConfig alloc] init];
    config.inAppDelegate = [[LegacyInAppDelegate alloc] init];
    XCTAssertNotNil(config.inAppDelegate);
}

- (void)testJsonOnlyApiSurfaceIsAccessibleFromObjectiveC {
    IterableConfig *config = [[IterableConfig alloc] init];
    config.inAppDelegate = [[JsonOnlyInAppDelegate alloc] init];
    XCTAssertNotNil(config.inAppDelegate);

    XCTAssertEqualObjects(IterableAPI.jsonOnlyInAppMessageAvailableNotification,
                          @"itbl_json_only_in_app_message_available");
    (void)[IterableAPI getUnhandledJsonOnlyMessages];
    XCTAssertFalse([IterableAPI markJsonOnlyMessageHandled:@"missing"]);
}

@end
