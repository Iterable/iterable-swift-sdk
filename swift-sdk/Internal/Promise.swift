//
//  Promise.swift
//  swift-sdk
//
//  Created by Tapash Majumder on 10/26/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

public enum Result<Value> {
    case value(Value)
    case error(Error)
}

// This has only two public methods
// either there is a success with result
// or there is a failure with error
// There is no way to set value a result in this class.
public class Future<Value> {
    fileprivate var successCallback: ((Value) -> Void)? = nil
    fileprivate var errorCallback: ((Error) -> Void)? = nil

    @discardableResult public func onSuccess(block: ((Value) -> Void)? = nil) -> Future<Value> {
        self.successCallback = block

        // if a successful result already exists (from constructor), report it
        if case let Result.value(value)? = result {
            successCallback?(value)
        }
        
        return self
    }
    
    @discardableResult public func onError(block: ((Error) -> Void)? = nil) -> Future<Value> {
        self.errorCallback = block
        
        // if a failed result already exists (from constructor), report it
        if case let Result.error(error)? = result {
            errorCallback?(error)
        }

        return self
    }

    fileprivate var result: Result<Value>? {
        // Observe whenever a result is assigned, and report it
        didSet { result.map(report) }
    }
    
    // Report success or error based on result
    private func report(result: Result<Value>) {
        switch result {
        case .value(let value):
            successCallback?(value)
            break
        case .error(let error):
            errorCallback?(error)
            break
        }
    }
}

public extension Future {
    func flatMap<NextValue>(_ closure: @escaping (Value) -> Future<NextValue>) -> Future<NextValue> {
        let promise = Promise<NextValue>()
        
        onSuccess { (value) in
            let future = closure(value)
            
            future.onSuccess { futureValue in
                promise.resolve(with: futureValue)
            }
            
            future.onError { futureError in
                promise.reject(with: futureError)
            }
        }
        
        onError  { error in
            promise.reject(with: error)
        }
        
        return promise
    }

    func map<NextValue>(_ closure: @escaping (Value) -> NextValue) -> Future<NextValue> {
        let promise = Promise<NextValue>()
        
        onSuccess { value in
            let nextValue = closure(value)
            promise.resolve(with: nextValue)
        }
        
        onError { error in
            promise.reject(with: error)
        }
        
        return promise
    }
}


// This class takes the responsibility of setting value for Future
public class Promise<Value> : Future<Value> {
    public init(value: Value? = nil) {
        super.init()
        result = value.map(Result.value)
    }
    
    public init(error: Error) {
        super.init()
        result = Result.error(error)
    }
    
    public func resolve(with value: Value) {
        result = .value(value)
    }
    
    public func reject(with error: Error) {
        result = .error(error)
    }
}

