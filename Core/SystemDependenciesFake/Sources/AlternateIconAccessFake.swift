//
//  AlternateIconAccessFake.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import Foundation
import SystemDependencies

@MainActor
public final class AlternateIconAccessFake: AlternateIconAccess {
    // MARK: Lifecycle

    public init(supportsAlternateIcons: Bool = true, alternateIconName: String? = nil) {
        self.supportsAlternateIcons = supportsAlternateIcons
        self.alternateIconName = alternateIconName
    }

    // MARK: Public

    public var supportsAlternateIcons: Bool
    public var alternateIconName: String?

    /// When set, changing the icon fails with this error and keeps the current icon.
    public var setAlternateIconNameError: Error?

    public func setAlternateIconName(_ name: String?) async throws {
        if let setAlternateIconNameError {
            throw setAlternateIconNameError
        }
        alternateIconName = name
    }
}
