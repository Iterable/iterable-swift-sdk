//
//  IterableUtilTests.m
//  new_ios_sdk_objcTests
//
//  Created by Tapash Majumder on 6/5/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

@import IterableSDK;

@interface IterableUtilTests : XCTestCase

@end

@implementation IterableUtilTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCurrentDate {
    XCTAssertEqualWithAccuracy([NSDate date].timeIntervalSinceReferenceDate, IterableDateUtil.currentDate.timeIntervalSinceReferenceDate, 0.1);
}

- (void)testFutureDate {
    id dateUtilMock = OCMClassMock([IterableDateUtil class]);
    OCMExpect([dateUtilMock currentDate]).andReturn([NSDate dateWithTimeIntervalSinceNow:5*60]);
    XCTAssertNotEqualWithAccuracy([NSDate timeIntervalSinceReferenceDate], IterableDateUtil.currentDate.timeIntervalSinceReferenceDate, 0.1);
    
    // Stop mocking date
    [dateUtilMock stopMocking];
    
    XCTAssertEqualWithAccuracy([NSDate timeIntervalSinceReferenceDate], IterableDateUtil.currentDate.timeIntervalSinceReferenceDate, 0.1);
    
}

@end
