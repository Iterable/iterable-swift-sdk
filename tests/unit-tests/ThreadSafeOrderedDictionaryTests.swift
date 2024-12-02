//
//  ThreadSafeOrderedDictionaryTests.swift
//  unit-tests
//
//  Created by Ricky on 11/6/24.
//  Copyright © 2024 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class ThreadSafeOrderedDictionaryTests: XCTestCase {
    func testConcurrentAccess() {
        let orderedDict = ThreadSafeOrderedDictionary<String, Int>()
        
        // Initialize with some data
        orderedDict["initialKey"] = 0
        
        let iterations = 1_000
        let concurrentQueue = DispatchQueue.global(qos: .userInitiated)
        
        // Dispatch group to wait for all tasks to complete
        let dispatchGroup = DispatchGroup()
        
        // Concurrently write to the dictionary
        dispatchGroup.enter()
        concurrentQueue.async {
            DispatchQueue.concurrentPerform(iterations: iterations) { i in
                print(i, "Here 1")
                orderedDict["key_\(i)"] = i
            }
            dispatchGroup.leave()
        }
        
        // Concurrently read from the dictionary
        dispatchGroup.enter()
        concurrentQueue.async {
            DispatchQueue.concurrentPerform(iterations: iterations) { i in
                print(i, "Here 2")
                _ = orderedDict["key_\(i % 10)"]
            }
            dispatchGroup.leave()
        }
        
        // Wait for all operations to finish
        let result = dispatchGroup.wait(timeout: .now() + 10)
                
        // Assert that all operations completed
        XCTAssertEqual(result, .success, "Test timed out - possible deadlock or crash occurred.")
        
        // Check if dictionary contains at least one expected entry
        XCTAssertGreaterThanOrEqual(orderedDict.count, 1, "Count should be greater than or equal to 1 after concurrent writes")
    }
}
