//
//  ThreadSafeOrderedDictionary.swift
//  swift-sdk
//
//  Created by Ricky on 11/6/24.
//  Copyright © 2024 Iterable. All rights reserved.
//

import Foundation

public final class ThreadSafeOrderedDictionary<K: Hashable, V> {
    private var orderedDictionary = OrderedDictionary<K, V>()
    private let lock = NSLock()
    
    public var keys: [K] {
        lock.withLock {
            orderedDictionary.keys
        }
    }
    
    public var count: Int {
        lock.withLock {
            orderedDictionary.count
        }
    }
    
    public var values: [V] {
        lock.withLock {
            orderedDictionary.values
        }
    }
    
    public subscript(key: K) -> V? {
        get {
            lock.withLock {
                orderedDictionary[key]
            }
        }
        set {
            lock.withLock {
                orderedDictionary[key] = newValue
            }
        }
    }
    
    @discardableResult public func updateValue(_ value: V?, forKey key: K) -> V? {
        lock.withLock {
            orderedDictionary.updateValue(value, forKey: key)
        }
    }
    
    @discardableResult public func removeValue(forKey key: K) -> V? {
        lock.withLock {
            orderedDictionary.removeValue(forKey: key)
        }
    }
    
    public func reset() {
        lock.withLock {
            orderedDictionary.reset()
        }
    }
    
    public func makeIterator() -> AnyIterator<(key: K, value: V)> {
        lock.withLock {
            orderedDictionary.makeIterator()
        }
    }
    
    public var description: String {
        lock.withLock {
            orderedDictionary.description
        }
    }
}

// Conformance to ExpressibleByDictionaryLiteral
extension ThreadSafeOrderedDictionary: ExpressibleByDictionaryLiteral {
    public convenience init(dictionaryLiteral elements: (K, V)...) {
        self.init()
        for (key, value) in elements {
            self[key] = value
        }
    }
}
