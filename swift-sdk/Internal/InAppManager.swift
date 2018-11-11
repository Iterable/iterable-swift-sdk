//
//
//  Created by Tapash Majumder on 11/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

class InAppManager : IterableInAppManagerProtocol {
    weak var internalApi: IterableAPIInternal?

    init(synchronizer: InAppSynchronizerProtocol,
         inAppDelegate: IterableInAppDelegate,
         urlDelegate: IterableURLDelegate?,
         urlOpener: UrlOpenerProtocol) {
        self.synchronizer = synchronizer
        self.inAppDelegate = inAppDelegate
        self.urlDelegate = urlDelegate
        self.urlOpener = urlOpener
        
        self.synchronizer.inAppSyncDelegate = self
    }
    
    func getMessages() -> [IterableInAppMessage] {
        ITBInfo()
        return []
    }
    
    func show(content: IterableInAppContent, consume: Bool = true, callbackBlock: ITEActionBlock? = nil) {
        ITBInfo()
    }

    private var synchronizer: InAppSynchronizerProtocol
    private var inAppDelegate: IterableInAppDelegate
    private var urlDelegate: IterableURLDelegate?
    private var urlOpener: UrlOpenerProtocol
}

extension InAppManager : InAppSynchronizerDelegate {
    func onInAppContentAvailable(contents: [IterableInAppContent]) {
        ITBInfo()
        
        guard let internalApi = internalApi else {
            ITBError("IterableAPI is not initialized")
            return
        }

        if contents.count == 1 {
            if inAppDelegate.onNew(content: contents[0]) == .show {
                InAppHelper.showInApp(content: contents[0], internalApi: internalApi) { (urlString) in
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
                InAppHelper.showInApp(content: content, internalApi: internalApi) { (urlString) in
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
}

class EmptyInAppManager : IterableInAppManagerProtocol {
    func getMessages() -> [IterableInAppMessage] {
        return []
    }
    
    func show(content: IterableInAppContent, consume: Bool, callbackBlock: ITEActionBlock?) {
    }
    
}

