//
//  Copyright © 2026 Iterable. All rights reserved.
//

import Foundation
import UIKit

/// Serializes SDK calls made while `IterableAPI.switchProject(apiKey:config:callback:)` is
/// tearing down one project and standing up the next.
///
/// While the gate is raised, calls are queued instead of running against a half-torn-down
/// SDK, then replayed in FIFO order against the new project. This mirrors the Android SDK's
/// `queueOrExecute` semantics.
final class ProjectSwitchGate {
    static let shared = ProjectSwitchGate()

    /// `true` between the start of a switch and the moment the new instance is live.
    var isSwitchInProgress: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isRaised
    }

    /// Raises the gate for a new switch.
    ///
    /// `callback` is registered against the switch either way, so a caller that arrives
    /// while a switch is running is notified by it rather than starting a second teardown.
    ///
    /// - Returns: `false` when a switch was already in progress.
    func beginSwitch(callback: ((Bool) -> Void)?) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if let callback = callback {
            callbacks.append(callback)
        }

        guard !isRaised else { return false }
        isRaised = true
        return true
    }

    /// Lowers the gate, replays everything queued during the switch in FIFO order against
    /// the new project, then delivers every registered callback on the main thread.
    func endSwitch(succeeded: Bool) {
        lock.lock()
        isRaised = false
        let queued = operations
        operations.removeAll()
        let toNotify = callbacks
        callbacks.removeAll()
        lock.unlock()

        for operation in queued {
            ITBInfo("switchProject: replaying queued call \(operation.description)")
            operation.run()
        }

        guard !toNotify.isEmpty else { return }
        DispatchQueue.main.async {
            toNotify.forEach { $0(succeeded) }
        }
    }

    /// Runs `operation` immediately, or queues it when a project switch is in progress.
    ///
    /// - Returns: `true` when the call was queued.
    @discardableResult
    func queueOrExecute(_ description: String, _ operation: @escaping () -> Void) -> Bool {
        lock.lock()
        guard isRaised else {
            lock.unlock()
            operation()
            return false
        }
        operations.append(QueuedOperation(description: description, run: operation))
        lock.unlock()

        ITBInfo("switchProject in progress, queued \(description)")
        return true
    }

    /// Drops the gate and everything queued behind it, without replaying or notifying.
    /// The gate is process-wide, so a test that raises it has to put it back.
    func resetForTesting() {
        lock.lock()
        isRaised = false
        operations.removeAll()
        callbacks.removeAll()
        lock.unlock()
    }

    private struct QueuedOperation {
        let description: String
        let run: () -> Void
    }

    private let lock = NSLock()
    private var isRaised = false
    private var operations = [QueuedOperation]()
    private var callbacks = [(Bool) -> Void]()
}

/// Bounded rendezvous between the outgoing project's `users/disableDevice` and the step of
/// `switchProject` that releases the outgoing instance. Mirrors Android's
/// `DISABLE_DISPATCH_TIMEOUT_MS` latch.
final class DeviceDisableHandoff {
    /// Kept equal to Android's `DISABLE_DISPATCH_TIMEOUT_MS`. The bound decides when a switch
    /// reports `false`, and that is a shared contract, so the two platforms have to give up
    /// after the same wait even though only Android has the background-executor shutdown grace
    /// the value was originally chosen against. Long enough for a busy Core Data store to
    /// persist the disable, short enough not to be felt.
    static let defaultTimeout: TimeInterval = 2

    /// Test-only. Set before `await` to drive the timeout path without spending the real bound.
    /// An instance property rather than a mutable static, so an override cannot leak out of the
    /// test that set it.
    var timeout: TimeInterval = DeviceDisableHandoff.defaultTimeout

    /// First signal wins: `IterableTaskScheduler.schedule` broadcasts a rejection and then a
    /// resolution on the same `Fulfill`, so a failed schedule reports twice.
    func signal(_ handedOff: Bool) {
        lock.lock()
        guard handoffResult == nil else {
            lock.unlock()
            return
        }
        handoffResult = handedOff
        let waiter = takeWaiterLocked()
        lock.unlock()
        waiter?(handedOff)
    }

