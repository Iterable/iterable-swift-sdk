//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

protocol AuthProvider: AnyObject {
    var auth: Auth { get }
}

struct Auth {
    let userId: String?
    let email: String?
    let authToken: String?
    let userIdUnknown: String?
    
    var emailOrUserId: EmailOrUserId {
        if let email = email {
            return .email(email)
        } else if let userId = userId {
            return .userId(userId)
        } else if let userIdUnknown = userIdUnknown {
            return .userIdUnknown(userIdUnknown)
        } else {
            return .none
        }
    }
    
    enum EmailOrUserId {
        case email(String)
        case userId(String)
        case userIdUnknown(String)
        case none
    }
}

extension Auth: Codable {}
