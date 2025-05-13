//
//  IterableDataRegionObjCTests.m
//  unit-tests
//
//  Copyright © 2024 Iterable. All rights reserved.
//

#import <XCTest/XCTest.h>
@import IterableSDK;

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

@end 