    /// Runs `then` once the disable has reached the request layer, or with `false` once
    /// `timeout` has passed without it. Never blocks the calling thread.
    func await(then: @escaping (Bool) -> Void) {
        lock.lock()
        if let handoffResult = handoffResult {
            hasDelivered = true
            lock.unlock()
            then(handoffResult)
            return
        }
        waiter = then
        let bound = timeout
        lock.unlock()

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + bound) { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            let waiter = self.takeWaiterLocked()
            self.lock.unlock()
            guard let waiter = waiter else { return }
            ITBError("switchProject: the outgoing project's device disable did not reach the request layer within \(bound)s, switching anyway")
            waiter(false)
        }
    }

    private func takeWaiterLocked() -> ((Bool) -> Void)? {
        guard !hasDelivered, let waiter = waiter else { return nil }
        hasDelivered = true
        self.waiter = nil
        return waiter
    }

    private let lock = NSLock()
    private var handoffResult: Bool?
    private var waiter: ((Bool) -> Void)?
    private var hasDelivered = false
}

public extension IterableAPI {
    /// Moves a running app from one Iterable project to another, in place, without an app
    /// restart and without state from the previous project leaking into the new one.
    ///
    /// The method returns immediately; teardown and re-initialization run off the calling
    /// thread. In order, the SDK disables the push token on the outgoing project, resets the
    /// in-app and embedded managers, purges the persisted offline queue, clears the stored
    /// identity (email, user ID, unknown-user ID and auth token) along with the rest of the
    /// outgoing project's storage (activation criteria, unsent unknown-user events, sessions
    /// and updates, and stored attribution info), and then stands up a fresh instance against
    /// `apiKey` and `config`. The device ID and visitor consent are project-agnostic and are
    /// deliberately preserved.
    ///
    /// SDK calls made between this call and `callback` are queued and replayed in FIFO order
    /// against the new project, so they are never run against a half-torn-down SDK.
    ///
    /// Special cases:
    /// - Before the SDK has been initialized, this behaves as `initialize(apiKey:config:)`.
    /// - With the API key that is already active, this is a no-op and reports `true`.
    /// - While a switch is already running, the callback joins that switch instead of
    ///   starting a second teardown.
    /// - With an empty or whitespace-only API key, nothing is torn down, the SDK stays on the
    ///   project it is on, and the callback reports `false`. Objective-C callers get the same
    ///   treatment for `nil`, which Swift's non-optional `String` cannot express.
    ///
    /// - Parameters:
    ///    - apiKey: The Iterable Mobile API key of the project to switch to
    ///    - config: The `IterableConfig` to use for the new project
    ///    - callback: Invoked on the main thread once the SDK is running on the new project.
    ///                `true` means every teardown step completed cleanly. `false` means the
    ///                SDK **is** on the new project but at least one cleanup step was noisy,
    ///                or no device disable was confirmed for the outgoing project. `false`
    ///                never means the switch failed or was rolled back.
    ///
    /// The SDK reports `false` when push registration is off, when there is no device token
    /// to disable, when no user was identified on the outgoing project, or when the
    /// `disableDevice` request itself fails. For an app that does not use push, `false` is
    /// therefore expected in normal operation and is not an error: carry on and re-identify
    /// the user with `setEmail` or `setUserId` exactly as you would after `true`.
    ///
    /// - Note: Queued `disableDevice` tasks survive the purge and still reach the project
    ///         they were created for, because each persisted task carries its own API key and
    ///         endpoint.
    /// - Note: The switch waits, briefly and with a bound, for the outgoing project's
    ///         `disableDevice` to reach the request layer, because a request built with the
    ///         outgoing project's API key is dropped if that instance is released first. It
    ///         does **not** wait for the network response: a queued disable may not run for
    ///         hours. A disable that fails after the callback has been delivered is logged
    ///         rather than reported retroactively.
    /// - Note: Calling `setEmail` from inside `callback` still hits the existing auth
    ///         retry-budget behaviour: if the previous project exhausted the JWT retry
    ///         budget, the new user's token request can be suppressed until
    ///         `pauseAuthRetries(false)` is called.
    ///
    /// - SeeAlso: IterableConfig
    @available(iOSApplicationExtension, unavailable)
    @objc(switchProject:config:callback:)
    static func switchProject(apiKey: String,
                              config: IterableConfig,
                              callback: ((Bool) -> Void)? = nil) {
        switchProject(apiKey: apiKey,
                      config: config,
                      apiEndPointOverride: nil,
                      dependencyContainer: nil,
                      callback: callback)
    }
}

