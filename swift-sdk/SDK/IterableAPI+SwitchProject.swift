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
    /// A request that arrives while a switch is running is handled by where it is headed:
    /// one targeting the project the in-flight switch is already heading to is notified by
    /// that switch rather than starting a second teardown, and one targeting a different
    /// project is queued and run once the in-flight switch has finished. Dropping the second
    /// one would leave the SDK on a project the app has already asked to leave, while its
    /// callback said the switch was done.
    ///
    /// - Returns: `false` when a switch was already in progress.
    func beginSwitch(_ request: PendingSwitchRequest) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard isRaised else {
            isRaised = true
            inFlightApiKey = request.apiKey
            callbacks.append(contentsOf: request.callbacks)
            return true
        }

        guard request.apiKey != inFlightApiKey else {
            callbacks.append(contentsOf: request.callbacks)
            return false
        }

        if let index = pending.firstIndex(where: { $0.apiKey == request.apiKey }) {
            pending[index].callbacks.append(contentsOf: request.callbacks)
        } else {
            pending.append(request)
        }
        return false
    }

    /// Replays everything queued during the switch in FIFO order against the new project,
    /// lowers the gate, then delivers every registered callback on the main thread.
    ///
    /// The gate stays raised until the queue is observed empty under the same lock
    /// `queueOrExecute` enqueues under. Lowering it before the replay would let a call made
    /// during the replay run ahead of the calls already waiting behind the gate, so a
    /// `setEmail` issued as the switch lands could be overwritten by the older one queued
    /// during it.
    ///
    /// When a switch was requested while this one ran, the gate is *not* lowered: it is
    /// handed straight to that request, which becomes the new in-flight one along with its
    /// callbacks. Lowering it in between would open a window in which a brand new
    /// `switchProject` could take the gate first and then be overtaken by the older queued
    /// request, leaving the SDK on a project the app did not ask for last.
    ///
    /// - Returns: The next switch requested while this one was running, if any. The caller
    ///            runs it, and inherits the raised gate with it, so the gate stays unaware
    ///            of how a switch is performed.
    @discardableResult
    func endSwitch(succeeded: Bool) -> PendingSwitchRequest? {
        var toNotify = [(Bool) -> Void]()
        var next: PendingSwitchRequest?

        while true {
            lock.lock()
            if !operations.isEmpty {
                let operation = operations.removeFirst()
                lock.unlock()
                ITBInfo("switchProject: replaying queued call \(operation.description)")
                operation.run()
                continue
            }
            toNotify = callbacks
            callbacks.removeAll()
            next = pending.isEmpty ? nil : pending.removeFirst()
            if let next = next {
                inFlightApiKey = next.apiKey
                callbacks = next.callbacks
            } else {
                isRaised = false
                inFlightApiKey = nil
            }
            lock.unlock()
            break
        }

        if !toNotify.isEmpty {
            DispatchQueue.main.async {
                toNotify.forEach { $0(succeeded) }
            }
        }
        return next
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
        inFlightApiKey = nil
        operations.removeAll()
        callbacks.removeAll()
        pending.removeAll()
        lock.unlock()
    }

    /// Everything needed to run a switch, so one requested during another can be replayed
    /// verbatim when the gate is handed over instead of being discarded. Its `callbacks` are
    /// moved into the gate at handover, so the runner does not carry them itself.
    struct PendingSwitchRequest {
        let apiKey: String
        let config: IterableConfig
        let apiEndPointOverride: String?
        let dependencyContainer: DependencyContainerProtocol?
        var callbacks: [(Bool) -> Void]
    }

    private struct QueuedOperation {
        let description: String
        let run: () -> Void
    }

    private let lock = NSLock()
    private var isRaised = false
    /// The project the in-flight switch is heading to, so a second request can tell whether it
    /// is asking for the same destination or a different one.
    private var inFlightApiKey: String?
    private var operations = [QueuedOperation]()
    private var callbacks = [(Bool) -> Void]()
    private var pending = [PendingSwitchRequest]()
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
    /// - Before the SDK has been initialized, this behaves as `initialize(apiKey:config:)` and
    ///   reports `.switchedCleanly` once it has started, matching Android. There is no previous
    ///   project, so there is no teardown step that could have been noisy.
    /// - With the API key that is already active, this is a no-op and reports
    ///   `.switchedCleanly`.
    /// - While a switch to the same project is already running, the callback joins that switch
    ///   instead of starting a second teardown.
    /// - While a switch to a *different* project is running, this request is queued and runs as
    ///   soon as that one finishes, so the SDK ends up on the project asked for last. The
    ///   callbacks are not merged: each one fires when the project it asked for is live.
    /// An unusable API key cannot reach here: `IterableProject` refuses to hold an empty or
    /// whitespace-only one, so the invalid state is not constructible.
    ///
    /// - Parameters:
    ///    - project: The project to switch to: its API key together with the config to run it
    ///               with. The two are paired in one object so one project's key cannot be
    ///               combined with another project's region or auth delegate.
    ///    - callback: Invoked on the main thread once the SDK is running on the new project.
    ///                `.switchedCleanly` means every teardown step completed cleanly.
    ///                `.switchedWithWarnings` means the SDK **is** on the new project but at
    ///                least one cleanup step was noisy, or no device disable was confirmed for
    ///                the outgoing project. Neither case means the switch failed or was rolled
    ///                back, so the response to both is the same.
    ///
    /// The SDK reports `.switchedWithWarnings` when push registration is off, when there is no
    /// device token to disable, when no user was identified on the outgoing project, or when the
    /// `disableDevice` request itself fails. For an app that does not use push it is therefore
    /// expected in normal operation and is not an error: carry on and re-identify the user with
    /// `setEmail` or `setUserId` exactly as you would after `.switchedCleanly`.
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
    /// - Note: The JWT auth retry budget does not carry over. It is state on the `AuthManager`
    ///         instance, and the switch builds a fresh one along with the rest of the
    ///         dependency container, so the new project starts with a full budget.
    ///
    /// - SeeAlso: IterableProject, IterableProjectSwitchResult, IterableConfig
    @available(iOSApplicationExtension, unavailable)
    @objc(switchProject:callback:)
    static func switchProject(project: IterableProject,
                              callback: ((IterableProjectSwitchResult) -> Void)? = nil) {
        switchProject(apiKey: project.apiKey,
                      config: project.config,
                      apiEndPointOverride: nil,
                      dependencyContainer: nil,
                      callback: callback == nil ? nil : { cleanTeardown in
                          callback?(.from(cleanTeardown: cleanTeardown))
                      })
    }
}

