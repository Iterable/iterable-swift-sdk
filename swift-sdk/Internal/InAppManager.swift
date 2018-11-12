//
//
//  Created by Tapash Majumder on 11/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

class InAppManager : IterableInAppManagerProtocol {
    weak var internalApi: IterableAPIInternal? {
        didSet {
            self.synchronizer.internalApi = internalApi
        }
    }

    init(synchronizer: InAppSynchronizerProtocol,
         displayer: InAppDisplayerProtocol,
         inAppDelegate: IterableInAppDelegate,
         urlDelegate: IterableURLDelegate?,
         urlOpener: UrlOpenerProtocol) {
        self.synchronizer = synchronizer
        self.displayer = displayer
        self.inAppDelegate = inAppDelegate
        self.urlDelegate = urlDelegate
        self.urlOpener = urlOpener
        
        self.synchronizer.inAppSyncDelegate = self
    }
    
    func getMessages() -> [IterableInAppMessage] {
        ITBInfo()
        return Array(messages.values)
    }
    
    func show(content: IterableInAppContent, consume: Bool = true, callback: ITEActionBlock? = nil) {
        ITBInfo()
        guard let message = messages[content.messageId] else {
            ITBError("Message with id: \(content.messageId) is not present.")
            return
        }
        
        displayer.showInApp(content: content, callback: callback).onSuccess { (showed) in // showed boolean value gets set when inApp is showed in UI
            if showed && consume {
                self.internalApi?.inAppConsume(content.messageId)
                self.messages.removeValue(forKey: content.messageId)
            } else {
                message.skipped = true
                self.messages.updateValue(message, forKey: content.messageId)
            }
        }
    }

    private var synchronizer: InAppSynchronizerProtocol
    private var displayer: InAppDisplayerProtocol
    private var inAppDelegate: IterableInAppDelegate
    private var urlDelegate: IterableURLDelegate?
    private var urlOpener: UrlOpenerProtocol
    
    private var messages: [String: IterableInAppMessage] = [:]
}

extension InAppManager : InAppSynchronizerDelegate {
    func onInAppContentAvailable(contents: [IterableInAppContent]) {
        ITBInfo()
        
        merge(contents: contents)
        
        if contents.count == 1 {
            if inAppDelegate.onNew(content: contents[0]) == .show {
                self.show(content: contents[0], consume: true) { (urlString) in // this gets called when user clicks link in inApp
                    if let name = urlString {
                        self.handleUrl(urlString: name, fromSource: .inApp)
                    } else {
                        ITBError("No name for clicked button/link in inApp")
                    }
                }
            } else {
                ITBInfo("skipped inApp")
            }
        } else if contents.count > 1 {
            if let content = inAppDelegate.onNew(batch: contents) {
                self.show(content: content, consume: true) { (urlString) in // This is what gets called when user clicks link
                    if let name = urlString {
                        self.handleUrl(urlString: name, fromSource: .inApp)
                    } else {
                        ITBError("No name for clicked button/link in inApp")
                    }
                }
            } else {
                ITBInfo("skipped inApp batch")
            }
        }
    }

    private func handleUrl(urlString: String, fromSource source: IterableActionSource) {
        guard let action = IterableAction.actionOpenUrl(fromUrlString: urlString) else {
            ITBError("Could not create action from: \(urlString)")
            return
        }
        
        let context = IterableActionContext(action: action, source: source)
        DispatchQueue.main.async {
            IterableActionRunner.execute(action: action,
                                         context: context,
                                         urlHandler: IterableUtil.urlHandler(fromUrlDelegate: self.urlDelegate, inContext: context),
                                         urlOpener: self.urlOpener)
        }
    }
    
    private func merge(contents: [IterableInAppContent]) {
        contents.forEach { content in
            if !messages.contains(where: { $0.key == content.messageId}) {
                messages[content.messageId] = IterableInAppMessage(content: content)
            }
        }
    }
}

class EmptyInAppManager : IterableInAppManagerProtocol {
    func getMessages() -> [IterableInAppMessage] {
        return []
    }
    
    func show(content: IterableInAppContent, consume: Bool, callback: ITEActionBlock?) {
    }
    
}

