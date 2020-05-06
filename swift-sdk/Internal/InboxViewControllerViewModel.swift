//
//  Created by Tapash Majumder on 6/12/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation
import UIKit

protocol InboxViewControllerViewModelView: AnyObject {
    // All these methods should be called on the main thread
    func onViewModelChanged(diff: [SectionedDiffStep<Int, InboxMessageViewModel>])
    func onImageLoaded(for indexPath: IndexPath)
    var currentlyVisibleRowIndexPaths: [IndexPath] { get }
}

protocol InboxViewControllerViewModelProtocol {
    var view: InboxViewControllerViewModelView? { get set }
    func set(comparator: ((IterableInAppMessage, IterableInAppMessage) -> Bool)?,
             filter: ((IterableInAppMessage) -> Bool)?,
             sectionMapper: ((IterableInAppMessage) -> Int)?)
    var numSections: Int { get }
    func numRows(in section: Int) -> Int
    var unreadCount: Int { get }
    func message(atIndexPath indexPath: IndexPath) -> InboxMessageViewModel
    func remove(atIndexPath indexPath: IndexPath)
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
    weak var view: InboxViewControllerViewModelView?
    
    func set(comparator: ((IterableInAppMessage, IterableInAppMessage) -> Bool)?, filter: ((IterableInAppMessage) -> Bool)?, sectionMapper: ((IterableInAppMessage) -> Int)?) {
        self.comparator = comparator
        self.filter = filter
        self.sectionMapper = sectionMapper
        sectionedMessages = sortAndFilter(messages: allMessagesInSections())
    }
    
    init(internalAPIProvider: @escaping @autoclosure () -> IterableAPIInternal? = IterableAPI.internalImplementation) {
        ITBInfo()
        
        self.internalAPIProvider = internalAPIProvider
        
        if let _ = internalAPI {
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
    
    var numSections: Int {
        sectionedMessages.sections.count
    }
    
    func numRows(in section: Int) -> Int {
        sectionedMessages[section].1.count
    }
    
    var unreadCount: Int {
        return allMessagesInSections().filter { $0.read == false }.count
    }
    
    func message(atIndexPath indexPath: IndexPath) -> InboxMessageViewModel {
        let message = sectionedMessages[indexPath.section].1[indexPath.row]
        loadImageIfNecessary(message)
        return message
    }
    
    func remove(atIndexPath indexPath: IndexPath) {
        let message = sectionedMessages[indexPath.section].1[indexPath.row]
        internalInAppManager?.remove(message: message.iterableMessage,
                                     location: .inbox,
                                     source: .inboxSwipe,
                                     inboxSessionId: sessionManager.sessionStartInfo?.id)
    }
    
    func set(read: Bool, forMessage message: InboxMessageViewModel) {
        internalInAppManager?.set(read: read, forMessage: message.iterableMessage)
    }
    
    func refresh() -> Future<Bool, Error> {
        return internalInAppManager?.scheduleSync() ?? Promise(error: IterableError.general(description: "Did not find inAppManager"))
    }
    
    func createInboxMessageViewController(for message: InboxMessageViewModel, withInboxMode inboxMode: IterableInboxViewController.InboxMode) -> UIViewController? {
        return internalInAppManager?.createInboxMessageViewController(for: message.iterableMessage, withInboxMode: inboxMode, inboxSessionId: sessionManager.sessionStartInfo?.id)
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
        if let networkSession = internalAPI?.networkSession {
            NetworkHelper.getData(fromUrl: url, usingSession: networkSession).onSuccess { [weak self] in
                self?.setImageData($0, forMessageId: messageId)
            }.onError {
                ITBError($0.localizedDescription)
            }
        }
    }
    
    private func setImageData(_ data: Data, forMessageId messageId: String) {
        guard let indexPath = findIndexPath(for: messageId) else {
            return
        }
        
        let message = sectionedMessages[indexPath.section].1[indexPath.row]
        message.imageData = data
        view?.onImageLoaded(for: indexPath)
    }
    
    private func findIndexPath(for messageId: String) -> IndexPath? {
        var section = -1
        for sectionAndValue in sectionedMessages.sectionsAndValues {
            section += 1
            let (_, values) = sectionAndValue
            if let row = values.firstIndex(where: { $0.iterableMessage.messageId == messageId }) {
                return IndexPath(row: row, section: section)
            }
        }
        return nil
    }
    
    private func getVisibleRows() -> [InboxImpressionTracker.RowInfo] {
        guard let view = view else {
            return []
        }
        
        return view.currentlyVisibleRowIndexPaths.compactMap { indexPath in
            guard indexPath.section < sectionedMessages.sectionsAndValues.count else {
                return nil
            }
            let sectionMessages = sectionedMessages.sectionsAndValues[indexPath.section].1
            guard indexPath.row < sectionMessages.count else {
                return nil
            }
            
            let message = sectionMessages[indexPath.row].iterableMessage
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
                                                endTotalMessageCount: internalInAppManager?.getInboxMessages().count ?? 0,
                                                endUnreadMessageCount: internalInAppManager?.getUnreadInboxMessagesCount() ?? 0,
                                                impressions: sessionInfo.impressions.map { $0.toIterableInboxImpression() })
        
        internalAPI?.track(inboxSession: inboxSession)
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
            view?.onViewModelChanged(diff: diff)
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
        return internalAPI?.inAppManager.getMessages().map { InboxMessageViewModel(message: $0) } ?? []
    }
    
    private func sortAndFilter(messages: [InboxMessageViewModel]) -> SectionedValues<Int, InboxMessageViewModel> {
        return SectionedValues(values: filteredMessages(messages: messages),
                               valueToSection: createSectionMapper(),
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
            return { IterableInboxViewController.DefaultComparator.descending($0.iterableMessage, $1.iterableMessage) }
        }
    }
    
    private func createSectionMapper() -> (InboxMessageViewModel) -> Int {
        if let sectionMapper = self.sectionMapper {
            return { sectionMapper($0.iterableMessage) }
        } else {
            return { _ in 0 }
        }
    }
    
    private func allMessagesInSections() -> [InboxMessageViewModel] {
        sectionedMessages.values
    }
    
    private var internalAPI: IterableAPIInternal? {
        return internalAPIProvider()
    }
    
    var comparator: ((IterableInAppMessage, IterableInAppMessage) -> Bool)?
    var filter: ((IterableInAppMessage) -> Bool)?
    var sectionMapper: ((IterableInAppMessage) -> Int)?
    
    private var sectionedMessages = SectionedValues<Int, InboxMessageViewModel>()
    private var newSectionedMessages = SectionedValues<Int, InboxMessageViewModel>()
    private var sessionManager = InboxSessionManager()
    private var internalAPIProvider: () -> IterableAPIInternal?
    
    private var internalInAppManager: IterableInternalInAppManagerProtocol? {
        return internalAPI?.inAppManager
    }
}

extension SectionedValues {
    var values: [Value] {
        return sectionsAndValues.flatMap { $0.1 }
    }
}
