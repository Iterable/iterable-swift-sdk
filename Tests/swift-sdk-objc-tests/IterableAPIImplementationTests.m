//
//
//  Created by Ilya Brin on 5/25/16.
//  Copyright © 2016 Iterable. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <asl.h>
#import <OHHTTPStubs.h>
#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>

#import "swift_sdk_objc_tests-Swift.h"

@import IterableSDK;

static CGFloat const IterableNetworkResponseExpectationTimeout = 5.0;

@interface IterableAPIImplementationTests : XCTestCase
@end

@implementation IterableAPIImplementationTests

NSString *redirectRequest = @"https://httpbin.org/redirect-to?url=http://example.com";
NSString *exampleUrl = @"http://example.com";

NSString *googleHttps = @"https://www.google.com";
NSString *googleHttp = @"http://www.google.com";
NSString *iterableRewriteURL = @"http://links.iterable.com/a/60402396fbd5433eb35397b47ab2fb83?_e=joneng%40iterable.com&_m=93125f33ba814b13a882358f8e0852e0";
NSString *iterableNoRewriteURL = @"http://links.iterable.com/u/60402396fbd5433eb35397b47ab2fb83?_e=joneng%40iterable.com&_m=93125f33ba814b13a882358f8e0852e0";

- (void)setUp {
    [super setUp];
    [IterableAPIImplementation initializeWithApiKey:@""];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPushServicePlatformToString {
    XCTAssertEqualObjects(@"APNS", [IterableAPIImplementation pushServicePlatformToString:APNS]);
    XCTAssertEqualObjects(@"APNS_SANDBOX", [IterableAPIImplementation pushServicePlatformToString:APNS_SANDBOX]);
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
    NSString *result = [IterableAPIImplementation dictToJson:args];
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
    XCTAssertEqualObjects(@"Phone", [IterableAPIImplementation userInterfaceIdiomEnumToString:UIUserInterfaceIdiomPhone]);
    XCTAssertEqualObjects(@"Pad", [IterableAPIImplementation userInterfaceIdiomEnumToString:UIUserInterfaceIdiomPad]);
    // we don't care about TVs for now
    XCTAssertEqualObjects(@"Unspecified", [IterableAPIImplementation userInterfaceIdiomEnumToString:UIUserInterfaceIdiomTV]);
    XCTAssertEqualObjects(@"Unspecified", [IterableAPIImplementation userInterfaceIdiomEnumToString:UIUserInterfaceIdiomUnspecified]);
    XCTAssertEqualObjects(@"Unspecified", [IterableAPIImplementation userInterfaceIdiomEnumToString:192387]);
}

- (void)testUniversalDeeplinkRewrite {
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    NSURL *iterableLink = [NSURL URLWithString:iterableRewriteURL];
    ITEActionBlock aBlock = ^(NSString* redirectUrl) {
        XCTAssertEqualObjects(@"https://links.iterable.com/api/docs#!/email", redirectUrl);
        XCTAssertTrue(NSThread.isMainThread);
        [expectation fulfill];
    };
    [IterableAPIImplementation getAndTrackDeeplink:iterableLink callbackBlock:aBlock];
    
    [self waitForExpectationsWithTimeout:IterableNetworkResponseExpectationTimeout handler:nil];
}

- (void)testUniversalDeeplinkNoRewrite {
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    NSURL *normalLink = [NSURL URLWithString:iterableNoRewriteURL];
    ITEActionBlock uBlock = ^(NSString* redirectUrl) {
        XCTAssertEqualObjects(iterableNoRewriteURL, redirectUrl);
        [expectation fulfill];
    };
    [IterableAPIImplementation getAndTrackDeeplink:normalLink callbackBlock:uBlock];
    
    [self waitForExpectationsWithTimeout:IterableNetworkResponseExpectationTimeout handler:nil];
}

- (void)testHandleUniversalLinkRewrite {
    XCTestExpectation *expectation = [self expectationWithDescription:@"urlDelegate is called"];

    MockUrlDelegate *urlDelegateMock = [[MockUrlDelegate alloc] initWithReturnValue:NO];
    urlDelegateMock.callback = ^(NSURL *url, IterableActionContext *context) {
        XCTAssertEqualObjects(url.absoluteString, @"https://links.iterable.com/api/docs#!/email");
        XCTAssertEqualObjects(context.action.type, IterableAction.actionTypeOpenUrl);
        [expectation fulfill];
    };
    
    IterableConfig *config = [[IterableConfig alloc] init];
    config.urlDelegate = urlDelegateMock;
    [IterableAPIImplementation initializeWithApiKey:@"" config:config];
    NSURL *iterableLink = [NSURL URLWithString:iterableRewriteURL];
    [IterableAPIImplementation handleUniversalLink:iterableLink];
   
    [self waitForExpectationsWithTimeout:IterableNetworkResponseExpectationTimeout handler:nil];
}

- (void)testDeeplinkAttributionInfo {
    NSNumber *campaignId = [NSNumber numberWithLong:83306];
    NSNumber *templateId = [NSNumber numberWithInt:124348];
    NSString *messageId = @"93125f33ba814b13a882358f8e0852e0";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    NSURL *normalLink = [NSURL URLWithString:iterableRewriteURL];
    ITEActionBlock uBlock = ^(NSString* redirectUrl) {
        XCTAssertEqualObjects(IterableAPIImplementation.sharedInstance.attributionInfo.campaignId, campaignId);
        XCTAssertEqualObjects(IterableAPIImplementation.sharedInstance.attributionInfo.templateId, templateId);
        XCTAssertEqualObjects(IterableAPIImplementation.sharedInstance.attributionInfo.messageId, messageId);
        [expectation fulfill];
    };
    [IterableAPIImplementation getAndTrackDeeplink:normalLink callbackBlock:uBlock];
    
    [self waitForExpectationsWithTimeout:IterableNetworkResponseExpectationTimeout handler:nil];
}

- (void)testNoURLRedirect {
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    NSURL *redirectLink = [NSURL URLWithString:redirectRequest];
    ITEActionBlock redirectBlock = ^(NSString* redirectUrl) {
        [expectation fulfill];
        XCTAssertNotEqual(exampleUrl, redirectUrl);
        XCTAssertEqualObjects(redirectRequest, redirectUrl);
    };
    [IterableAPIImplementation getAndTrackDeeplink:redirectLink callbackBlock:redirectBlock];
    
    [self waitForExpectationsWithTimeout:IterableNetworkResponseExpectationTimeout handler:nil];
}

- (void)testUniversalDeeplinkHttp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    NSURL *googleHttpLink = [NSURL URLWithString:googleHttps];
    ITEActionBlock googleHttpBlock = ^(NSString* redirectUrl) {
        [expectation fulfill];
        XCTAssertEqualObjects(googleHttps, redirectUrl);
        XCTAssertNotEqual(googleHttp, redirectUrl);
    };
    [IterableAPIImplementation getAndTrackDeeplink:googleHttpLink callbackBlock:googleHttpBlock];
    
    [self waitForExpectationsWithTimeout:IterableNetworkResponseExpectationTimeout handler:nil];
}

