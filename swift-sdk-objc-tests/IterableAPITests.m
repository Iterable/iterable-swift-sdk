//
//  IterableAPITests.m
//  Iterable-iOS-SDK
//
//  Created by Ilya Brin on 5/25/16.
//  Copyright © 2016 Iterable. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <asl.h>

@import IterableSDK;

static CGFloat const IterableNetworkResponseExpectationTimeout = 5.0;

@interface IterableAPITests : XCTestCase
@end

@implementation IterableAPITests

NSString *redirectRequest = @"https://httpbin.org/redirect-to?url=http://example.com";
NSString *exampleUrl = @"http://example.com";

NSString *googleHttps = @"https://www.google.com";
NSString *googleHttp = @"http://www.google.com";
NSString *iterableRewriteURL = @"http://links.iterable.com/a/60402396fbd5433eb35397b47ab2fb83?_e=joneng%40iterable.com&_m=93125f33ba814b13a882358f8e0852e0";
NSString *iterableNoRewriteURL = @"http://links.iterable.com/u/60402396fbd5433eb35397b47ab2fb83?_e=joneng%40iterable.com&_m=93125f33ba814b13a882358f8e0852e0";

- (void)setUp {
    [super setUp];
    
    [IterableAPI initializeWithApiKey:@"" launchOptions:nil config: nil email:nil userId:nil];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPushServicePlatformToString {
    XCTAssertEqualObjects(@"APNS", [IterableAPI pushServicePlatformToString:APNS]);
    XCTAssertEqualObjects(@"APNS_SANDBOX", [IterableAPI pushServicePlatformToString:APNS_SANDBOX]);
}

- (void)testDictToJson {
    NSDictionary *args = @{
                           @"email": @"ilya@iterable.com",
                           @"device": @{
                                   @"token": @"foo",
                                   @"platform": @"bar",
                                   @"applicationName": @"baz",
                                   @"dataFields": @{
                                           @"name": @"green",
                                           @"localizedModel": @"eggs",
                                           @"userInterfaceIdiom": @"and",
                                           @"identifierForVendor": @"ham",
                                           @"systemName": @"iterable",
                                           @"systemVersion": @"is",
                                           @"model": @"awesome"
                                           }
                                   }
                           };
    NSString *result = [IterableAPI dictToJson:args];
    NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    XCTAssertEqualObjects(args, json);
    
    NSString *expected = @"{\"email\":\"ilya@iterable.com\",\"device\":{\"applicationName\":\"baz\",\"dataFields\":{\"systemName\":\"iterable\",\"model\":\"awesome\",\"localizedModel\":\"eggs\",\"userInterfaceIdiom\":\"and\",\"systemVersion\":\"is\",\"name\":\"green\",\"identifierForVendor\":\"ham\"},\"token\":\"foo\",\"platform\":\"bar\"}}";
    
    id object = [NSJSONSerialization
                 JSONObjectWithData:[expected dataUsingEncoding:NSUTF8StringEncoding]
                 options:0
                 error:nil];
    XCTAssertEqualObjects(args, object);
    XCTAssertEqualObjects(args, json);
}

- (void)testUserInterfaceIdionEnumToString {
    XCTAssertEqualObjects(@"Phone", [IterableAPI userInterfaceIdiomEnumToString:UIUserInterfaceIdiomPhone]);
    XCTAssertEqualObjects(@"Pad", [IterableAPI userInterfaceIdiomEnumToString:UIUserInterfaceIdiomPad]);
    // we don't care about TVs for now
    XCTAssertEqualObjects(@"Unspecified", [IterableAPI userInterfaceIdiomEnumToString:UIUserInterfaceIdiomTV]);
    XCTAssertEqualObjects(@"Unspecified", [IterableAPI userInterfaceIdiomEnumToString:UIUserInterfaceIdiomUnspecified]);
    XCTAssertEqualObjects(@"Unspecified", [IterableAPI userInterfaceIdiomEnumToString:192387]);
}

- (void)testUniversalDeeplinkRewrite {
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    NSURL *iterableLink = [NSURL URLWithString:iterableRewriteURL];
    ITEActionBlock aBlock = ^(NSString* redirectUrl) {
        XCTAssertEqualObjects(@"https://links.iterable.com/api/docs#!/email", redirectUrl);
        [expectation fulfill];
    };
    [IterableAPI getAndTrackDeeplink:iterableLink callbackBlock:aBlock];
    
    [self waitForExpectationsWithTimeout:IterableNetworkResponseExpectationTimeout handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testUniversalDeeplinkNoRewrite {
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    NSURL *normalLink = [NSURL URLWithString:iterableNoRewriteURL];
    ITEActionBlock uBlock = ^(NSString* redirectUrl) {
        XCTAssertEqualObjects(iterableNoRewriteURL, redirectUrl);
        [expectation fulfill];
    };
    [IterableAPI getAndTrackDeeplink:normalLink callbackBlock:uBlock];
    
    [self waitForExpectationsWithTimeout:IterableNetworkResponseExpectationTimeout handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testDeeplinkAttributionInfo {
    NSNumber *campaignId = [NSNumber numberWithLong:83306];
    NSNumber *templateId = [NSNumber numberWithInt:124348];
    NSString *messageId = @"93125f33ba814b13a882358f8e0852e0";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    NSURL *normalLink = [NSURL URLWithString:iterableRewriteURL];
    ITEActionBlock uBlock = ^(NSString* redirectUrl) {
        XCTAssertEqualObjects(IterableAPI.instance.attributionInfo.campaignId, campaignId);
        XCTAssertEqualObjects(IterableAPI.instance.attributionInfo.templateId, templateId);
        XCTAssertEqualObjects(IterableAPI.instance.attributionInfo.messageId, messageId);
        [expectation fulfill];
    };
    [IterableAPI getAndTrackDeeplink:normalLink callbackBlock:uBlock];
    
    [self waitForExpectationsWithTimeout:IterableNetworkResponseExpectationTimeout handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testNoURLRedirect {
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    NSURL *redirectLink = [NSURL URLWithString:redirectRequest];
    ITEActionBlock redirectBlock = ^(NSString* redirectUrl) {
        [expectation fulfill];
        XCTAssertNotEqual(exampleUrl, redirectUrl);
        XCTAssertEqualObjects(redirectRequest, redirectUrl);
    };
    [IterableAPI getAndTrackDeeplink:redirectLink callbackBlock:redirectBlock];
    
    [self waitForExpectationsWithTimeout:IterableNetworkResponseExpectationTimeout handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testUniversalDeeplinkHttp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    NSURL *googleHttpLink = [NSURL URLWithString:googleHttps];
    ITEActionBlock googleHttpBlock = ^(NSString* redirectUrl) {
        [expectation fulfill];
        XCTAssertEqualObjects(googleHttps, redirectUrl);
        XCTAssertNotEqual(googleHttp, redirectUrl);
    };
    [IterableAPI getAndTrackDeeplink:googleHttpLink callbackBlock:googleHttpBlock];
    
    [self waitForExpectationsWithTimeout:IterableNetworkResponseExpectationTimeout handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testUniversalDeeplinkHttps {
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    NSString *googleHttps = @"https://www.google.com";
    
    NSURL *googleHttpsLink = [NSURL URLWithString:googleHttps];
    ITEActionBlock googleHttpsBlock = ^(NSString* redirectUrl) {
        [expectation fulfill];
        XCTAssertEqualObjects(googleHttps, redirectUrl);
    };
    [IterableAPI getAndTrackDeeplink:googleHttpsLink callbackBlock:googleHttpsBlock];
    
    [self waitForExpectationsWithTimeout:IterableNetworkResponseExpectationTimeout handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testURLQueryParamRewrite {
    [IterableAPI initializeWithApiKey:@"" launchOptions:nil config: nil email:nil userId:nil];

    NSCharacterSet* set = [NSCharacterSet URLQueryAllowedCharacterSet];
    
    NSMutableString* strSet =[NSMutableString string];
    for (int plane = 0; plane <= 16; plane++) {
        if ([set hasMemberInPlane:plane]) {
            UTF32Char c;
            for (c = plane << 16; c < (plane+1) << 16; c++) {
                if ([set longCharacterIsMember:c]) {
                    UTF32Char c1 = OSSwapHostToLittleInt32(c);
                    NSString *s = [[NSString alloc] initWithBytes:&c1 length:4 encoding:NSUTF32LittleEndianStringEncoding];
                    [strSet appendString:s];
                }
            }
        }
    }
    
    //Test full set of possible URLQueryAllowedCharacterSet characters
    NSString* encodedSet = [[IterableAPI instance] encodeURLParam:strSet];
    XCTAssertNotEqual(encodedSet, strSet);
    XCTAssert([encodedSet isEqualToString:@"!$&'()*%2B,-./0123456789:;=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~"]);
    
    NSString* encoded = [[IterableAPI instance] encodeURLParam:@"you+me@iterable.com"];
    XCTAssertNotEqual(encoded, @"you+me@iterable.com");
    XCTAssert([encoded isEqualToString:@"you%2Bme@iterable.com"]);
    
    NSString* emptySet = [[IterableAPI instance] encodeURLParam:@""];
    XCTAssertEqual(emptySet, @"");
    XCTAssert([emptySet isEqualToString:@""]);
    
    NSString* nilSet = [[IterableAPI instance] encodeURLParam:nil];
    XCTAssertEqualObjects(nilSet, nil);
}

@end
