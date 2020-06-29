//
//  Created by Tapash Majumder on 10/26/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class PromiseTests: XCTestCase {
    struct MyError: Error, CustomStringConvertible {
        let message: String
        
        var description: String {
            message
        }
    }
    
    func testMap() {
        let expectation1 = expectation(description: "test map")
        let expectation2 = expectation(description: "test map, inverted")
        expectation2.isInverted = true
        
        let f1 = createSucessfulFuture(withValue: "zeeString")
        let f2 = f1.map { $0.count }
        
        f2.onSuccess { value in
            XCTAssertEqual(value, "zeeString".count)
            expectation1.fulfill()
        }.onError { _ in
            expectation2.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
        wait(for: [expectation2], timeout: testExpectationTimeoutForInverted)
    }
    
    func testMapFailure() {
        let expectation1 = expectation(description: "test map failure, inverted")
        expectation1.isInverted = true
        let expectation2 = expectation(description: "test map failure")
        
        let f1: Future<String, Error> = createFailureFuture(withError: MyError(message: "zeeErrorMessage"))
        let f2 = f1.map { $0.count }
        
        f2.onSuccess { _ in
            expectation1.fulfill()
        }.onError { error in
            if let myError = error as? MyError {
                XCTAssertEqual(myError.message, "zeeErrorMessage")
                expectation2.fulfill()
            }
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }
    
    func testFlatMap() {
        let expectation1 = expectation(description: "test flatMap")
        let expectation2 = expectation(description: "test flatMap, inverted")
        expectation2.isInverted = true
        
        let f1 = createSucessfulFuture(withValue: "zeeString")
        
        let f2 = f1.flatMap { firstValue in
            self.createSucessfulFuture(withValue: firstValue + firstValue)
        }
        
        f2.onSuccess { secondValue in
            XCTAssertEqual(secondValue, "zeeStringzeeString")
            expectation1.fulfill()
        }.onError { _ in
            expectation2.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
        wait(for: [expectation2], timeout: testExpectationTimeoutForInverted)
    }
    
    // The first future fails
    func testFlatMapFailure1() {
        let expectation1 = expectation(description: "test flatMap failure, inverted")
        expectation1.isInverted = true
        let expectation2 = expectation(description: "test flatMap failure")
        
        let f1: Future<String, Error> = createFailureFuture(withError: MyError(message: "zeeErrorMessage"))
        
        let f2 = f1.flatMap { (_) -> Future<String, Error> in
            self.createSucessfulFuture(withValue: "zeeString")
        }
        
        f2.onSuccess { _ in
            expectation1.fulfill()
        }.onError { error in
            if let myError = error as? MyError {
                XCTAssertEqual(myError.message, "zeeErrorMessage")
                expectation2.fulfill()
            }
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }
    
    // The second future fails
    func testFlatMapFailure2() {
        let expectation1 = expectation(description: "test flatMap success, inverted")
        expectation1.isInverted = true
        let expectation2 = expectation(description: "test flatMap failure")
        
        let f1 = createSucessfulFuture(withValue: "zeeString")
        
        let f2 = f1.flatMap { (_) -> Future<String, Error> in
            self.createFailureFuture(withError: MyError(message: "zeeErrorMessage"))
        }
        
        f2.onSuccess { _ in
            expectation1.fulfill()
        }.onError { error in
            if let myError = error as? MyError {
                XCTAssertEqual(myError.message, "zeeErrorMessage")
                expectation2.fulfill()
            }
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }
    
    func testFutureInitWithSuccess() {
        let expectation1 = expectation(description: "test future init with success")
        let expectation2 = expectation(description: "test future init with success, inverted")
        expectation2.isInverted = true
        
        let f1: Future<String, Error> = Promise<String, Error>(value: "zeeValue")
        
        f1.onSuccess { value in
            XCTAssertEqual(value, "zeeValue")
            expectation1.fulfill()
        }.onError { _ in
            expectation2.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
        wait(for: [expectation2], timeout: testExpectationTimeoutForInverted)
    }
    
    func testFutureInitWithFailure() {
        let expectation1 = expectation(description: "test future init with failure, inverted")
        expectation1.isInverted = true
        let expectation2 = expectation(description: "test future init with failure")
        
        let f1: Future<String, Error> = Promise<String, Error>(error: MyError(message: "zeeErrorMessage"))
        
        f1.onSuccess { _ in
            expectation1.fulfill()
        }.onError { error in
            if let myError = error as? MyError {
                XCTAssertEqual(myError.message, "zeeErrorMessage")
                expectation2.fulfill()
            }
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }
    
    func testMultiValues() {
        let expectation1 = expectation(description: "test future init with success")
        expectation1.expectedFulfillmentCount = 3
        
        let f1 = createSucessfulFuture(withValue: true)
        
        f1.onSuccess { val in
            XCTAssertTrue(val)
            expectation1.fulfill()
        }
        
        f1.onSuccess { val in
            XCTAssertTrue(val)
            expectation1.fulfill()
        }
        
        f1.onSuccess { val in
            XCTAssertTrue(val)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testWaitUntilFinished() {
        let expectation1 = expectation(description: "testWaitUntilFinished")
        let future = Promise<Bool, Error>()
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.3) {
            future.resolve(with: true)
        }
        
        future.wait()
        expectation1.fulfill()
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    private func createSucessfulFuture<T>(withValue value: T) -> Future<T, Error> {
        let future = Promise<T, Error>()
        
        DispatchQueue.main.async {
            future.resolve(with: value)
        }
        
        return future
    }
    
    private func createFailureFuture<T>(withError error: MyError) -> Future<T, Error> {
        let future = Promise<T, Error>()
        
        DispatchQueue.main.async {
            future.reject(with: error)
        }
        
        return future
    }
}
