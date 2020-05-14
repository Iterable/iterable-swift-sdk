//
//  Created by Tapash Majumder on 10/26/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

enum IterableError: Error {
    case general(description: String)
}

extension IterableError: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case let .general(description):
            return description
        }
    }
}

// This has only two public methods
// either there is a success with result
// or there is a failure with error
// There is no way to set value a result in this class.
class Future<Value, Failure> where Failure: Error {
    fileprivate var successCallbacks = [(Value) -> Void]()
    fileprivate var errorCallbacks = [(Failure) -> Void]()
    
    @discardableResult public func onSuccess(block: @escaping ((Value) -> Void)) -> Future<Value, Failure> {
        successCallbacks.append(block)
        
        // if a successful result already exists (from constructor), report it
        if case let Result.success(value)? = result {
            successCallbacks.forEach { $0(value) }
        }
        
        return self
    }
    
    @discardableResult public func onError(block: @escaping ((Failure) -> Void)) -> Future<Value, Failure> {
        errorCallbacks.append(block)
        
        // if a failed result already exists (from constructor), report it
        if case let Result.failure(error)? = result {
            errorCallbacks.forEach { $0(error) }
        }
        
        return self
    }
    
    public func isResolved() -> Bool {
        return result != nil
    }
    
    public func wait() {
        ITBInfo()
        guard !isResolved() else {
            ITBInfo("isResolved")
            return
        }
        
        ITBInfo("waiting....")
        Thread.sleep(forTimeInterval: 0.1)
        wait()
    }
    
    fileprivate var result: Result<Value, Failure>? {
        // Observe whenever a result is assigned, and report it
        didSet { result.map(report) }
    }
    
    // Report success or error based on result
    private func report(result: Result<Value, Failure>) {
        switch result {
        case let .success(value):
            successCallbacks.forEach { $0(value) }
        case let .failure(error):
            errorCallbacks.forEach { $0(error) }
        }
    }
}

extension Future {
    func flatMap<NewValue>(_ closure: @escaping (Value) -> Future<NewValue, Failure>) -> Future<NewValue, Failure> {
        let promise = Promise<NewValue, Failure>()
        
        onSuccess { value in
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
class Promise<Value, Failure>: Future<Value, Failure> where Failure: Error {
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