extension IterableAPI {
    @available(iOSApplicationExtension, unavailable)
    static func switchProject(apiKey: String,
                              config: IterableConfig,
                              apiEndPointOverride: String?,
                              dependencyContainer: DependencyContainerProtocol?,
                              callback: ((Bool) -> Void)?) {
        // Step 1: guard and validate.
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            ITBError("switchProject called with an empty API key. The SDK is left on the project it is already on.")
            deliverOnMainThread(callback, false)
            return
        }

        guard let outgoing = implementation else {
            ITBError("switchProject called before the SDK was initialized. Initializing with the supplied API key instead.")
            initialize2(apiKey: apiKey,
                        launchOptions: nil,
                        config: config,
                        apiEndPointOverride: apiEndPointOverride,
                        dependencyContainer: dependencyContainer,
                        callback: { started in deliverOnMainThread(callback, started) })
            return
        }

        guard outgoing.apiKey != apiKey else {
            ITBInfo("switchProject called with the API key already in use. Nothing to tear down.")
            deliverOnMainThread(callback, true)
            return
        }

        // Step 2: raise the gate so any SDK call made from here until step 8 is queued.
        guard ProjectSwitchGate.shared.beginSwitch(callback: callback) else {
            ITBInfo("switchProject is already in progress. The callback will fire when it completes.")
            return
        }

        switchQueue.async {
            // Held so the outgoing instance survives teardown even though `implementation`
            // is replaced below.
            var releasing: InternalIterableAPI? = outgoing

            // Steps 3 to 6: reuse the existing logout path, purge the offline queue, clear
            // identity. The managers themselves are rebuilt for free by the instance swap.
            releasing?.tearDownForProjectSwitch { teardownWasClean in
                // A new frame so nothing below runs inside a method of the instance we are
                // about to deallocate.
                switchQueue.async {
                    // Drop our reference first, so replacing `implementation` releases the
                    // last one and the outgoing `deinit` runs: observers removed, request
                    // handler stopped.
                    releasing = nil

                    // Step 7: re-initialize against the new project. A start that reports
                    // failure is reported as a noisy switch, matching Android, which reports
                    // an unclean teardown when its own re-initialization does not complete.
                    initialize2(apiKey: apiKey,
                                launchOptions: nil,
                                config: config,
                                apiEndPointOverride: apiEndPointOverride,
                                dependencyContainer: dependencyContainer,
                                callback: { started in
                                    if !started {
                                        ITBError("switchProject: the new project's SDK did not start cleanly")
                                    }
                                    // Step 8: lower the gate, drain queued calls FIFO against
                                    // the new project, then fire every registered callback on
                                    // the main thread.
                                    ProjectSwitchGate.shared.endSwitch(succeeded: teardownWasClean && started)
                                })
                }
            }
        }
    }

    private static func deliverOnMainThread(_ callback: ((Bool) -> Void)?, _ succeeded: Bool) {
        guard let callback = callback else { return }
        DispatchQueue.main.async { callback(succeeded) }
    }

    private static let switchQueue = DispatchQueue(label: "com.iterable.projectSwitch")
}