extension IterableAPI {
    @available(iOSApplicationExtension, unavailable)
    /// - Parameter resumingGate: `true` when this call is a request that was queued during an
    ///                           earlier switch and has inherited its still-raised gate, so it
    ///                           must not raise one of its own and owns releasing it if it
    ///                           bails out before the teardown starts.
    static func switchProject(apiKey: String,
                              config: IterableConfig,
                              apiEndPointOverride: String?,
                              dependencyContainer: DependencyContainerProtocol?,
                              callback: ((Bool) -> Void)?,
                              resumingGate: Bool = false) {
        // A bail-out on an inherited gate has to release it, or it stays raised for the life of
        // the process and every later SDK call is queued and never replayed. The callbacks are
        // already in the gate, so endSwitch delivers them.
        func releaseInheritedGate(_ succeeded: Bool) {
            guard resumingGate else { return }
            runNextSwitchIfAny(ProjectSwitchGate.shared.endSwitch(succeeded: succeeded))
        }

        // Step 1: guard and validate.
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            ITBError("switchProject called with an empty API key. The SDK is left on the project it is already on.")
            deliverOnMainThread(callback, false)
            releaseInheritedGate(false)
            return
        }

        guard let outgoing = implementation else {
            ITBError("switchProject called before the SDK was initialized. Initializing with the supplied API key instead.")
            initialize2(apiKey: apiKey,
                        launchOptions: nil,
                        config: config,
                        apiEndPointOverride: apiEndPointOverride,
                        dependencyContainer: dependencyContainer,
                        callback: { started in
                            deliverOnMainThread(callback, started)
                            releaseInheritedGate(started)
                        })
            return
        }

        guard outgoing.apiKey != apiKey else {
            ITBInfo("switchProject called with the API key already in use. Nothing to tear down.")
            deliverOnMainThread(callback, true)
            releaseInheritedGate(true)
            return
        }

        // Step 2: raise the gate so any SDK call made from here until step 8 is queued. Skipped
        // when the gate was inherited from the switch that queued this request: it was never
        // lowered, precisely so nothing could take it in between.
        if !resumingGate {
            let request = ProjectSwitchGate.PendingSwitchRequest(apiKey: apiKey,
                                                                 config: config,
                                                                 apiEndPointOverride: apiEndPointOverride,
                                                                 dependencyContainer: dependencyContainer,
                                                                 callbacks: callback.map { [$0] } ?? [])
            guard ProjectSwitchGate.shared.beginSwitch(request) else {
                ITBInfo("switchProject is already in progress. This request will be honoured when it completes.")
                return
            }
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
                                    // Step 8: drain queued calls FIFO against the new project,
                                    // lower the gate, then fire every registered callback on
                                    // the main thread. A switch requested during this one for a
                                    // different project runs next, so the SDK ends up where the
                                    // app last asked to be.
                                    let next = ProjectSwitchGate.shared.endSwitch(succeeded: teardownWasClean && started)
                                    runNextSwitchIfAny(next)
                                })
                }
            }
        }
    }

    /// Runs a switch that was requested while another was in flight, on the gate that switch
    /// handed over rather than a fresh one. Dispatched rather than called inline so a chain of
    /// rapid requests unwinds the stack between switches.
    ///
    /// The callbacks are not passed along: `endSwitch` moved them into the gate at handover, so
    /// they fire from there when this switch lands, together with any later request for the
    /// same project that joined it in the meantime.
    private static func runNextSwitchIfAny(_ next: ProjectSwitchGate.PendingSwitchRequest?) {
        guard let next = next else { return }
        ITBInfo("switchProject: running the switch requested while the previous one was in flight")
        switchQueue.async {
            switchProject(apiKey: next.apiKey,
                          config: next.config,
                          apiEndPointOverride: next.apiEndPointOverride,
                          dependencyContainer: next.dependencyContainer,
                          callback: nil,
                          resumingGate: true)
        }
    }

    private static func deliverOnMainThread(_ callback: ((Bool) -> Void)?, _ succeeded: Bool) {
        guard let callback = callback else { return }
        DispatchQueue.main.async { callback(succeeded) }
    }

    private static let switchQueue = DispatchQueue(label: "com.iterable.projectSwitch")
}