- (void)testUniversalDeeplinkHttps {
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    NSString *googleHttps = @"https://www.google.com";
    
    NSURL *googleHttpsLink = [NSURL URLWithString:googleHttps];
    ITEActionBlock googleHttpsBlock = ^(NSString* redirectUrl) {
        [expectation fulfill];
        XCTAssertEqualObjects(googleHttps, redirectUrl);
    };
    [IterableAPIImplementation getAndTrackDeeplink:googleHttpsLink callbackBlock:googleHttpsBlock];
    
    [self waitForExpectationsWithTimeout:IterableNetworkResponseExpectationTimeout handler:nil];
}

- (void)testURLQueryParamRewrite {
    [IterableAPIImplementation initializeWithApiKey:@""];

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
    NSString* encodedSet = [[IterableAPIImplementation sharedInstance] encodeURLParam:strSet];
    XCTAssertNotEqual(encodedSet, strSet);
    XCTAssert([encodedSet isEqualToString:@"!$&'()*%2B,-./0123456789:;=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~"]);
    
    NSString* encoded = [[IterableAPIImplementation sharedInstance] encodeURLParam:@"you+me@iterable.com"];
    XCTAssertNotEqual(encoded, @"you+me@iterable.com");
    XCTAssert([encoded isEqualToString:@"you%2Bme@iterable.com"]);
    
    NSString* emptySet = [[IterableAPIImplementation sharedInstance] encodeURLParam:@""];
    XCTAssertEqual(emptySet, @"");
    XCTAssert([emptySet isEqualToString:@""]);
    
    NSString* nilSet = [[IterableAPIImplementation sharedInstance] encodeURLParam:nil];
    XCTAssertEqualObjects(nilSet, nil);
}

- (void)testRegisterToken {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Request is sent"];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        [expectation fulfill];
        NSDictionary *json = [NSJSONSerialization
                              JSONObjectWithData:request.OHHTTPStubs_HTTPBody
                              options:0 error:nil];
        XCTAssertEqualObjects(json[@"email"], @"user@example.com");
        XCTAssertEqualObjects(json[@"device"][@"applicationName"], @"pushIntegration");
        XCTAssertEqualObjects(json[@"device"][@"platform"], @"APNS_SANDBOX");
        XCTAssertEqualObjects(json[@"device"][@"token"], [[@"token" dataUsingEncoding:kCFStringEncodingUTF8] ITEHexadecimalString]);
        return [OHHTTPStubsResponse responseWithData:[@"" dataUsingEncoding:kCFStringEncodingUTF8] statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    IterableConfig *config = [[IterableConfig alloc] init];
    config.pushIntegrationName = @"pushIntegration";
    [IterableAPIImplementation initializeWithApiKey:@"apiKey" config:config];
    [[IterableAPIImplementation sharedInstance] setEmail:@"user@example.com"];
    [[IterableAPIImplementation sharedInstance] registerToken:[@"token" dataUsingEncoding:kCFStringEncodingUTF8]];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    [OHHTTPStubs removeAllStubs];
}

- (void)testEmailUserIdPersistence {
    [IterableAPIImplementation initializeWithApiKey:@"apiKey"];
    [[IterableAPIImplementation sharedInstance] setEmail:@"test@email.com"];
    
    [IterableAPIImplementation initializeWithApiKey:@"apiKey"];
    XCTAssertEqualObjects([IterableAPIImplementation sharedInstance].email, @"test@email.com");
    XCTAssertNil([IterableAPIImplementation sharedInstance].userId);
    
    [[IterableAPIImplementation sharedInstance] setUserId:@"testUserId"];

    [IterableAPIImplementation initializeWithApiKey:@"apiKey"];
    XCTAssertEqualObjects([IterableAPIImplementation sharedInstance].userId, @"testUserId");
    XCTAssertNil([IterableAPIImplementation sharedInstance].email);
}


@end
