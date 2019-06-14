//
//
//  Created by Tapash Majumder on 6/12/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

protocol InboxViewControllerViewModelDelegate : class {
    // All these methods should be called on the main thread
    func onViewModelChanged(diff: [SectionedDiffStep<Int, InboxMessageViewModel>])
    func onImageLoaded(forRow row: Int)
}

protocol InboxViewControllerViewModelProtocol {
    var delegate: InboxViewControllerViewModelDelegate? { get set}
    var numMessages: Int { get }
    var unreadCount: Int { get }
    func message(atRow row: Int) -> InboxMessageViewModel
    func remove(atRow row: Int)
    func set(read: Bool, forMessage message: InboxMessageViewModel)
    func createInboxMessageViewController(forMessage message: InboxMessageViewModel) -> UIViewController?
    func refresh() -> Future<Bool, Error> // Talks to the server and refreshes
    // this works hand in hand with listener.onViewModelChanged.
    // Internal model can't be changed until the view begins update.
    func beganUpdates()
    func endedUpdates()
}

class InboxViewControllerViewModel : InboxViewControllerViewModelProtocol {
    weak var delegate: InboxViewControllerViewModelDelegate?
    
    init() {
        ITBInfo()
        if let _ = IterableAPI.internalImplementation {
            messages = IterableAPI.inAppManager.getInboxMessages().map { InboxMessageViewModel(message: $0) }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(onInboxChanged(notification:)), name: .iterableInboxChanged, object: nil)
    }
    
    deinit {
        ITBInfo()
        NotificationCenter.default.removeObserver(self)
    }
    
    var numMessages: Int {
        return messages.count
    }
    
    var unreadCount: Int {
        return messages.filter { $0.read == false }.count
    }
    
    func message(atRow row: Int) -> InboxMessageViewModel {
        let message = messages[row]
        loadImageIfNecessary(message)
        return message
    }
    
    func remove(atRow row: Int) {
        IterableAPI.inAppManager.remove(message: messages[row].iterableMessage)
    }
    
    func set(read: Bool, forMessage message: InboxMessageViewModel) {
        IterableAPI.inAppManager.set(read: true, forMessage: message.iterableMessage)
    }
    
    func refresh() -> Future<Bool, Error> {
        guard let inAppManager = IterableAPI.inAppManager as? InAppManager else {
            return Promise(error: IterableError.general(description: "Did not find inAppManager"))
        }
        
        return inAppManager.scheduleSync()
    }
    
    func createInboxMessageViewController(forMessage message: InboxMessageViewModel) -> UIViewController? {
        return IterableAPI.inAppManager.createInboxMessageViewController(for: message.iterableMessage)
    }
    
    func beganUpdates() {
        messages = newMessages
    }
    
    func endedUpdates() {
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
            NetworkHelper.getData(fromUrl: url, usingSession: networkSession).onSuccess {[weak self] in
                self?.setImageData($0, forMessageId: messageId)
                }.onError {
                    ITBError($0.localizedDescription)
            }
        }
    }
    
    private func setImageData(_ data: Data, forMessageId messageId: String) {
        guard let row = messages.firstIndex (where: { $0.iterableMessage.messageId == messageId }) else {
            return
        }
        let message = messages[row]
        message.imageData = data
        
        self.delegate?.onImageLoaded(forRow: row)
    }
    
    
    @objc private func onInboxChanged(notification: NSNotification) {
        ITBInfo()
        
        let oldSectionedValues = AbstractDiffCalculator<Int, InboxMessageViewModel>.buildSectionedValues(values: messages, sectionIndex: 0)
        newMessages = IterableAPI.inAppManager.getInboxMessages().map { InboxMessageViewModel(message: $0) }
        let newSectionedValues = AbstractDiffCalculator<Int, InboxMessageViewModel>.buildSectionedValues(values: newMessages, sectionIndex: 0)
        
        let diff = Dwifft.diff(lhs: oldSectionedValues, rhs: newSectionedValues)
        if (diff.count > 0) {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.onViewModelChanged(diff: diff)
            }
        }
    }
    
    private var messages = [InboxMessageViewModel]()
    private var newMessages = [InboxMessageViewModel]()
}

