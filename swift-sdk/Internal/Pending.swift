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

class Pending<Value, Failure> where Failure: Error {
    func onCompletion(receiveValue: @escaping ((Value) -> Void), receiveError: ( (Failure) -> Void)? = nil) {
        implementation.onCompletion(receiveValue: receiveValue, receiveError: receiveError)
    }
    
    @discardableResult
    func onSuccess(block: @escaping ((Value) -> Void)) -> Self {
        implementation.onSuccess(block: block)
        return self
    }
    
    @discardableResult
    func onError(block: @escaping ((Failure) -> Void)) -> Self {
        implementation.onError(block: block)
        return self
    }
    
    func flatMap<NewValue>(_ closure: @escaping (Value) -> Pending<NewValue, Failure>) -> Pending<NewValue, Failure> {
        Pending<NewValue, Failure>(implementation: implementation.flatMap { closure($0).implementation })
    }
    
    func map<NewValue>(_ closure: @escaping (Value) -> NewValue) -> Pending<NewValue, Failure> {
        Pending<NewValue, Failure>(implementation: implementation.map { closure($0) })
    }
    
    func mapFailure<NewFailure>(_ closure: @escaping (Failure) -> NewFailure) -> Pending<Value, NewFailure> {
        Pending<Value, NewFailure>(implementation: implementation.mapFailure { closure($0) })
    }

    func replaceError(with defaultForError: Value) -> Pending<Value, Never> {
        Pending<Value, Never>(implementation: implementation.replaceError(with: defaultForError))
    }

    public func isResolved() -> Bool {
        implementation.isResolved()
    }
    
    public func wait() {
        implementation.wait()
    }
    
    public func resolve(with value: Value) {
        ITBDebug()
        (implementation as! IterablePendingImpl).resolve(with: value)
    }
    
    public func reject(with error: Failure) {
        ITBDebug()
        (implementation as! IterablePendingImpl).reject(with: error)
    }

    fileprivate let implementation: PendingImpl<Value, Failure>

    init(implementation: PendingImpl<Value, Failure>) {
        ITBDebug()
        self.implementation = implementation
    }
    
    init(value: Value? = nil) {
        ITBDebug()
        implementation = IterablePendingImpl<Value, Failure>(value: value)
    }

    init(error: Failure) {
        ITBDebug()
        implementation = IterablePendingImpl<Value, Failure>(error: error)
    }

    deinit {
        ITBDebug()
    }
}
