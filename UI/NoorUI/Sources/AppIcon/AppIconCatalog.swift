//
//  AppIconCatalog.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

/// The Home Screen icons an app offers, in the order the App Icon screen lists them.
public struct AppIconCatalog {
    public struct Section: Identifiable {
        // MARK: Lifecycle

        public init(
            id: String,
            title: String,
            previewSize: PreviewSize,
            options: [AppIconOption]
        ) {
            self.id = id
            self.title = title
            self.previewSize = previewSize
            self.options = options
        }

        // MARK: Public

        public enum PreviewSize {
            case large
            case regular
        }

        public let id: String
        public let title: String
        public let previewSize: PreviewSize
        public let options: [AppIconOption]
    }

    // MARK: Lifecycle

    /// - Precondition: Exactly one option is the primary icon, whose `alternateIconName` is `nil`.
    ///   It is the default icon.
    public init(sections: [Section]) {
        let primaryOptions = sections.flatMap(\.options).filter(\.isPrimary)
        precondition(primaryOptions.count == 1, "An app icon catalog needs exactly one primary icon.")
        self.sections = sections
        defaultOption = primaryOptions[0]
    }

    // MARK: Public

    public let sections: [Section]

    /// The primary icon, which the app shows until the user picks another one.
    public let defaultOption: AppIconOption

    // MARK: Internal

    var options: [AppIconOption] {
        sections.flatMap(\.options)
    }

    /// The option iOS shows for `alternateIconName`. Unknown names fall back to the default icon.
    func option(alternateIconName: String?) -> AppIconOption {
        options.first { $0.alternateIconName == alternateIconName } ?? defaultOption
    }
}
