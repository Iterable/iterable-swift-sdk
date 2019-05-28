//
//  Operations+Extensions.swift
//  swift-sdk
//
//

import Foundation

class AsyncOperation: Operation {
    override var isAsynchronous: Bool {
        return true
    }
    
    // KVO compliant setting
    override var isFinished: Bool {
        get {
            return _finished
        }
        set {
            willChangeValue(forKey: "isFinished")
            _finished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }
    
    // KVO compliant setting
    override var isExecuting: Bool {
        get {
            return _executing
        }
        set {
            willChangeValue(forKey: "isExecuting")
            _executing = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    func execute() {
    }
    
    override func start() {
        isExecuting = true
        execute()
        isExecuting = false
        isFinished = true
    }

    private var _finished: Bool = false
    private var _executing: Bool = false
}
