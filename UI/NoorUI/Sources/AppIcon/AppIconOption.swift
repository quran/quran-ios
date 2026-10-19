//
//  AppIconOption.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import SwiftUI

/// An icon the app offers on the Home Screen.
public struct AppIconOption: Identifiable {
    // MARK: Lifecycle

    /// - Parameters:
    ///   - id: A stable identifier, also used in analytics.
    ///   - alternateIconName: The name iOS knows the icon by, or `nil` for the primary icon.
    ///   - name: The localized display name.
    ///   - previewImageName: A preview image in the main bundle.
    ///   - artworkImageName: An opaque, square image of the icon in the main bundle, without its rounded mask.
    ///   - accent: The colors the icon lends the interface.
    public init(
        id: String,
        alternateIconName: String?,
        name: String,
        previewImageName: String,
        artworkImageName: String,
        accent: AppIconAccent
    ) {
        self.id = id
        self.alternateIconName = alternateIconName
        self.name = name
        self.previewImageName = previewImageName
        self.artworkImageName = artworkImageName
        self.accent = accent
    }

    // MARK: Public

    public let id: String
    public let name: String

    /// Whether this is the icon the app ships with.
    public var isPrimary: Bool {
        alternateIconName == nil
    }

    /// The icon as the Home Screen draws it, with its rounded corners.
    public var previewImage: Image {
        Image(previewImageName, bundle: .main)
    }

    /// The icon as square artwork for places that draw their own shape, such as Now Playing.
    public var artworkImage: UIImage? {
        UIImage(named: artworkImageName, in: .main, compatibleWith: nil)
    }

    // MARK: Internal

    let alternateIconName: String?
    let previewImageName: String
    let artworkImageName: String
    let accent: AppIconAccent
}

extension AppIconOption: Equatable {
    public static func == (lhs: AppIconOption, rhs: AppIconOption) -> Bool {
        lhs.id == rhs.id
    }
}
