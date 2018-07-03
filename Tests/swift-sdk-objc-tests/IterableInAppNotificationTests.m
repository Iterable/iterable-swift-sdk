//
//  IterableInAppNotificationTests.m
//  Iterable-iOS-SDK
//
//  Created by David Truong on 10/3/17.
//  Copyright © 2017 Iterable. All rights reserved.
//

#import <XCTest/XCTest.h>

@import IterableSDK;

@interface IterableInAppNotificationTests : XCTestCase

@end

@implementation IterableInAppNotificationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testGetNextNotificationNil {
    NSDictionary *payload;
    NSDictionary *message = [IterableInAppManager getNextMessageFromPayload:payload];
    
    XCTAssertNil(message);
}

- (void)testGetNextNotificationEmpty {
    NSDictionary *payload = @{ @"inAppMessages" : @[] };
    NSDictionary *message = [IterableInAppManager getNextMessageFromPayload:payload];
    
    XCTAssertNil(message);
}

- (void)testNotificationCreation {
    //call showIterableNotificationHTML with fake data
    //Check the top level dialog
    
    NSString *htmlString = @"<a href=\"http://www.iterable.com\" target=\"http://www.iterable.com\">test</a>";
    
    IterableInAppHTMLViewController *baseNotification;
        baseNotification = [[IterableInAppHTMLViewController alloc] initWithData:htmlString];

    NSString *html = [baseNotification getHtml];
    XCTAssertEqual(html, htmlString);
}

- (void)testGetPaddingInvalid {
    NSDictionary *payload = @{};
    
    UIEdgeInsets insets = [IterableInAppManager getPaddingFromPayload:payload];
    
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsZero));
}

- (void)testGetPaddingFull {
    
    NSDictionary *payload = @{ @"top" : @{@"percentage" : @"0"}, @"left" : @{@"percentage" : @"0"}, @"bottom" : @{@"percentage" : @"0"}, @"right" : @{@"percentage" : @"0"}};
    
    UIEdgeInsets insets = [IterableInAppManager getPaddingFromPayload:payload];
    
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsZero));
    
    UIEdgeInsets padding = UIEdgeInsetsZero;
        padding.top = [IterableInAppManager decodePadding:[payload objectForKey:@"top"]];
        padding.left = [IterableInAppManager decodePadding:[payload objectForKey:@"left"]];
        padding.bottom = [IterableInAppManager decodePadding:[payload objectForKey:@"bottom"]];
        padding.right = [IterableInAppManager decodePadding:[payload objectForKey:@"right"]];

    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsZero));
}

- (void)testGetPaddingCenter {
    
    NSDictionary *payload = @{ @"top" : @{@"displayOption" : @"AutoExpand"}, @"left" : @{@"percentage" : @"0"}, @"bottom" : @{@"displayOption" : @"AutoExpand"}, @"right" : @{@"percentage" : @"0"}};
    
    UIEdgeInsets insets = [IterableInAppManager getPaddingFromPayload:payload];
    
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsMake(-1, 0, -1, 0)));
    
    UIEdgeInsets padding = UIEdgeInsetsZero;
    padding.top = [IterableInAppManager decodePadding:[payload objectForKey:@"top"]];
    padding.left = [IterableInAppManager decodePadding:[payload objectForKey:@"left"]];
    padding.bottom = [IterableInAppManager decodePadding:[payload objectForKey:@"bottom"]];
    padding.right = [IterableInAppManager decodePadding:[payload objectForKey:@"right"]];
    
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsMake(-1, 0, -1, 0)));
}

- (void)testGetPaddingTop {
    
    NSDictionary *payload = @{ @"top" : @{@"percentage" : @"0"}, @"left" : @{@"percentage" : @"0"}, @"bottom" : @{@"displayOption" : @"AutoExpand"}, @"right" : @{@"percentage" : @"0"}};
    
    UIEdgeInsets insets = [IterableInAppManager getPaddingFromPayload:payload];
    
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsMake(0, 0, -1, 0)));
    
    UIEdgeInsets padding = UIEdgeInsetsZero;
    padding.top = [IterableInAppManager decodePadding:[payload objectForKey:@"top"]];
    padding.left = [IterableInAppManager decodePadding:[payload objectForKey:@"left"]];
    padding.bottom = [IterableInAppManager decodePadding:[payload objectForKey:@"bottom"]];
    padding.right = [IterableInAppManager decodePadding:[payload objectForKey:@"right"]];
    
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsMake(0, 0, -1, 0)));
}

- (void)testGetPaddingBottom {
    NSDictionary *payload = @{ @"top" : @{@"displayOption" : @"AutoExpand"}, @"left" : @{@"percentage" : @"0"}, @"bottom" : @{@"percentage" : @"0"}, @"right" : @{@"percentage" : @"0"}};
    
    UIEdgeInsets insets = [IterableInAppManager getPaddingFromPayload:payload];
    
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsMake(-1, 0, 0, 0)));
    
    UIEdgeInsets padding = UIEdgeInsetsZero;
    padding.top = [IterableInAppManager decodePadding:[payload objectForKey:@"top"]];
    padding.left = [IterableInAppManager decodePadding:[payload objectForKey:@"left"]];
    padding.bottom = [IterableInAppManager decodePadding:[payload objectForKey:@"bottom"]];
    padding.right = [IterableInAppManager decodePadding:[payload objectForKey:@"right"]];
    
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsMake(-1, 0, 0, 0)));
}

- (void)testNotificationPaddingFull {
    INAPP_NOTIFICATION_TYPE notificationType = [IterableInAppHTMLViewController setLocation:UIEdgeInsetsMake(0,0,0,0)];
    XCTAssertEqual(notificationType, INAPP_FULL);
}

- (void)testNotificationPaddingTop {
    INAPP_NOTIFICATION_TYPE notificationType = [IterableInAppHTMLViewController setLocation:UIEdgeInsetsMake(0,0,-1,0)];
    XCTAssertEqual(notificationType, INAPP_TOP);
}

- (void)testNotificationPaddingBottom {
    INAPP_NOTIFICATION_TYPE notificationType = [IterableInAppHTMLViewController setLocation:UIEdgeInsetsMake(-1,0,0,0)];
    XCTAssertEqual(notificationType, INAPP_BOTTOM);
}

- (void)testNotificationPaddingCenter {
    INAPP_NOTIFICATION_TYPE notificationType = [IterableInAppHTMLViewController setLocation:UIEdgeInsetsMake(-1,0,-1,0)];
    XCTAssertEqual(notificationType, INAPP_CENTER);
}

- (void)testNotificationPaddingDefault {
    INAPP_NOTIFICATION_TYPE notificationType = [IterableInAppHTMLViewController setLocation:UIEdgeInsetsMake(10,0,20,0)];
    XCTAssertEqual(notificationType, INAPP_CENTER);
}

@end
