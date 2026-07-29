//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

protocol AuthProvider: AnyObject {
    var auth: Auth { get }
}

struct UserIdentityContext: Equatable {
    let identity: UserIdentitySnapshot?
    let generation: UInt64
}

final class IdentityCoordinator {
    func capture(identityProvider: () -> UserIdentitySnapshot?) -> UserIdentityContext {
        withCriticalSection {
            UserIdentityContext(identity: identityProvider(), generation: generation)
        }
    }

    func isCurrent(_ context: UserIdentityContext,
                   identityProvider: () -> UserIdentitySnapshot?) -> Bool {
        withCriticalSection {
            context.generation == generation &&
                context.identity == identityProvider() &&
                !hasPendingPublication
        }
    }

    @discardableResult
    func performIfCurrent(_ context: UserIdentityContext,
                          identityProvider: () -> UserIdentitySnapshot?,
                          _ block: () -> Void) -> Bool {
        withCriticalSection {
            guard context.generation == generation,
                  context.identity == identityProvider(),
                  !hasPendingPublication else {
                return false
            }
            block()
            return context.generation == generation &&
                context.identity == identityProvider() &&
                !hasPendingPublication
        }
    }

    func publish(_ block: () -> Void) {
        // Announce before waiting for the identity lock so stale in-flight checks fail while publication is queued.
        beginPublication()
        withCriticalSection {
            block()
            generation &+= 1
            endPublication()
        }
    }

    func beginPublication() {
        pendingPublicationLock.lock()
        pendingPublicationCount += 1
        pendingPublicationLock.unlock()
    }

    func endPublication() {
        pendingPublicationLock.lock()
        pendingPublicationCount -= 1
        pendingPublicationLock.unlock()
    }

    func withCriticalSection<T>(_ block: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return block()
    }

    private var hasPendingPublication: Bool {
        pendingPublicationLock.lock()
        defer { pendingPublicationLock.unlock() }
        return pendingPublicationCount > 0
    }

    // Lock order is manager queue, identity section, then JSON store queue. Identity
    // holders must not call customer code or synchronously wait on manager queues.
    private let lock = NSRecursiveLock()
    private let pendingPublicationLock = NSLock()
    private var generation: UInt64 = 0
    private var pendingPublicationCount = 0
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
