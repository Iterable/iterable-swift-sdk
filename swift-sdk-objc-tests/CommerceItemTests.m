//
//  CommerceItemTests.m
//  Iterable-iOS-SDK
//
//  Created by Ilya Brin on 5/25/16.
//  Copyright © 2016 Iterable. All rights reserved.
//

#import <XCTest/XCTest.h>

@import IterableSDK;

@interface CommerceItemTests : XCTestCase

@end

@implementation CommerceItemTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testToDictionary {
    NSUInteger quantity = 9001;
    CommerceItem *item = [[CommerceItem alloc] initWithId:@"foo" name:@"bar" price:@666 quantity:quantity];
    NSDictionary *expected = @{
                               @"id": @"foo",
                               @"name": @"bar",
                               @"price": @666,
                               @"quantity": @9001
                               };
    XCTAssertEqualObjects([item toDictionary], expected);
}

@end
