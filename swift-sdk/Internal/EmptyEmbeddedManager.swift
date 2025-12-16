//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

class EmptyEmbeddedManager: IterableInternalEmbeddedManagerProtocol {
    
    // MARK: - Constants
    
    private static let syncIdentifier = "embeddedMessagesSync"
    
    /// Creates a SendRequestError for when embedded messaging is not enabled
    /// This ensures consistent error handling across all embedded manager implementations,
    /// making it easier for consumers to handle errors uniformly regardless of which
    /// manager implementation is in use (e.g., for testing, disabled state, or production)
    private static func createNotEnabledError() -> SendRequestError {
        SendRequestError(reason: "Embedded messaging is not enabled",
                         data: nil,
                         httpStatusCode: nil,
                         iterableCode: "EmbeddedMessagingNotEnabled",
                         originalError: nil)
    }
    
    // MARK: - Default Handlers (following RequestProcessorUtil pattern)
    
    private static func defaultOnFailure(_ identifier: String) -> OnFailureHandler {
        { reason, data in
            var toLog = "\(identifier) failed:"
            if let reason = reason {
                toLog += ", \(reason)"
            }
            if let data = data {
                toLog += ", got response \(String(data: data, encoding: .utf8) ?? "nil")"
            }
            ITBError(toLog)
        }
    }
    
    private static func defaultOnDetailedFailure(_ identifier: String) -> EmbeddedSyncErrorHandler {
        { error in
            var toLog = "\(identifier) failed:"
            if let reason = error.reason {
                toLog += ", \(reason)"
            }
            if let httpStatusCode = error.httpStatusCode {
                toLog += ", httpStatus: \(httpStatusCode)"
            }
            if let iterableCode = error.iterableCode {
                toLog += ", iterableCode: \(iterableCode)"
            }
            if let data = error.data {
                toLog += ", got response \(String(data: data, encoding: .utf8) ?? "nil")"
            }
            ITBError(toLog)
        }
    }
    
    // MARK: - Protocol Implementation
    
    func addUpdateListener(_ listener: IterableEmbeddedUpdateDelegate) {
        
    }
    
    func removeUpdateListener(_ listener: IterableEmbeddedUpdateDelegate) {
        
    }
    
    func getMessages() -> [IterableEmbeddedMessage] {
        return []
    }
    
    func getMessages(for placementId: Int) -> [IterableEmbeddedMessage] {
        return []
    }

    func syncMessages(completion: @escaping () -> Void) {
        
    }
    
    func syncMessages(onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        let error = Self.createNotEnabledError()
        // Dispatch async for consistent callback timing
        DispatchQueue.main.async {
            if let onFailure = onFailure {
                onFailure(error.reason, error.data)
            } else {
                Self.defaultOnFailure(Self.syncIdentifier)(error.reason, error.data)
            }
        }
    }
    
    func syncMessagesWithCallback(onSuccess: OnSuccessHandler?, onFailure: EmbeddedSyncErrorHandler?) {
        let error = Self.createNotEnabledError()
        // Dispatch async for consistent callback timing
        DispatchQueue.main.async {
            if let onFailure = onFailure {
                onFailure(error)
            } else {
                Self.defaultOnDetailedFailure(Self.syncIdentifier)(error)
            }
        }
    }
    
    public func handleEmbeddedClick(message: IterableEmbeddedMessage, buttonIdentifier: String?, clickedUrl: String) {

    }
    
    func reset() {
        
    }
    
    func track(click message: IterableEmbeddedMessage, buttonIdentifier: String?, clickedUrl: String) {
            
    }
    
    func track(impression message: IterableEmbeddedMessage) {
        
    }
    
    func track(embeddedSession: IterableEmbeddedSession) {
        
    }
}
