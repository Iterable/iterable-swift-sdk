//
//  Copyright © 2022 Iterable. All rights reserved.
//

#if canImport(Combine) && !arch(arm)

import Foundation
import Combine

@available(iOS 13.0, *)
class CombinePendingImpl<Value, Failure> : PendingImpl<Value, Failure> where Failure: Error {
    override func onCompletion(receiveValue: @escaping ((Value) -> Void), receiveError: ((Failure) -> Void)? = nil) {
        publisher.subscribe(Subscribers.Sink(receiveCompletion: { (completion) in
            if case .failure(let error) = completion {
                receiveError?(error)
            }
        }, receiveValue: { (value) in
            receiveValue(value)
        }))
    }
    
    override func onSuccess(block: @escaping ((Value) -> Void)) -> Self {
        onCompletion { value in
            block(value)
        }
        return self
    }
    
    override func onError(block: @escaping ((Failure) -> Void)) -> Self {
        onCompletion { _ in
        } receiveError: { error in
            block(error)
        }
        return self
    }
    
    override func flatMap<NewValue>(_ closure: @escaping (Value) -> PendingImpl<NewValue, Failure>) -> PendingImpl<NewValue, Failure> {
        let flatMapped = publisher.flatMap { value -> AnyPublisher<NewValue,Failure> in
            (closure(value) as! CombinePendingImpl<NewValue, Failure>).publisher
        }.eraseToAnyPublisher()
        
        return CombinePendingImpl<NewValue, Failure>(publisher: flatMapped)
    }
    
    override func map<NewValue>(_ closure: @escaping (Value) -> NewValue) -> PendingImpl<NewValue, Failure> {
        CombinePendingImpl<NewValue, Failure>(publisher: publisher.map (closure).eraseToAnyPublisher())
    }
    
    override func mapFailure<NewFailure>(_ closure: @escaping (Failure) -> NewFailure) -> PendingImpl<Value, NewFailure> where NewFailure : Error {
        CombinePendingImpl<Value, NewFailure>(publisher: publisher.mapError(closure).eraseToAnyPublisher())
    }
    
    override func replaceError(with defaultForError: Value) -> PendingImpl<Value, Never> {
        CombinePendingImpl<Value, Never>(publisher: publisher.replaceError(with: defaultForError).eraseToAnyPublisher())
    }
    
    override func isResolved() -> Bool {
        resolved
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
    
    init(publisher: AnyPublisher<Value, Failure>) {
        self.publisher = publisher
        super.init()
        self.publisher.subscribe(Subscribers.Sink(receiveCompletion: { [weak self] _ in
            self?.resolved = true
        }, receiveValue: { _ in
        }))
    }

    private let publisher: AnyPublisher<Value, Failure>
    private var resolved = false
}

#endif
