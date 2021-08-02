//
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation
import UIKit

enum RowDiff {
    case insert(IndexPath)
    case delete(IndexPath)
    case update(IndexPath)
    case sectionInsert(IndexSet)
    case sectionDelete(IndexSet)
    case sectionUpdate(IndexSet)
}

@available(iOSApplicationExtension, unavailable)
class InboxViewControllerViewModel: InboxViewControllerViewModelProtocol {
    init(internalAPIProvider: @escaping @autoclosure () -> InternalIterableAPI? = IterableAPI.internalImplementation) {
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
    
    // MARK: - InboxViewControllerViewModelProtocol
    
    weak var view: InboxViewControllerViewModelView?
    
    var numSections: Int {
        sectionedMessages.sections.count
    }
    
    var unreadCount: Int {
        allMessagesInSections().filter { $0.read == false }.count
    }
    
    func refresh() -> Future<Bool, Error> {
        internalInAppManager?.scheduleSync() ?? Promise(error: IterableError.general(description: "Did not find inAppManager"))
    }
    
    func createInboxMessageViewController(for message: InboxMessageViewModel, withInboxMode inboxMode: IterableInboxViewController.InboxMode) -> UIViewController? {
        internalInAppManager?.createInboxMessageViewController(for: message.iterableMessage, withInboxMode: inboxMode, inboxSessionId: sessionManager.sessionStartInfo?.id)
    }
    
    func set(comparator: ((IterableInAppMessage, IterableInAppMessage) -> Bool)?, filter: ((IterableInAppMessage) -> Bool)?, sectionMapper: ((IterableInAppMessage) -> Int)?) {
        self.comparator = comparator
        self.filter = filter
        self.sectionMapper = sectionMapper
        sectionedMessages = sortAndFilter(messages: allMessagesInSections())
    }
    
    func isEmpty() -> Bool {
        return sectionedMessages.sectionsAndValues.reduce(0) { count, sectionAndValue in
            count + sectionAndValue.1.count
        } == 0
    }
    
    func numRows(in section: Int) -> Int {
        sectionedMessages[section].1.count
    }
    
    func set(read: Bool, forMessage message: InboxMessageViewModel) {
        internalInAppManager?.set(read: read, forMessage: message.iterableMessage)
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
    
    func beganUpdates() {
        sectionedMessages = newSectionedMessages
    }
    
    func endedUpdates() {}
    
    // MARK: - Private/Internal
    
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
        
        let dwifftDiffs = Dwifft.diff(lhs: sectionedMessages, rhs: newSectionedMessages)
        if dwifftDiffs.count > 0 {
            let rowDiffs = Self.dwifftDiffsToRowDiffs(dwifftDiffs: dwifftDiffs)
            view?.onViewModelChanged(diffs: rowDiffs)
            updateVisibleRows()
        }
    }
    
    private static func dwifftDiffsToRowDiffs(dwifftDiffs: [SectionedDiffStep<Int, InboxMessageViewModel>]) -> [RowDiff] {
        var result = [RowDiff]()
        var rowDeletes = [IndexPath: Int]()
        var sectionDeletes = [Int: Int]()
        
        for (pos, dwiffDiff) in dwifftDiffs.enumerated() {
            switch dwiffDiff {
            case let .delete(section, row, _):
                let indexPath = IndexPath(row: row, section: section)
                result.append(.delete(indexPath))
                rowDeletes[indexPath] = pos
            case let .insert(section, row, _):
                let indexPath = IndexPath(row: row, section: section)
                if let pos = rowDeletes[indexPath] {
                    result.remove(at: pos)
                    rowDeletes.removeValue(forKey: indexPath)
                    result.append(.update(indexPath))
                } else {
                    result.append(.insert(indexPath))
                }
            case let .sectionDelete(section, _):
                result.append(.sectionDelete(IndexSet(integer: section)))
                sectionDeletes[section] = pos
            case let .sectionInsert(section, _):
                if let pos = sectionDeletes[section] {
                    result.remove(at: pos)
                    sectionDeletes.removeValue(forKey: section)
                    result.append(.sectionUpdate(IndexSet(integer: section)))
                } else {
                    result.append(.sectionInsert(IndexSet(integer: section)))
                }
            }
        }
        
        return result
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
        internalAPI?.inAppManager.getInboxMessages().map { InboxMessageViewModel(message: $0) } ?? []
    }
    
    private func sortAndFilter(messages: [InboxMessageViewModel]) -> SectionedValues<Int, InboxMessageViewModel> {
        SectionedValues(values: filteredMessages(messages: messages),
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
    
    private var internalAPI: InternalIterableAPI? {
        internalAPIProvider()
    }
    
    var comparator: ((IterableInAppMessage, IterableInAppMessage) -> Bool)?
    var filter: ((IterableInAppMessage) -> Bool)?
    var sectionMapper: ((IterableInAppMessage) -> Int)?
    
    private var sectionedMessages = SectionedValues<Int, InboxMessageViewModel>()
    private var newSectionedMessages = SectionedValues<Int, InboxMessageViewModel>()
    private var sessionManager = InboxSessionManager()
    private var internalAPIProvider: () -> InternalIterableAPI?
    
    private var internalInAppManager: IterableInternalInAppManagerProtocol? {
        internalAPI?.inAppManager
    }
}

extension SectionedValues {
    var values: [Value] {
        sectionsAndValues.flatMap { $0.1 }
    }
}
