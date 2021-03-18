//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation
import UIKit

protocol CardStreamViewControllerViewModelProtocol {
    func isEmpty() -> Bool
    func numRows() -> Int
    func getHtmlForMessage(index: Int) -> String
    func getSizeForMessage(index: Int) -> CGSize
}

class CardStreamViewControllerViewModel: CardStreamViewControllerViewModelProtocol {
    init(internalAPIProvider: @escaping @autoclosure () -> InternalIterableAPI? = IterableAPI.internalImplementation) {
        self.internalAPIProvider = internalAPIProvider
    }
    
    // MARK: - CardStreamViewControllerViewModelProtocol
    
    func isEmpty() -> Bool {
        inAppManager?.getInboxMessages().isEmpty ?? true
    }
    
    func numRows() -> Int {
        inAppManager?.getInboxMessages().count ?? 0
    }
    
    func getHtmlForMessage(index: Int) -> String {
        guard let content = inAppManager?.getInboxMessages()[index].content as? IterableHtmlInAppContent else {
            return ""
        }
        
        return content.html
    }
    
    func getSizeForMessage(index: Int) -> CGSize {
        guard let content = inAppManager?.getInboxMessages()[index].content as? IterableHtmlInAppContent else {
            return .zero
        }
        
        
    }
    
    // MARK: - Private/Internal
    
    private var internalAPIProvider: () -> InternalIterableAPI?
    
    private var internalAPI: InternalIterableAPI? {
        internalAPIProvider()
    }
    
    private var inAppManager: IterableInternalInAppManagerProtocol? {
        internalAPI?.inAppManager
    }
}
