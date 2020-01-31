//
//
//  Created by Ilya Brin on 5/25/16.
//  Copyright © 2016 Iterable. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <asl.h>

#import "swift_sdk_objc_tests-Swift.h"

@import IterableSDK;

@interface IterableAPIObjCTests : XCTestCase
@end

@implementation IterableAPIObjCTests

- (void)setUp {
    [super setUp];
    [IterableAPI initializeForObjcTesting];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testEmailUserIdPersistence {
    [IterableAPI initializeForObjcTesting];
    IterableAPI.email = @"test@email.com";
    
    [IterableAPI initializeForObjcTesting];
    XCTAssertEqualObjects(IterableAPI.email, @"test@email.com");
    XCTAssertNil(IterableAPI.userId);
    
    IterableAPI.userId = @"testUserId";

    [IterableAPI initializeForObjcTesting];
    XCTAssertEqualObjects(IterableAPI.userId, @"testUserId");
    XCTAssertNil(IterableAPI.email);
}


@end
