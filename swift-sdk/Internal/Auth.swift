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
    let userIdUnknownUser: String?
    
    var emailOrUserId: EmailOrUserId {
        if let email = email {
            return .email(email)
        } else if let userId = userId {
            return .userId(userId)
        } else if let userIdUnknownUser = userIdUnknownUser {
            return .userIdUnknownUser(userIdUnknownUser)
        } else {
            return .none
        }
    }
    
    enum EmailOrUserId {
        case email(String)
        case userId(String)
        case userIdUnknownUser(String)
        case none
    }
}

extension Auth: Codable {}
