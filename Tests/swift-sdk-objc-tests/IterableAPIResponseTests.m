//
//  IterableAPIResponseTests.m
//  Iterable-iOS-SDKTests
//
//  Created by Victor Babenko on 3/29/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OHHTTPStubs.h"
#import "OHPathHelpers.h"

@import IterableSDK;

static CGFloat const IterableResponseExpectationTimeout = 1.0;

@interface IterableAPIResponseTests : XCTestCase

@end

@implementation IterableAPIResponseTests

- (void)setUp {
    [super setUp];
    [IterableAPI initializeWithApiKey:@""];
}

- (void)tearDown {
    [OHHTTPStubs removeAllStubs];
    [super tearDown];
}

- (NSDictionary *)defaultResponseHeaders {
    return @{@"Content-Type":@"application/json"};
}

- (void)stubAnyRequestReturningStatusCode:(int)statusCode data:(NSData *)data {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        return [OHHTTPStubsResponse responseWithData:data statusCode:statusCode headers:self.defaultResponseHeaders];
    }];
}

- (void)stubAnyRequestReturningStatusCode:(int)statusCode json:(NSDictionary *)json {
    NSError *error = nil;
    NSData *jsonResponseData = [NSJSONSerialization dataWithJSONObject:json
                                                               options:0 error:&error];
    [self stubAnyRequestReturningStatusCode:statusCode data:jsonResponseData];
}

- (void)testResponseCode200 {
    NSDictionary *responseData = @{@"key":@"value"};
    [self stubAnyRequestReturningStatusCode:200 json:responseData];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"onSuccess is called"];
    
    NSURLRequest *request = [[IterableAPI sharedInstance] createPostRequestForAction:@"" withArgs:@{}];
    [[IterableAPI sharedInstance] sendRequest:request onSuccess:^(NSDictionary * _Nonnull data) {
        [expectation fulfill];
        XCTAssert([data isEqualToDictionary:responseData]);
    } onFailure:nil];
    [self waitForExpectations:@[expectation] timeout:IterableResponseExpectationTimeout];
}

- (void)testResponseCode200WithNoData {
    [self stubAnyRequestReturningStatusCode:200 data:nil];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"onFailure is called"];
    
    NSURLRequest *request = [[IterableAPI sharedInstance] createPostRequestForAction:@"" withArgs:@{}];
    [[IterableAPI sharedInstance] sendRequest:request onSuccess:nil onFailure:^(NSString * _Nonnull reason, NSData * _Nullable data) {
        [expectation fulfill];
        XCTAssertEqualObjects(reason, @"No data received");
    }];
    [self waitForExpectations:@[expectation] timeout:IterableResponseExpectationTimeout];
}

- (void)testResponseCode200WithInvalidJson {
    [self stubAnyRequestReturningStatusCode:200 data:[@"{'''}}" dataUsingEncoding:NSUTF8StringEncoding]];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"onFailure is called"];
    
    NSURLRequest *request = [[IterableAPI sharedInstance] createPostRequestForAction:@"" withArgs:@{}];
    [[IterableAPI sharedInstance] sendRequest:request onSuccess:nil onFailure:^(NSString * _Nonnull reason, NSData * _Nullable data) {
        [expectation fulfill];
        XCTAssert([reason containsString:@"Could not parse json"]);
    }];
    [self waitForExpectations:@[expectation] timeout:IterableResponseExpectationTimeout];
}

- (void)testResponseCode400WithoutMessage {
    [self stubAnyRequestReturningStatusCode:400 json:@{}];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"onFailure is called"];
    
    NSURLRequest *request = [[IterableAPI sharedInstance] createPostRequestForAction:@"" withArgs:@{}];
    [[IterableAPI sharedInstance] sendRequest:request onSuccess:nil onFailure:^(NSString * _Nonnull reason, NSData * _Nullable data) {
        [expectation fulfill];
        XCTAssert([reason containsString:@"Invalid Request"]);
    }];
    [self waitForExpectations:@[expectation] timeout:IterableResponseExpectationTimeout];
}

