//
//  Promise.swift
//  swift-sdk
//
//  Created by Tapash Majumder on 10/26/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

public enum IterableError : Error {
    case general(description: String)
}

extension IterableError : LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .general(let description):
            return description
        }
    }
}

// This has only two public methods
// either there is a success with result
// or there is a failure with error
// There is no way to set value a result in this class.
public class Future<Value, Failure> where Failure : Error {
    fileprivate var successCallback: ((Value) -> Void)? = nil
    fileprivate var errorCallback: ((Failure) -> Void)? = nil

    @discardableResult public func onSuccess(block: ((Value) -> Void)? = nil) -> Future<Value, Failure> {
        self.successCallback = block

        // if a successful result already exists (from constructor), report it
        if case let Result.success(value)? = result {
            successCallback?(value)
        }
        
        return self
    }
    
    @discardableResult public func onError(block: ((Failure) -> Void)? = nil) -> Future<Value, Failure> {
        self.errorCallback = block
        
        // if a failed result already exists (from constructor), report it
        if case let Result.failure(error)? = result {
            errorCallback?(error)
        }

        return self
    }

    fileprivate var result: Result<Value, Failure>? {
        // Observe whenever a result is assigned, and report it
        didSet { result.map(report) }
    }
    
    // Report success or error based on result
    private func report(result: Result<Value, Failure>) {
        switch result {
        case .success(let value):
            successCallback?(value)
            break
        case .failure(let error):
            errorCallback?(error)
            break
        }
    }
}

public extension Future {
    func flatMap<NewValue>(_ closure: @escaping (Value) -> Future<NewValue, Failure>) -> Future<NewValue, Failure> {
        let promise = Promise<NewValue, Failure>()
        
        onSuccess { (value) in
            let future = closure(value)
            
            future.onSuccess { futureValue in
                promise.resolve(with: futureValue)
            }
            
            future.onError { futureError in
                promise.reject(with: futureError)
            }
        }
        
        onError { error in
            promise.reject(with: error)
        }
        
        return promise
    }

    func map<NewValue>(_ closure: @escaping (Value) -> NewValue) -> Future<NewValue, Failure> {
        let promise = Promise<NewValue, Failure>()
        
        onSuccess { value in
            let nextValue = closure(value)
            promise.resolve(with: nextValue)
        }
        
        onError { error in
            promise.reject(with: error)
        }
        
        return promise
    }

    func mapFailure<NewFailure>(_ closure: @escaping (Failure) -> NewFailure) -> Future<Value, NewFailure> {
        let promise = Promise<Value, NewFailure>()
        
        onSuccess { value in
            promise.resolve(with: value)
        }
        
        onError { error in
            let nextError = closure(error)
            promise.reject(with: nextError)
        }
        
        return promise
    }
}


// This class takes the responsibility of setting value for Future
public class Promise<Value, Failure> : Future<Value, Failure> where Failure : Error {
    public init(value: Value? = nil) {
        super.init()
        if let value = value {
            result = Result.success(value)
        } else {
            result = nil
        }
    }
    
    public init(error: Failure) {
        super.init()
        result = Result.failure(error)
    }
    
    public func resolve(with value: Value) {
        result = .success(value)
    }
    
    public func reject(with error: Failure) {
        result = .failure(error)
    }
}

