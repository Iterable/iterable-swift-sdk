//
//  Created by Tapash Majumder on 6/12/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation
import UIKit

protocol InboxViewControllerViewModelDelegate: AnyObject {
    // All these methods should be called on the main thread
    func onViewModelChanged(diff: [SectionedDiffStep<Int, InboxMessageViewModel>])
    func onImageLoaded(forRow row: Int)
    var currentlyVisibleRowIndices: [Int] { get }
}

protocol InboxViewControllerViewModelProtocol {
    var delegate: InboxViewControllerViewModelDelegate? { get set }
    var comparator: ((IterableInAppMessage, IterableInAppMessage) -> Bool)? { get set }
    var numMessages: Int { get }
    var unreadCount: Int { get }
    func message(atIndexPath indexPath: IndexPath) -> InboxMessageViewModel
    func remove(atRow row: Int)
    func set(read: Bool, forMessage message: InboxMessageViewModel)
    func createInboxMessageViewController(for message: InboxMessageViewModel, withInboxMode inboxMode: IterableInboxViewController.InboxMode) -> UIViewController?
    func refresh() -> Future<Bool, Error> // Talks to the server and refreshes
    // this works hand in hand with listener.onViewModelChanged.
    // Internal model can't be changed until the view begins update (tableView.beginUpdates()).
    func beganUpdates()
    func endedUpdates()
    func viewWillAppear()
    func viewWillDisappear()
    func visibleRowsChanged()
}

class InboxViewControllerViewModel: InboxViewControllerViewModelProtocol {
    weak var delegate: InboxViewControllerViewModelDelegate?
    
    var comparator: ((IterableInAppMessage, IterableInAppMessage) -> Bool)? {
        didSet {
            sectionedMessages = sortAndFilter(messages: allMessages())
        }
    }
    
    var filter: ((IterableInAppMessage) -> Bool)? {
        didSet {
            sectionedMessages = sortAndFilter(messages: allMessages())
        }
    }
    
