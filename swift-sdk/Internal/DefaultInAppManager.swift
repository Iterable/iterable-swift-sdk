//
//
//  Created by Tapash Majumder on 11/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

class DefaultInAppManager : IterableInAppManagerProtocol {
    func getMessages() -> [IterableInAppMessage] {
        ITBInfo()
        return []
    }
    
    func show(content: IterableInAppContent, consume: Bool) {
        ITBInfo()
    }
}
