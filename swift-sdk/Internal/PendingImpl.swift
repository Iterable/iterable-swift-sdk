//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

class PendingImpl<Value, Failure> where Failure: Error {
    func onCompletion(receiveValue: @escaping ((Value) -> Void), receiveError: ( (Failure) -> Void)?) {}
    
    @discardableResult
    func onSuccess(block: @escaping ((Value) -> Void)) -> Self { preconditionFailure() }
    @discardableResult
    func onError(block: @escaping ((Failure) -> Void)) -> Self { preconditionFailure() }
    
    func flatMap<NewValue>(_ closure: @escaping (Value) -> PendingImpl<NewValue, Failure>) -> PendingImpl<NewValue, Failure> { preconditionFailure() }
    func map<NewValue>(_ closure: @escaping (Value) -> NewValue) -> PendingImpl<NewValue, Failure> { preconditionFailure() }
    func mapFailure<NewFailure>(_ closure: @escaping (Failure) -> NewFailure) -> PendingImpl<Value, NewFailure> { preconditionFailure() }
    func replaceError(with defaultForError: Value) -> PendingImpl<Value, Never> { preconditionFailure() }
    
    func resolve(with value: Value) { preconditionFailure() }
    func reject(with error: Failure) { preconditionFailure() }
    
    func isResolved() -> Bool { preconditionFailure() }
    func wait() {}
}
