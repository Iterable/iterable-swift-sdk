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

/// Captures the single user identifier that was current when a request was created.
/// This avoids rebuilding a disable-device payload from mutable auth state later.
enum UserIdentitySnapshot: Equatable {
    case email(String)
    case userId(String)

    init?(auth: Auth?) {
        guard let auth else {
            return nil
        }

        switch auth.emailOrUserId {
        case let .email(email):
            self = .email(email)
        case let .userId(userId), let .userIdUnknownUser(userId):
            self = .userId(userId)
        case .none:
            return nil
        }
    }

    func apply(to dict: inout [AnyHashable: Any]) {
        switch self {
        case let .email(email):
            dict.setValue(for: JsonKey.email, value: email)
        case let .userId(userId):
            dict.setValue(for: JsonKey.userId, value: userId)
        }
    }
}
