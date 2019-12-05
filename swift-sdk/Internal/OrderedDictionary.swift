//
//  Created by Tapash Majumder on 1/2/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

public struct OrderedDictionary<K: Hashable, V> {
    public var keys = [K]()
    
    public var count: Int {
        return keys.count
    }
    
    public var values: [V] {
        return map { $0.1 }
    }
    
    public subscript(key: K) -> V? {
        get {
            return dict[key]
        }
        
        set(newValue) {
            if newValue == nil {
                dict.removeValue(forKey: key)
                keys = keys.filter { $0 != key }
            } else {
                let oldValue = dict.updateValue(newValue!, forKey: key)
                if oldValue == nil {
                    keys.append(key)
                }
            }
        }
    }
    
    @discardableResult public mutating func updateValue(_ value: V?, forKey key: K) -> V? {
        let prevValue = dict[key]
        self[key] = value
        return prevValue
    }
    
    @discardableResult public mutating func removeValue(forKey key: K) -> V? {
        let prevValue = dict[key]
        self[key] = nil
        return prevValue
    }
    
    public mutating func reset() {
        keys.removeAll()
        dict.removeAll()
    }
    
    private var dict = [K: V]()
}

extension OrderedDictionary: Sequence {
    public func makeIterator() -> AnyIterator<(key: K, value: V)> {
        var counter = 0
        return AnyIterator {
            guard counter < self.keys.count else {
                return nil
            }
            
            let key = self.keys[counter]
            guard let value = self.dict[key] else {
                return nil
            }
            
            counter += 1
            return (key, value)
        }
    }
}

extension OrderedDictionary: CustomStringConvertible {
    public var description: String {
        return keys.map {
            var valueToDisplay = ""
            
            if let value = dict[$0] as? CustomStringConvertible {
                valueToDisplay = value.description
            } else {
                valueToDisplay = "nil"
            }
            
            return "\($0) : \(valueToDisplay)"
        }.joined(separator: ", ")
    }
}

extension OrderedDictionary: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (K, V)...) {
        self.init()
        
        for (key, value) in elements {
            self[key] = value
        }
    }
}
