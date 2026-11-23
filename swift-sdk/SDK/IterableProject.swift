//
//  Copyright © 2026 Iterable. All rights reserved.
//

import Foundation

/// An Iterable project to run the SDK against: a Mobile API key together with the `IterableConfig`
/// that belongs with it.
///
/// The two halves are paired in one object on purpose. `IterableConfig` carries the data region and
/// the `authDelegate`, so supplying a key and a config separately allows one project's key to be
/// paired with another project's region or auth delegate. That mismatch produces an authentication
/// failure, or a request sent to the wrong region, that looks unrelated to the project it came from.
/// Requiring the pair makes it unrepresentable.
///
/// Build one per project or region:
///
/// ```swift
/// let config = IterableConfig()
/// config.authDelegate = euAuthDelegate
/// config.dataRegion = IterableDataRegion.EU
///
/// guard let euProject = IterableProject(apiKey: euApiKey, config: config) else {
///     // The key was empty. Handle it as you would any other bad configuration value.
///     return
/// }
/// ```
///
/// - Important: `IterableConfig` holds its delegates **weakly**, and this type does not change that.
///             If you keep a project as a long-lived constant, keep a strong reference to its
///             delegates somewhere too. A delegate that is only referenced by the config will be
///             deallocated, and auth or URL handling will stop working with nothing to indicate why.
///
/// - Note: `IterableConfig` is a mutable class, so this type pairs the key with a config rather than
///         freezing it. Mutating the config after building a project changes what the project will
///         apply. Treat a project as built and then left alone.
///
/// - SeeAlso: `IterableAPI.switchProject(project:callback:)`
@objcMembers
public class IterableProject: NSObject {
    /// The project's Iterable Mobile API key.
    public let apiKey: String

    /// The configuration this project runs with.
    public let config: IterableConfig

    /// Creates a project, or returns `nil` if `apiKey` is empty or whitespace only.
    ///
    /// Validated here rather than at the call site so an unusable project cannot be constructed: a
    /// blank key passed to a switch would otherwise tear down the project the SDK is on and leave it
    /// initialized against nothing. A blank key is a normal outcome of a failed region lookup or a
    /// missing remote config value, so this is failable rather than a trap.
    ///
    /// - Parameters:
    ///    - apiKey: The project's Iterable Mobile API key
    ///    - config: The `IterableConfig` to run this project with
    public init?(apiKey: String, config: IterableConfig) {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            ITBError("IterableProject requires a non-empty API key. Returning nil.")
            return nil
        }

        self.apiKey = apiKey
        self.config = config

        super.init()
    }

    /// Masks the key, so a project can be logged without leaking it.
    public override var description: String {
        "IterableProject(apiKey: \(apiKey.prefix(1))***, dataRegion: \(config.dataRegion))"
    }
}
