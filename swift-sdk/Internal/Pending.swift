//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

enum IterableError: Error {
    case general(description: String)
}

extension IterableError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .general(description):
            return NSLocalizedString(description, comment: "error description")
        }
    }
}

// This has only two public methods
// either there is a success with result
// or there is a failure with error
// There is no way to set value a result in this class.
class Pending<Value, Failure> where Failure: Error {
    fileprivate var successCallbacks = [(Value) -> Void]()
    fileprivate var errorCallbacks = [(Failure) -> Void]()
    
    public func onCompletion(receiveValue: @escaping ((Value) -> Void), receiveError: ( (Failure) -> Void)? = nil) {
        successCallbacks.append(receiveValue)
        
        // if a successful result already exists (from constructor), report it
        if case let Result.success(value)? = result {
            successCallbacks.forEach { $0(value) }
        }
        
        if let receiveError = receiveError {
            errorCallbacks.append(receiveError)
            
            // if a failed result already exists (from constructor), report it
            if case let Result.failure(error)? = result {
                errorCallbacks.forEach { $0(error) }
            }
        }
    }
    
    @discardableResult public func onSuccess(block: @escaping ((Value) -> Void)) -> Pending<Value, Failure> {
        successCallbacks.append(block)
        
        // if a successful result already exists (from constructor), report it
        if case let Result.success(value)? = result {
            successCallbacks.forEach { $0(value) }
        }
        
        return self
    }
    
    @discardableResult public func onError(block: @escaping ((Failure) -> Void)) -> Pending<Value, Failure> {
        errorCallbacks.append(block)
        
        // if a failed result already exists (from constructor), report it
        if case let Result.failure(error)? = result {
            errorCallbacks.forEach { $0(error) }
        }
        
        return self
    }
    
    public func isResolved() -> Bool {
        result != nil
    }
    
    public func wait() {
        ITBDebug()
        guard !isResolved() else {
            ITBDebug("isResolved")
            return
        }
        
        ITBDebug("waiting....")
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

// need this class for testing failure
class FailPending<Value, Failure: Error>: Pending<Value, Failure> {
    init(error: Failure) {
        super.init()
        self.result = .failure(error)
    }
}

extension Pending {
    func flatMap<NewValue>(_ closure: @escaping (Value) -> Pending<NewValue, Failure>) -> Pending<NewValue, Failure> {
        let fulfill = Fulfill<NewValue, Failure>()
        
        onSuccess { value in
            let pending = closure(value)
            
            pending.onSuccess { futureValue in
                fulfill.resolve(with: futureValue)
            }
            
            pending.onError { futureError in
                fulfill.reject(with: futureError)
            }
        }
        
        onError { error in
            fulfill.reject(with: error)
        }
        
        return fulfill
    }
    
    func map<NewValue>(_ closure: @escaping (Value) -> NewValue) -> Pending<NewValue, Failure> {
        let fulfill = Fulfill<NewValue, Failure>()
        
        onSuccess { value in
            let nextValue = closure(value)
            fulfill.resolve(with: nextValue)
        }
        
        onError { error in
            fulfill.reject(with: error)
        }
        
        return fulfill
    }
    
    func mapFailure<NewFailure>(_ closure: @escaping (Failure) -> NewFailure) -> Pending<Value, NewFailure> {
        let fulfill = Fulfill<Value, NewFailure>()
        
        onSuccess { value in
            fulfill.resolve(with: value)
        }
        
        onError { error in
            let nextError = closure(error)
            fulfill.reject(with: nextError)
        }
        
        return fulfill
    }
    
    func replaceError(with defaultForError: Value) -> Pending<Value, Failure> {
        let fulfill = Fulfill<Value, Failure>()
        
        onSuccess { value in
            fulfill.resolve(with: value)
        }
        
        onError { _ in
            fulfill.resolve(with: defaultForError)
        }
        
        return fulfill
    }
}

extension Pending where Failure == Never {
    func flatMap<NewValue, NewFailure>(_ closure: @escaping (Value) -> Pending<NewValue, NewFailure>) -> Pending<NewValue, NewFailure> {
        let fulfill = Fulfill<NewValue, NewFailure>()
        
        onSuccess { value in
            let pending = closure(value)
            
            pending.onSuccess { futureValue in
                fulfill.resolve(with: futureValue)
            }
            
            pending.onError { futureError in
                fulfill.reject(with: futureError)
            }
        }
        
        return fulfill
    }
}

// This class takes the responsibility of setting value for Pending
class Fulfill<Value, Failure>: Pending<Value, Failure> where Failure: Error {
    public init(value: Value? = nil) {
        ITBDebug()
        super.init()
        if let value = value {
            result = Result.success(value)
        } else {
            result = nil
        }
    }
    
    public init(error: Failure) {
        ITBDebug()
        super.init()
        result = Result.failure(error)
    }

    deinit {
        ITBDebug()
    }
    
    public func resolve(with value: Value) {
        result = .success(value)
    }
    
    public func reject(with error: Failure) {
        result = .failure(error)
    }
}
