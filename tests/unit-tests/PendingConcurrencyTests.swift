//
//  Copyright © 2026 Iterable. All rights reserved.
//
//  Tests for thread-safety of `Pending` / `Fulfill` (SDK-471).
//
//  These exercise the race paths that Apple's Thread Sanitizer flagged on
//  `successCallbacks`, `errorCallbacks`, and `result` in `swift-sdk/Internal/Pending.swift`.
//  Each test races registration (`onSuccess` / `onError` / `onCompletion`) against
//  resolution (`resolve` / `reject`) across queues. With the fix in place, every
//  callback must fire exactly once per matching resolution and no crash / TSan
//  report should occur.
//

import XCTest

@testable import IterableSDK

class PendingConcurrencyTests: XCTestCase {
    struct MyError: Error, Equatable {
        let message: String
    }

    private let producerQueue = DispatchQueue(label: "test.pending.producer", attributes: .concurrent)
    private let consumerQueue = DispatchQueue(label: "test.pending.consumer", attributes: .concurrent)

    // MARK: - Concurrent registration vs resolve

    func testConcurrentOnSuccessAndResolve() {
        let registrationCount = 50
        let expectation1 = expectation(description: "all onSuccess callbacks fire")
        expectation1.expectedFulfillmentCount = registrationCount

        let pending = Fulfill<Int, MyError>()
        let invocations = AtomicInt()

        let group = DispatchGroup()
        for _ in 0..<registrationCount {
            group.enter()
            consumerQueue.async {
                pending.onSuccess { _ in
                    invocations.increment()
                    expectation1.fulfill()
                }
                group.leave()
            }
        }

        producerQueue.async {
            // Resolve while registrations are still racing in.
            pending.resolve(with: 42)
        }

        wait(for: [expectation1], timeout: testExpectationTimeout)
        group.wait()
        XCTAssertEqual(invocations.value, registrationCount)
    }

    func testConcurrentOnErrorAndReject() {
        let registrationCount = 50
        let expectation1 = expectation(description: "all onError callbacks fire")
        expectation1.expectedFulfillmentCount = registrationCount

        let pending = Fulfill<Int, MyError>()
        let invocations = AtomicInt()

        let group = DispatchGroup()
        for _ in 0..<registrationCount {
            group.enter()
            consumerQueue.async {
                pending.onError { _ in
                    invocations.increment()
                    expectation1.fulfill()
                }
                group.leave()
            }
        }

        producerQueue.async {
            pending.reject(with: MyError(message: "boom"))
        }

        wait(for: [expectation1], timeout: testExpectationTimeout)
        group.wait()
        XCTAssertEqual(invocations.value, registrationCount)
    }

    // MARK: - onCompletion atomicity

