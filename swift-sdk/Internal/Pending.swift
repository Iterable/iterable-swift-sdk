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
//
// Thread-safety: all mutations of `result`, `successCallbacks`, and `errorCallbacks`
// are serialized through `stateQueue`. Callbacks are snapshotted under `.sync` and
// invoked outside the critical section, so user code that re-enters `onSuccess` /
// `onError` on the same instance cannot deadlock the queue.
public class Pending<Value, Failure> where Failure: Error {
    fileprivate var successCallbacks = [(Value) -> Void]()
    fileprivate var errorCallbacks = [(Failure) -> Void]()
    fileprivate var result: Result<Value, Failure>?

    private let stateQueue = DispatchQueue(label: "com.iterable.pending.state")

    public func onCompletion(receiveValue: @escaping ((Value) -> Void), receiveError: ( (Failure) -> Void)? = nil) {
        // Append both callbacks in one critical section so a concurrent failure
        // cannot land between the success and error registrations.
        let current: Result<Value, Failure>? = stateQueue.sync {
            successCallbacks.append(receiveValue)
            if let receiveError = receiveError {
                errorCallbacks.append(receiveError)
            }
            return result
        }

        // Late registration on an already-resolved Pending: replay the current
        // result for the newly registered callback only.
        guard let current = current else { return }
        switch current {
        case let .success(value):
            receiveValue(value)
        case let .failure(error):
            receiveError?(error)
        }
    }

    @discardableResult public func onSuccess(block: @escaping ((Value) -> Void)) -> Pending<Value, Failure> {
        let current: Result<Value, Failure>? = stateQueue.sync {
            successCallbacks.append(block)
            return result
        }

        if case let .success(value)? = current {
            block(value)
        }
        return self
    }

    @discardableResult public func onError(block: @escaping ((Failure) -> Void)) -> Pending<Value, Failure> {
        let current: Result<Value, Failure>? = stateQueue.sync {
            errorCallbacks.append(block)
            return result
        }

        if case let .failure(error)? = current {
            block(error)
        }
        return self
    }

    public func isResolved() -> Bool {
        stateQueue.sync { result != nil }
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

    /// Stores the result and fires every currently-registered callback.
    ///
    /// Repeated calls are allowed: in-tree callers reuse a single `Fulfill` as a
    /// broadcast event signal. Each call overwrites `result` and fires the matching
    /// branch against a snapshot of the callback list taken under the lock.
    /// Callbacks fire outside the critical section so re-entrant registrations on
    /// the same instance cannot deadlock.
    fileprivate func setResult(_ newResult: Result<Value, Failure>) {
        let snapshot: (successes: [(Value) -> Void], errors: [(Failure) -> Void]) = stateQueue.sync {
            result = newResult
            return (successCallbacks, errorCallbacks)
        }

        switch newResult {
        case let .success(value):
            snapshot.successes.forEach { $0(value) }
        case let .failure(error):
            snapshot.errors.forEach { $0(error) }
        }
    }
}

// need this class for testing failure
public class FailPending<Value, Failure: Error>: Pending<Value, Failure> {
    public init(error: Failure) {
        super.init()
        setResult(.failure(error))
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
public class Fulfill<Value, Failure>: Pending<Value, Failure> where Failure: Error {
    public init(value: Value? = nil) {
        ITBDebug()
        super.init()
        if let value = value {
            setResult(.success(value))
        }
    }

    public init(error: Failure) {
        ITBDebug()
        super.init()
        setResult(.failure(error))
    }

    deinit {
        ITBDebug()
    }

    public func resolve(with value: Value) {
        setResult(.success(value))
    }

    public func reject(with error: Failure) {
        setResult(.failure(error))
    }
}