    init() {
        ITBInfo()
        
        if let _ = IterableAPI.internalImplementation {
            sectionedMessages = sortAndFilter(messages: getMessages())
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(onInboxChanged(notification:)), name: .iterableInboxChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAppWillEnterForeground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAppDidEnterBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        ITBInfo()
        NotificationCenter.default.removeObserver(self)
    }
    
    var numMessages: Int {
        return allMessages().count
    }
    
    var unreadCount: Int {
        return allMessages().filter { $0.read == false }.count
    }
    
    func message(atIndexPath indexPath: IndexPath) -> InboxMessageViewModel {
        let message = sectionedMessages[indexPath.section].1[indexPath.row]
        loadImageIfNecessary(message)
        return message
    }
    
    func remove(atRow row: Int) {
        IterableAPI.inAppManager.remove(message: allMessages()[row].iterableMessage,
                                        location: .inbox,
                                        source: .inboxSwipe,
                                        inboxSessionId: sessionManager.sessionStartInfo?.id)
    }
    
    func set(read _: Bool, forMessage message: InboxMessageViewModel) {
        IterableAPI.inAppManager.set(read: true, forMessage: message.iterableMessage)
    }
    
    func refresh() -> Future<Bool, Error> {
        guard let inAppManager = IterableAPI.inAppManager as? InAppManager else {
            return Promise(error: IterableError.general(description: "Did not find inAppManager"))
        }
        
        return inAppManager.scheduleSync()
    }
    
    func createInboxMessageViewController(for message: InboxMessageViewModel, withInboxMode inboxMode: IterableInboxViewController.InboxMode) -> UIViewController? {
        guard let inAppManager = IterableAPI.inAppManager as? IterableInAppManagerProtocolInternal else {
            ITBError("Unexpected inAppManager type")
            return nil
        }
        
        return inAppManager.createInboxMessageViewController(for: message.iterableMessage, withInboxMode: inboxMode, inboxSessionId: sessionManager.sessionStartInfo?.id)
    }
    
    func beganUpdates() {
        sectionedMessages = newSectionedMessages
    }
    
    func endedUpdates() {}
    
    func viewWillAppear() {
        ITBInfo()
        startSession()
    }
    
    func viewWillDisappear() {
        ITBInfo()
        endSession()
    }
    
    func visibleRowsChanged() {
        ITBDebug()
        updateVisibleRows()
    }
    
    private func updateVisibleRows() {
        ITBDebug()
        
        guard sessionManager.isTracking else {
            ITBInfo("Not tracking session")
            return
        }
        
        sessionManager.updateVisibleRows(visibleRows: getVisibleRows())
    }
    
    private func loadImageIfNecessary(_ message: InboxMessageViewModel) {
        guard let imageUrlString = message.imageUrl, let url = URL(string: imageUrlString) else {
            return
        }
        
        if message.imageData == nil {
            loadImage(forMessageId: message.iterableMessage.messageId, fromUrl: url)
        }
    }
    
    private func loadImage(forMessageId messageId: String, fromUrl url: URL) {
        if let networkSession = IterableAPI.internalImplementation?.networkSession {
            NetworkHelper.getData(fromUrl: url, usingSession: networkSession).onSuccess { [weak self] in
                self?.setImageData($0, forMessageId: messageId)
            }.onError {
                ITBError($0.localizedDescription)
            }
        }
    }
    
    private func setImageData(_ data: Data, forMessageId messageId: String) {
        guard let row = allMessages().firstIndex(where: { $0.iterableMessage.messageId == messageId }) else {
            return
        }
        let message = allMessages()[row]
        message.imageData = data
        
        delegate?.onImageLoaded(forRow: row)
    }
    
    private func getVisibleRows() -> [InboxImpressionTracker.RowInfo] {
        guard let delegate = delegate else {
            return []
        }
        
        return delegate.currentlyVisibleRowIndices.compactMap { index in
            guard index < allMessages().count else {
                return nil
            }
            let message = allMessages()[index].iterableMessage
            return InboxImpressionTracker.RowInfo(messageId: message.messageId, silentInbox: message.silentInbox)
        }
    }
    
    private func startSession() {
        ITBInfo()
        
        sessionManager.startSession(visibleRows: getVisibleRows())
    }
    
    private func endSession() {
        guard let sessionInfo = sessionManager.endSession() else {
            ITBError("Could not find session info")
            return
        }
        
        let inboxSession = IterableInboxSession(id: sessionInfo.startInfo.id,
                                                sessionStartTime: sessionInfo.startInfo.startTime,
                                                sessionEndTime: Date(),
                                                startTotalMessageCount: sessionInfo.startInfo.totalMessageCount,
                                                startUnreadMessageCount: sessionInfo.startInfo.unreadMessageCount,
                                                endTotalMessageCount: IterableAPI.inAppManager.getInboxMessages().count,
                                                endUnreadMessageCount: IterableAPI.inAppManager.getUnreadInboxMessagesCount(),
                                                impressions: sessionInfo.impressions.map { $0.toIterableInboxImpression() })
        
        IterableAPI.internalImplementation?.track(inboxSession: inboxSession)
    }
    
    @objc private func onInboxChanged(notification _: NSNotification) {
        ITBInfo()
        
        DispatchQueue.main.async { [weak self] in
            self?.updateView()
        }
    }
    
    private func updateView() {
        ITBInfo()
        newSectionedMessages = sortAndFilter(messages: getMessages())
        
        let diff = Dwifft.diff(lhs: sectionedMessages, rhs: newSectionedMessages)
        if diff.count > 0 {
            delegate?.onViewModelChanged(diff: diff)
            updateVisibleRows()
        }
    }
    
    @objc private func onAppWillEnterForeground(notification _: NSNotification) {
        ITBInfo()
        
        if sessionManager.startSessionWhenAppMovesToForeground {
            startSession()
            sessionManager.startSessionWhenAppMovesToForeground = false
        }
    }
    
    @objc private func onAppDidEnterBackground(notification _: NSNotification) {
        ITBInfo()
        
        if sessionManager.isTracking {
            // if a session is going on trigger session end
            endSession()
            sessionManager.startSessionWhenAppMovesToForeground = true
        }
    }
    
    private func getMessages() -> [InboxMessageViewModel] {
        IterableAPI.inAppManager.getInboxMessages().map { InboxMessageViewModel(message: $0) }
    }
    
    private func allMessages() -> [InboxMessageViewModel] {
        return sectionedMessages.values
    }
    
    private func sortAndFilter(messages: [InboxMessageViewModel]) -> SectionedValues<Int, InboxMessageViewModel> {
        return SectionedValues(values: filteredMessages(messages: messages),
                               valueToSection: { _ in 0 },
                               sortSections: { $0 < $1 },
                               sortValues: createComparator())
    }
    
    private func filteredMessages(messages: [InboxMessageViewModel]) -> [InboxMessageViewModel] {
        guard let filter = self.filter else {
            return messages
        }
        
        return messages.filter { filter($0.iterableMessage) }
    }
    
    private func createComparator() -> (InboxMessageViewModel, InboxMessageViewModel) -> Bool {
        if let comparator = self.comparator {
            return { comparator($0.iterableMessage, $1.iterableMessage) }
        } else {
            return { IterableInboxViewController.DefaultComparator.ascending($0.iterableMessage, $1.iterableMessage) }
        }
    }
    
    private var sectionedMessages = SectionedValues<Int, InboxMessageViewModel>()
    private var newSectionedMessages = SectionedValues<Int, InboxMessageViewModel>()
    private var sessionManager = InboxSessionManager()
}

extension SectionedValues {
    var values: [Value] {
        return sectionsAndValues.flatMap { $0.1 }
    }
}
