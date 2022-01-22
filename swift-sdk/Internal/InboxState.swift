import Foundation

protocol InboxStateProtocol {
    var isReady: Bool { get }
    
    var messages: [InboxMessageViewModel] { get }
    
    var totalMessagesCount: Int { get }
    
    var unreadMessagesCount: Int { get }
    
    func sync() -> Pending<Bool, Error>
    
    func track(inboxSession: IterableInboxSession)
    
    func loadImage(forMessageId messageId: String, fromUrl url: URL) -> Pending<Data, Error>
    
    func handleClick(clickedUrl url: URL?, forMessage message: IterableInAppMessage)
    
    func set(read: Bool, forMessage message: InboxMessageViewModel)
    
    func remove(message: InboxMessageViewModel, inboxSessionId: String?)
}

class InboxState: InboxStateProtocol {
    var isReady: Bool {
        internalAPI != nil
    }

    var messages: [InboxMessageViewModel] {
        inAppManager?.getInboxMessages().map { InboxMessageViewModel(message: $0) } ?? []
    }

    var totalMessagesCount: Int {
        inAppManager?.getInboxMessages().count ?? 0
    }
    
    var unreadMessagesCount: Int {
        inAppManager?.getUnreadInboxMessagesCount() ?? 0
    }
    
    func sync() -> Pending<Bool, Error> {
        inAppManager?.scheduleSync() ?? Pending(error: IterableError.general(description: "Did not find inAppManager"))
    }
    
    func track(inboxSession: IterableInboxSession) {
        internalAPI?.track(inboxSession: inboxSession)
    }
    
    func loadImage(forMessageId messageId: String, fromUrl url: URL) -> Pending<Data, Error> {
        guard let networkSession = networkSession else {
            return Pending(error: IterableError.general(description: "Network session not initialized"))
        }
        
        return NetworkHelper.getData(fromUrl: url, usingSession: networkSession)
    }

    
    func handleClick(clickedUrl url: URL?, forMessage message: IterableInAppMessage) {
        inAppManager?.handleClick(clickedUrl: url, forMessage: message, location: .inbox)
    }
    
    func set(read: Bool, forMessage message: InboxMessageViewModel) {
        inAppManager?.set(read: read, forMessage: message.iterableMessage)
    }

    func remove(message: InboxMessageViewModel, inboxSessionId: String?) {
        inAppManager?.remove(message: message.iterableMessage,
                             location: .inbox,
                             source: .inboxSwipe,
                             inboxSessionId: inboxSessionId)
    }

    init(internalAPIProvider: @escaping @autoclosure () -> InternalIterableAPI? = IterableAPI.internalImplementation) {
        self.internalAPIProvider = internalAPIProvider
    }

    private var internalAPIProvider: () -> InternalIterableAPI?

    /// We can't use a lazy variable here. Since in the beginning value will be null
    private var internalAPI: InternalIterableAPI? {
        internalAPIProvider()
    }

    private var inAppManager: IterableInternalInAppManagerProtocol? {
        internalAPI?.inAppManager
    }

    private var networkSession: NetworkSessionProtocol? {
        internalAPI?.dependencyContainer.networkSession
    }
}
