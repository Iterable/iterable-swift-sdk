//
//  IterableActionRunnerTests.m
//  new_ios_sdk_objcTests
//
//  Created by Victor Babenko on 5/14/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

@import IterableSDK;

@interface IterableActionRunnerTests : XCTestCase

@end

@implementation IterableActionRunnerTests

- (void)setUp {
    [super setUp];
    [IterableAPI createSharedInstanceWithApiKey:@"" email:@"" userId:nil launchOptions:nil useCustomLaunchOptions:nil];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/* !!!TQM: TODO: fix
- (void)testUrlOpenAction {
    id urlDelegateMock = OCMProtocolMock(@protocol(IterableURLDelegate));
    id applicationMock = OCMPartialMock([UIApplication sharedApplication]);
    IterableAPI.instance.urlDelegate = urlDelegateMock;
    IterableAction *action = [IterableAction actionFromDictionary:@{ @"type": @"openUrl", @"data": @"https://example.com" }];
    [IterableActionRunner executeAction:action];
    
    OCMVerify([urlDelegateMock handleIterableURL:[OCMArg isEqual:[NSURL URLWithString:@"https://example.com"]] fromAction:[OCMArg isEqual:action]]);
    if (@available(iOS 10.0, *)) {
        OCMVerify([applicationMock openURL:[OCMArg any] options:[OCMArg any] completionHandler:[OCMArg any]]);
    } else {
        OCMVerify([applicationMock openURL:[OCMArg any]]);
    }
    [applicationMock stopMocking];
}
*/

/* !!!TQM: TODO: fix
- (void)testUrlHandlingOverride {
    id urlDelegateMock = OCMProtocolMock(@protocol(IterableURLDelegate));
    id applicationMock = OCMPartialMock([UIApplication sharedApplication]);
    if (@available(iOS 10.0, *)) {
        OCMReject([applicationMock openURL:[OCMArg any] options:[OCMArg any] completionHandler:[OCMArg any]]);
    } else {
        OCMReject([applicationMock openURL:[OCMArg any]]);
    }
    OCMStub([urlDelegateMock handleIterableURL:[OCMArg any] fromAction:[OCMArg any]]).andReturn(YES);
    IterableAPI.instance.urlDelegate = urlDelegateMock;
    IterableAction *action = [IterableAction actionFromDictionary:@{ @"type": @"openUrl", @"data": @"https://example.com" }];
    [IterableActionRunner executeAction:action];
    
    [applicationMock stopMocking];
}
*/

- (void)testCustomAction {
    id customActionDelegateMock = OCMProtocolMock(@protocol(IterableCustomActionDelegate));
    IterableAPI.instance.customActionDelegate = customActionDelegateMock;
    IterableAction *action = [IterableAction actionFromDictionary:@{ @"type": @"customActionName" }];
    [IterableActionRunner executeAction:action];
    
    OCMVerify([customActionDelegateMock handleIterableCustomAction:[OCMArg checkWithBlock:^BOOL(IterableAction *action) {
        XCTAssertEqualObjects(action.type, @"customActionName");
        return YES;
    }]]);
}

@end
