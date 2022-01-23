//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

class IterablePendingImpl<Value, Failure> : PendingImpl<Value, Failure> where Failure: Error {
    override func onCompletion(receiveValue: @escaping ((Value) -> Void), receiveError: ( (Failure) -> Void)? = nil) {
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
    
    @discardableResult
    override func onSuccess(block: @escaping ((Value) -> Void)) -> Self {
        successCallbacks.append(block)
        
        // if a successful result already exists (from constructor), report it
        if case let Result.success(value)? = result {
            successCallbacks.forEach { $0(value) }
        }
        
        return self
    }
    
    @discardableResult
    override func onError(block: @escaping ((Failure) -> Void)) -> Self {
        errorCallbacks.append(block)
        
        // if a failed result already exists (from constructor), report it
        if case let Result.failure(error)? = result {
            errorCallbacks.forEach { $0(error) }
        }
        
        return self
    }
    
    override func flatMap<NewValue>(_ closure: @escaping (Value) -> PendingImpl<NewValue, Failure>) -> PendingImpl<NewValue, Failure> {
        let fulfill = IterablePendingImpl<NewValue, Failure>()
        
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
    
    override func map<NewValue>(_ closure: @escaping (Value) -> NewValue) -> PendingImpl<NewValue, Failure> {
        let fulfill = IterablePendingImpl<NewValue, Failure>()
        
        onSuccess { value in
            let nextValue = closure(value)
            fulfill.resolve(with: nextValue)
        }
        
        onError { error in
            fulfill.reject(with: error)
        }
        
        return fulfill
    }
    
    override func mapFailure<NewFailure>(_ closure: @escaping (Failure) -> NewFailure) -> PendingImpl<Value, NewFailure> {
        let fulfill = IterablePendingImpl<Value, NewFailure>()
        
        onSuccess { value in
            fulfill.resolve(with: value)
        }
        
        onError { error in
            let nextError = closure(error)
            fulfill.reject(with: nextError)
        }
        
        return fulfill
    }

    override func replaceError(with defaultForError: Value) -> PendingImpl<Value, Never> {
        let fulfill = IterablePendingImpl<Value, Never>()
        
        onSuccess { value in
            fulfill.resolve(with: value)
        }
        
        onError { _ in
            fulfill.resolve(with: defaultForError)
        }
        
        return fulfill
    }
    
    override func send(value: Value) {
        result = .success(value)
    }
    
    override func resolve(with value: Value) {
        result = .success(value)
    }
    
    override func reject(with error: Failure) {
        result = .failure(error)
    }

    override func isResolved() -> Bool {
        result != nil
    }
    
    override func wait() {
        ITBDebug()
        guard !isResolved() else {
            ITBDebug("isResolved")
            return
        }
        
        ITBDebug("waiting....")
        Thread.sleep(forTimeInterval: 0.1)
        wait()
    }

    override init() {
        result = nil
    }

    init(value: Value) {
        result = Result.success(value)
    }
    
    init(error: Failure) {
        ITBDebug()
        result = Result.failure(error)
    }

    deinit {
        ITBDebug()
    }
    
    private var successCallbacks = [(Value) -> Void]()
    private var errorCallbacks = [(Failure) -> Void]()
    
    private var result: Result<Value, Failure>? {
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

