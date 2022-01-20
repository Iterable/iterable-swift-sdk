//
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class PendingTests: XCTestCase {
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
        
        f2.onCompletion { value in
            XCTAssertEqual(value, "zeeString".count)
            expectation1.fulfill()
        } receiveError: { _ in
            expectation2.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
        wait(for: [expectation2], timeout: testExpectationTimeoutForInverted)
    }
    
    func testMapFailure() {
        let expectation1 = expectation(description: "test map failure, inverted")
        expectation1.isInverted = true
        let expectation2 = expectation(description: "test map failure")
        
        let f1: Pending<String, Error> = createFailureFuture(withError: MyError(message: "zeeErrorMessage"))
        let f2 = f1.map { $0.count }
        
        f2.onCompletion { _ in
            expectation1.fulfill()
        } receiveError: { error in
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
        
        f2.onCompletion { secondValue in
            XCTAssertEqual(secondValue, "zeeStringzeeString")
            expectation1.fulfill()
        } receiveError: { _ in
            expectation2.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
        wait(for: [expectation2], timeout: testExpectationTimeoutForInverted)
    }
    
    // The first pending fails
    func testFlatMapFailure1() {
        let expectation1 = expectation(description: "test flatMap failure, inverted")
        expectation1.isInverted = true
        let expectation2 = expectation(description: "test flatMap failure")
        
        let f1: Pending<String, Error> = createFailureFuture(withError: MyError(message: "zeeErrorMessage"))
        
        let f2 = f1.flatMap { (_) -> Pending<String, Error> in
            self.createSucessfulFuture(withValue: "zeeString")
        }
        
        f2.onCompletion { _ in
            expectation1.fulfill()
        } receiveError: { error in
            if let myError = error as? MyError {
                XCTAssertEqual(myError.message, "zeeErrorMessage")
                expectation2.fulfill()
            }
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }
    
    // The second pending fails
    func testFlatMapFailure2() {
        let expectation1 = expectation(description: "test flatMap success, inverted")
        expectation1.isInverted = true
        let expectation2 = expectation(description: "test flatMap failure")
        
        let f1 = createSucessfulFuture(withValue: "zeeString")
        
        let f2 = f1.flatMap { (_) -> Pending<String, Error> in
            self.createFailureFuture(withError: MyError(message: "zeeErrorMessage"))
        }
        
        f2.onCompletion { _ in
            expectation1.fulfill()
        } receiveError: { error in
            if let myError = error as? MyError {
                XCTAssertEqual(myError.message, "zeeErrorMessage")
                expectation2.fulfill()
            }
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }
    
    func testFutureInitWithSuccess() {
        let expectation1 = expectation(description: "test pending init with success")
        let expectation2 = expectation(description: "test pending init with success, inverted")
        expectation2.isInverted = true
        
        let f1: Pending<String, Error> = Fulfill<String, Error>(value: "zeeValue")
        
        f1.onCompletion { value in
            XCTAssertEqual(value, "zeeValue")
            expectation1.fulfill()
        } receiveError: { _ in
            expectation2.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
        wait(for: [expectation2], timeout: testExpectationTimeoutForInverted)
    }
    
    func testFutureInitWithFailure() {
        let expectation1 = expectation(description: "test pending init with failure, inverted")
        expectation1.isInverted = true
        let expectation2 = expectation(description: "test pending init with failure")
        
        let f1: Pending<String, Error> = Fulfill<String, Error>(error: MyError(message: "zeeErrorMessage"))
        
        f1.onCompletion { _ in
            expectation1.fulfill()
        } receiveError: { error in
            if let myError = error as? MyError {
                XCTAssertEqual(myError.message, "zeeErrorMessage")
                expectation2.fulfill()
            }
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }
    
    func testMultiValues() {
        let expectation1 = expectation(description: "test pending init with success")
        expectation1.expectedFulfillmentCount = 3
        
        let f1 = createSucessfulFuture(withValue: true)
        
        f1.onCompletion { val in
            XCTAssertTrue(val)
            expectation1.fulfill()
        }
        
        f1.onCompletion { val in
            XCTAssertTrue(val)
            expectation1.fulfill()
        }
        
        f1.onCompletion { val in
            XCTAssertTrue(val)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testWaitUntilFinished() {
        let expectation1 = expectation(description: "testWaitUntilFinished")
        let pending = Fulfill<Bool, Error>()
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.3) {
            pending.resolve(with: true)
        }
        
        pending.wait()
        expectation1.fulfill()
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    private func createSucessfulFuture<T>(withValue value: T) -> Pending<T, Error> {
        let pending = Fulfill<T, Error>()
        
        DispatchQueue.main.async {
            pending.resolve(with: value)
        }
        
        return pending
    }
    
    private func createFailureFuture<T>(withError error: MyError) -> Pending<T, Error> {
        let pending = Fulfill<T, Error>()
        
        DispatchQueue.main.async {
            pending.reject(with: error)
        }
        
        return pending
    }
}