- (void)testResponseCode400WithMessage {
    [self stubAnyRequestReturningStatusCode:400 json:@{@"msg":@"Test error"}];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"onFailure is called"];
    
    NSURLRequest *request = [[IterableAPI sharedInstance] createPostRequestForAction:@"" withArgs:@{}];
    [[IterableAPI sharedInstance] sendRequest:request onSuccess:nil onFailure:^(NSString * _Nonnull reason, NSData * _Nullable data) {
        [expectation fulfill];
        XCTAssertEqualObjects(reason, @"Test error");
    }];
    [self waitForExpectations:@[expectation] timeout:IterableResponseExpectationTimeout];
}

- (void)testResponseCode401 {
    [self stubAnyRequestReturningStatusCode:401 json:@{}];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"onFailure is called"];
    
    NSURLRequest *request = [[IterableAPI sharedInstance] createPostRequestForAction:@"" withArgs:@{}];
    [[IterableAPI sharedInstance] sendRequest:request onSuccess:nil onFailure:^(NSString * _Nonnull reason, NSData * _Nullable data) {
        [expectation fulfill];
        XCTAssertEqualObjects(reason, @"Invalid API Key");
    }];
    [self waitForExpectations:@[expectation] timeout:IterableResponseExpectationTimeout];
}

- (void)testResponseCode500 {
    [self stubAnyRequestReturningStatusCode:500 json:@{}];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"onFailure is called"];
    
    NSURLRequest *request = [[IterableAPI sharedInstance] createPostRequestForAction:@"" withArgs:@{}];
    [[IterableAPI sharedInstance] sendRequest:request onSuccess:nil onFailure:^(NSString * _Nonnull reason, NSData * _Nullable data) {
        [expectation fulfill];
        XCTAssertEqualObjects(reason, @"Internal Server Error");
    }];
    [self waitForExpectations:@[expectation] timeout:IterableResponseExpectationTimeout];
}

- (void)testNon200ResponseCode {
    [self stubAnyRequestReturningStatusCode:302 json:@{}];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"onFailure is called"];
    
    NSURLRequest *request = [[IterableAPI sharedInstance] createPostRequestForAction:@"" withArgs:@{}];
    [[IterableAPI sharedInstance] sendRequest:request onSuccess:nil onFailure:^(NSString * _Nonnull reason, NSData * _Nullable data) {
        [expectation fulfill];
        XCTAssert([reason containsString:@"Received non-200 response"]);
    }];
    [self waitForExpectations:@[expectation] timeout:IterableResponseExpectationTimeout];
}

- (void)testNoNetworkResponse {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSError* notConnectedError = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
        return [OHHTTPStubsResponse responseWithError:notConnectedError];
    }];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"onFailure is called"];
    
    NSURLRequest *request = [[IterableAPI sharedInstance] createPostRequestForAction:@"" withArgs:@{}];
    [[IterableAPI sharedInstance] sendRequest:request onSuccess:nil onFailure:^(NSString * _Nonnull reason, NSData * _Nullable data) {
        [expectation fulfill];
        XCTAssert([reason containsString:@"NSURLErrorDomain"]);
    }];
    [self waitForExpectations:@[expectation] timeout:IterableResponseExpectationTimeout];
}

- (void)testNetworkTimeoutResponse {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSError* notConnectedError = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
        return [[OHHTTPStubsResponse responseWithData:nil statusCode:200 headers:nil] requestTime:0.0 responseTime:5.0];
    }];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"onFailure is called"];
    
    NSMutableURLRequest *request = (NSMutableURLRequest *) [[IterableAPI sharedInstance] createPostRequestForAction:@"" withArgs:@{}];
    request.timeoutInterval = 0.01;
    [[IterableAPI sharedInstance] sendRequest:request onSuccess:nil onFailure:^(NSString * _Nonnull reason, NSData * _Nullable data) {
        [expectation fulfill];
        XCTAssert([reason containsString:@"timed out"]);
    }];
    [self waitForExpectations:@[expectation] timeout:IterableResponseExpectationTimeout];
}

@end
