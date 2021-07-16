//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation

@objc public protocol IterableAuthManagerProtocol {
    func getAuthToken() -> String?
    func resetFailedAuthCount()
    func requestNewAuthToken(hasFailedPriorAuth: Bool, onSuccess: ((String?) -> Void)?)
    func logoutUser()
}
