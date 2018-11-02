//
//  Promise.swift
//  swift-sdk
//
//  Created by Tapash Majumder on 10/26/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

enum Result<Value, ErrorType> {
    case value(Value)
    case error(ErrorType)
}

// This has only two public methods
// either there is a success with result
// or there is a failure with error
// There is no way to set value a result in this class.
class Future<Value, ErrorType> {
    fileprivate var successCallback: ((Value) -> Void)? = nil
    fileprivate var failureCallback: ((ErrorType) -> Void)? = nil

    @discardableResult func onSuccess(block: ((Value) -> Void)? = nil) -> Future<Value, ErrorType> {
        self.successCallback = block

        // if a successful result already exists (from constructor), report it
        if case let Result.value(value)? = result {
            successCallback?(value)
        }
        
        return self
    }
    
    @discardableResult func onFailure(block: ((ErrorType) -> Void)? = nil) -> Future<Value, ErrorType> {
        self.failureCallback = block
        
        // if a failed result already exists (from constructor), report it
        if case let Result.error(error)? = result {
            failureCallback?(error)
        }

        return self
    }

    fileprivate var result: Result<Value, ErrorType>? {
        // Observe whenever a result is assigned, and report it
        didSet { result.map(report) }
    }
    
    // Report success or error based on result
    private func report(result: Result<Value, ErrorType>) {
        switch result {
        case .value(let value):
            successCallback?(value)
            break
        case .error(let error):
            print("calling onFailure")
            failureCallback?(error)
            break
        }
    }
}

extension Future {
    func flatMap<NextValue>(_ closure: @escaping (Value) -> Future<NextValue, ErrorType>) -> Future<NextValue, ErrorType> {
        let promise = Promise<NextValue, ErrorType>()
        
        onSuccess { (value) in
            let future = closure(value)
            
            future.onSuccess { futureValue in
                promise.resolve(with: futureValue)
            }
            
            future.onFailure { futureError in
                promise.reject(with: futureError)
            }
        }
        
        onFailure  { error in
            promise.reject(with: error)
        }
        
        return promise
    }
    
    func map<NextValue>(_ closure: @escaping (Value) -> NextValue) -> Future<NextValue, ErrorType> {
        let promise = Promise<NextValue, ErrorType>()
        
        onSuccess { value in
            let nextValue = closure(value)
            promise.resolve(with: nextValue)
        }
        
        onFailure { error in
            promise.reject(with: error)
        }
        
        return promise
    }
}


// This class takes the responsibility of setting value for Future
class Promise<Value, ErrorType> : Future<Value, ErrorType> {
    init(value: Value? = nil) {
        super.init()
        result = value.map(Result.value)
    }
    
    init(error: ErrorType) {
        super.init()
        result = Result.error(error)
    }
    
    func resolve(with value: Value) {
        result = .value(value)
    }
    
    func reject(with error: ErrorType) {
        result = .error(error)
    }
}