    /// Stress-tests the historical partial-append bug: prior to SDK-471, `onCompletion`
    /// appended `receiveValue` first and then conditionally appended `receiveError`. A
    /// `.failure` resolve landing between the two appends would lose the error handler.
    /// After the fix, both appends happen inside a single `stateQueue.sync` so this can
    /// never happen. We assert exactly one of (success, error) fires for each pairing.
    func testOnCompletionAtomicityUnderRace() {
        let iterations = 200
        let expectation1 = expectation(description: "every Pending fires exactly one branch")
        expectation1.expectedFulfillmentCount = iterations

        for i in 0..<iterations {
            let pending = Fulfill<Int, MyError>()
            let successCount = AtomicInt()
            let errorCount = AtomicInt()

            let operationGroup = DispatchGroup()

            operationGroup.enter()
            consumerQueue.async {
                pending.onCompletion(receiveValue: { _ in
                    successCount.increment()
                }, receiveError: { _ in
                    errorCount.increment()
                })
                operationGroup.leave()
            }

            operationGroup.enter()
            producerQueue.async {
                if i.isMultiple(of: 2) {
                    pending.resolve(with: i)
                } else {
                    pending.reject(with: MyError(message: "n=\(i)"))
                }
                operationGroup.leave()
            }

            DispatchQueue.global().async {
                operationGroup.wait()
                let total = successCount.value + errorCount.value
                XCTAssertEqual(total, 1, "iteration \(i) saw success=\(successCount.value) error=\(errorCount.value)")
                expectation1.fulfill()
            }
        }

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    // MARK: - Re-entrancy

    /// A callback fired during resolution registers another callback on the same
    /// Pending instance. The inner registration must not deadlock the state queue
    /// (we drop the lock before invoking user code) and must fire synchronously with
    /// the already-stored result.
    func testReentrantRegistrationFromCallback() {
        let expectationOuter = expectation(description: "outer onSuccess fires")
        let expectationInner = expectation(description: "re-entrant onSuccess fires")

        let pending = Fulfill<String, MyError>()

        pending.onSuccess { [weak pending] value in
            XCTAssertEqual(value, "hello")
            expectationOuter.fulfill()
            // Re-enter on the same instance. Must not deadlock.
            pending?.onSuccess { innerValue in
                XCTAssertEqual(innerValue, "hello")
                expectationInner.fulfill()
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            pending.resolve(with: "hello")
        }

        wait(for: [expectationOuter, expectationInner], timeout: testExpectationTimeout)
    }

    // MARK: - flatMap across queues

    func testFlatMapCrossQueueResolution() {
        let expectation1 = expectation(description: "flatMap chain completes across queues")

        let outer = Fulfill<Int, MyError>()
        let chained = outer.flatMap { value -> Pending<String, MyError> in
            let inner = Fulfill<String, MyError>()
            DispatchQueue.main.async {
                inner.resolve(with: "v=\(value)")
            }
            return inner
        }

        DispatchQueue.global(qos: .background).async {
            chained.onCompletion { result in
                XCTAssertEqual(result, "v=7")
                expectation1.fulfill()
            } receiveError: { _ in
                XCTFail("error branch should not fire")
            }
        }

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.05) {
            outer.resolve(with: 7)
        }

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    // MARK: - Late registration after resolve

    /// Locks in the fix for the O(N^2) latent bug: prior to SDK-471, registering N
    /// callbacks on an already-resolved Pending iterated the full accumulated array
    /// each time, firing earlier callbacks repeatedly. After the fix each
    /// late-registered callback replays the current result once.
    func testLateRegisterAfterResolveFiresOnce() {
        let pending = Fulfill<Int, MyError>(value: 99)
        XCTAssertTrue(pending.isResolved())

        let registrationCount = 3
        let expectation1 = expectation(description: "each late onSuccess fires once")
        expectation1.expectedFulfillmentCount = registrationCount
        expectation1.assertForOverFulfill = true

        DispatchQueue.concurrentPerform(iterations: registrationCount) { _ in
            pending.onSuccess { value in
                XCTAssertEqual(value, 99)
                expectation1.fulfill()
            }
        }

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testLateRegisterAfterResolveStaysRegisteredForFutureResolves() {
        let pending = Fulfill<Int, MyError>(value: 99)
        var firstValues = [Int]()
        var secondValues = [Int]()

        pending.onSuccess { value in
            firstValues.append(value)
        }

        pending.onSuccess { value in
            secondValues.append(value)
        }

        XCTAssertEqual(firstValues, [99])
        XCTAssertEqual(secondValues, [99])

        pending.resolve(with: 100)

        XCTAssertEqual(firstValues, [99, 100])
        XCTAssertEqual(secondValues, [99, 100])
    }

    // MARK: - Repeated resolution

    func testRepeatedResolveNotifiesRegisteredCallbacks() {
        let pending = Fulfill<Int, MyError>()
        var values = [Int]()

        pending.onSuccess { value in
            values.append(value)
        }

        pending.resolve(with: 1)
        pending.resolve(with: 2)

        XCTAssertEqual(values, [1, 2])
    }

    func testRepeatedRejectNotifiesRegisteredCallbacks() {
        let pending = Fulfill<Int, MyError>()
        var errors = [MyError]()

        pending.onError { error in
            errors.append(error)
        }

        pending.reject(with: MyError(message: "first"))
        pending.reject(with: MyError(message: "second"))

        XCTAssertEqual(errors, [MyError(message: "first"), MyError(message: "second")])
    }

    func testResolveAfterRejectNotifiesMatchingBranches() {
        let pending = Fulfill<Int, MyError>()
        var events = [String]()

        pending.onCompletion(receiveValue: { _ in
            events.append("success")
        }, receiveError: { error in
            events.append("error:\(error.message)")
        })

        pending.reject(with: MyError(message: "first"))
        pending.resolve(with: 42)

        XCTAssertEqual(events, ["error:first", "success"])
    }

    // MARK: - Stress

    /// Heavy concurrent load: many Fulfills are created on a producer queue and
    /// resolved on another while consumers register `onSuccess` against each. Passes
    /// if no crash and all callbacks fire.
    func testStress1000Iterations() {
        let iterations = 1000
        let expectation1 = expectation(description: "stress: every callback fires")
        expectation1.expectedFulfillmentCount = iterations

        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let pending = Fulfill<Int, MyError>()

            consumerQueue.async {
                pending.onSuccess { value in
                    XCTAssertEqual(value, i)
                    expectation1.fulfill()
                }
            }

            producerQueue.async {
                pending.resolve(with: i)
            }
        }

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
}

/// Tiny lock-protected counter used to verify exact invocation counts under
/// concurrent fire. `OSAtomicIncrement32` is deprecated; an `NSLock` matches the
/// codebase style of preferring Foundation primitives.
private final class AtomicInt {
    private var _value: Int = 0
    private let lock = NSLock()

    func increment() {
        lock.lock()
        _value += 1
        lock.unlock()
    }

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }
}
