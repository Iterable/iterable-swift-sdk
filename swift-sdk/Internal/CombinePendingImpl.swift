//
//  Copyright © 2022 Iterable. All rights reserved.
//

#if canImport(Combine) && !arch(arm)

import Foundation
import Combine

@available(iOS 13.0, *)
class CombinePendingImpl<Value, Failure> : PendingImpl<Value, Failure> where Failure: Error {
    override func onCompletion(receiveValue: @escaping ((Value) -> Void), receiveError: ((Failure) -> Void)? = nil) {
        ITBDebug()
        publisher.subscribe(Subscribers.Sink(receiveCompletion: { (completion) in
            if case .failure(let error) = completion {
                receiveError?(error)
            }
        }, receiveValue: { (value) in
            receiveValue(value)
        }))
    }
    
    override func onSuccess(block: @escaping ((Value) -> Void)) -> Self {
        ITBDebug()
        onCompletion { value in
            block(value)
        }
        return self
    }
    
    override func onError(block: @escaping ((Failure) -> Void)) -> Self {
        ITBDebug()
        onCompletion { _ in
        } receiveError: { error in
            block(error)
        }
        return self
    }
    
    override func flatMap<NewValue>(_ closure: @escaping (Value) -> PendingImpl<NewValue, Failure>) -> PendingImpl<NewValue, Failure> {
        ITBDebug()
        let flatMapped = publisher.flatMap { value -> AnyPublisher<NewValue,Failure> in
            (closure(value) as! CombinePendingImpl<NewValue, Failure>).publisher
        }.eraseToAnyPublisher()
        
        return copy(publisher: flatMapped)
    }
    
    override func map<NewValue>(_ closure: @escaping (Value) -> NewValue) -> PendingImpl<NewValue, Failure> {
        ITBDebug()
        return copy(publisher: publisher.map (closure).eraseToAnyPublisher())
    }
    
    override func mapFailure<NewFailure>(_ closure: @escaping (Failure) -> NewFailure) -> PendingImpl<Value, NewFailure> where NewFailure : Error {
        ITBDebug()
        return copy(publisher: publisher.mapError(closure).eraseToAnyPublisher())
    }
    
    override func replaceError(with defaultForError: Value) -> PendingImpl<Value, Never> {
        ITBDebug()
        return copy(publisher: publisher.replaceError(with: defaultForError).eraseToAnyPublisher())
    }
    
    override func resolve(with value: Value) {
        ITBDebug()
        passthroughSubject?.send(value)
        passthroughSubject?.send(completion: .finished)
        resolved = true
    }
    
    override func reject(with error: Failure) {
        ITBDebug()
        passthroughSubject?.send(completion: .failure(error))
        resolved = true
    }

    override func isResolved() -> Bool {
        ITBDebug()
        return resolved
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
        ITBDebug()
        let passthroughSubject = PassthroughSubject<Value, Failure>()
        self.passthroughSubject = passthroughSubject
        publisher = passthroughSubject.eraseToAnyPublisher()
        
        super.init()
    }
    
    init(value: Value) {
        ITBDebug()
        resolved = true
        self.publisher = Just(value)
            .setFailureType(to: Failure.self)
            .eraseToAnyPublisher()
    }
    
    init(error: Failure) {
        ITBDebug()
        resolved = true
        self.publisher = Fail(error: error)
            .eraseToAnyPublisher()
    }
    
    private func copy<NewValue, NewFailure>(publisher: AnyPublisher<NewValue, NewFailure>) -> CombinePendingImpl<NewValue, NewFailure> {
        CombinePendingImpl<NewValue, NewFailure>(publisher: publisher,
                                                 resolved: resolved)
    }
    
    private init(publisher: AnyPublisher<Value, Failure>,
                 resolved: Bool) {
        ITBDebug()
        self.publisher = publisher
        self.resolved = resolved
    }
    
    deinit {
        ITBDebug()
    }

    private var passthroughSubject: PassthroughSubject<Value, Failure>?
    private var publisher: AnyPublisher<Value, Failure>
    private var resolved = false
}

#endif
