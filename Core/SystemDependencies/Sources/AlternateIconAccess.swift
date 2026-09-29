//
//  AlternateIconAccess.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import UIKit

/// The system API that changes the app's Home Screen icon.
@MainActor
public protocol AlternateIconAccess {
    /// Whether this device and platform let the app change its icon.
    var supportsAlternateIcons: Bool { get }

    /// The name of the icon iOS shows, or `nil` for the primary icon.
    var alternateIconName: String? { get }

    /// Shows the named icon, or the primary icon for `nil`. iOS confirms the change with its own alert.
    func setAlternateIconName(_ name: String?) async throws
}

public struct DefaultAlternateIconAccess: AlternateIconAccess {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var supportsAlternateIcons: Bool {
        UIApplication.shared.supportsAlternateIcons
    }

    public var alternateIconName: String? {
        UIApplication.shared.alternateIconName
    }

    public func setAlternateIconName(_ name: String?) async throws {
        try await UIApplication.shared.setAlternateIconName(name)
    }
}
