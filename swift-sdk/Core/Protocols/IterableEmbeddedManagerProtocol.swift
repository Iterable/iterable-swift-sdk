//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

/// Callback handler for embedded message sync errors that provides full error details
/// - Parameter error: The `SendRequestError` containing reason, HTTP status code, Iterable error code, and response data
public typealias EmbeddedSyncErrorHandler = (_ error: SendRequestError) -> Void

public protocol IterableEmbeddedManagerProtocol {
    func getMessages() -> [IterableEmbeddedMessage]
    func getMessages(for placementId: Int) -> [IterableEmbeddedMessage]
    func addUpdateListener(_ listener: IterableEmbeddedUpdateDelegate)
    func removeUpdateListener(_ listener: IterableEmbeddedUpdateDelegate)
    
    func syncMessages(completion: @escaping () -> Void)
    func syncMessages(onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?)
    
    /// Syncs embedded messages with detailed error information via `SendRequestError`
    ///
    /// Use this method when you need access to full error details including HTTP status codes,
    /// Iterable error codes, and raw response data for debugging or advanced error handling.
    ///
    /// - Parameters:
    ///   - onSuccess: Called on successful sync with response data dictionary containing `placementCount` and `messageCount`
    ///   - onFailure: Called on failure with full `SendRequestError` containing `httpStatusCode`, `iterableCode`, `reason`, and `data`
    func syncMessagesWithCallback(onSuccess: OnSuccessHandler?, onFailure: EmbeddedSyncErrorHandler?)
    
    func handleEmbeddedClick(message: IterableEmbeddedMessage, buttonIdentifier: String?, clickedUrl: String)
    func reset()
}
