//
//  Created by Jay Kim on 9/3/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

@objc public protocol IterableInternalAuthManagerProtocol {
    func requestNewAuthToken()
}

class AuthManager: IterableInternalAuthManagerProtocol {
    init(config: IterableConfig) {
        ITBInfo()
        
        self.config = config
    }
    
    deinit {
        ITBInfo()
    }
    
    // MARK: - IterableInternalAuthManagerProtocol
    
    func requestNewAuthToken() {
        // change this when a bridge to the SDK stored auth token is created so it can actually be set
        guard let newAuthToken = config.retrieveNewAuthTokenCallback?() else {
            return
        }
        
        print("new token: \(newAuthToken) - update to the new token here")
    }
    
    // MARK: - Private/Internal
    
    private let config: IterableConfig
}
