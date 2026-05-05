//
//  BCITIDs.swift
//  IterableSDK-Integration-Tester
//
//  Centralized IDs for the campaigns and templates the BCIT app and integration
//  tests reference. These point at the **Mobile SDK Testing** project (project
//  1226, NJ engineering org). When we recreate or rotate these campaigns, this
//  is the single place to update.
//
//  Used by both the app target (button titles, push payloads sent by the in-app
//  backend) and the UI-test target (simulated CI push payloads, alert string
//  assertions).
//

import Foundation

/// IDs of campaigns provisioned in the Mobile SDK Testing project that BCIT
/// triggers or whose payloads it stamps onto simulated pushes in CI.
enum BCITCampaign {
    /// Basic push campaign — used as the `itbl.campaignId` stamp on simulated
    /// pushes in CI and as the campaignId on backend-sent standard pushes.
    static let basicPush = 17966885

    /// Deep link push campaign — payload contains a `defaultAction` URL.
    static let deepLinkPush = 17967053

    /// Silent push campaign — content-available only, no UI.
    static let silentPush = 17967055

    /// In-app display campaign — basic in-app message rendering.
    static let inAppDisplay = 17967060

    /// In-app deep link campaign — message contains a deep link.
    static let inAppDeepLink = 17967062

    /// Full-screen in-app campaign (SDK-31 regression).
    static let inAppFullScreen = 17967063

    /// Bottom-position in-app campaign (SDK-92 regression).
    static let inAppBottomPosition = 17967064

    /// Top-position in-app campaign (SDK-92 regression).
    static let inAppTopPosition = 17967065

    /// Silent push campaign for embedded message sync (notificationType = UpdateEmbedded).
    static let embeddedSilentPush = 17967057
}

/// IDs of message templates provisioned in the Mobile SDK Testing project.
enum BCITTemplate {
    /// Template attached to the basic push campaign.
    static let basicPush = 23382518

    /// Template attached to the deep link push campaign.
    static let deepLinkPush = 23382695
}

/// Asset URLs referenced by simulated push payloads in CI.
enum BCITAsset {
    /// `attachment-url` stamped on simulated deep-link push payloads. Lives in
    /// the Mobile SDK Testing project's media library (project 1226).
    static let deepLinkPushAttachment = "https://library.iterable.com/1733/1226/57740fdbf0be4cc79672eb07d9969f30-square_cat.png"
}
