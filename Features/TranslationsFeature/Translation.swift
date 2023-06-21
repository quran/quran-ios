import NoorUI
import QuranText
import UIKit

@dynamicMemberLookup
public struct TranslationItem: Equatable, Sendable {
    // MARK: Lifecycle

    public init(info: TranslationInfo, isDownloaded: Bool, downloadState: DownloadState, isSelected: Bool) {
        self.info = info
        self.isDownloaded = isDownloaded
        self.downloadState = downloadState
        self.isSelected = isSelected
    }

    // MARK: Public

    public let info: TranslationInfo

    public let isDownloaded: Bool
    public let downloadState: DownloadState

    public let isSelected: Bool

    public subscript<T>(dynamicMember keyPath: KeyPath<TranslationInfo, T>) -> T {
        info[keyPath: keyPath]
    }
}

public struct TranslationInfo: Hashable, Identifiable, Sendable {
    public typealias ID = Int

    // MARK: Lifecycle

    public init(id: TranslationInfo.ID, displayName: String, languageCode: String, translator: String?) {
        self.id = id
        self.displayName = displayName
        self.languageCode = languageCode
        self.translator = translator
    }

    // MARK: Public

    public let id: ID
    public let displayName: String
    public let languageCode: String
    public let translator: String?

    // TODO: Reuse in QuranTranslationTranslatorNameCollectionViewCell
    public func preferredTranslatorNameFont(ofSize size: FontSize) -> UIFont {
        if languageCode == "am" {
            return .translatorNameAmharic(ofSize: size)
        } else if languageCode == "ar" {
            return .translatorNameArabic(ofSize: size)
        } else {
            return .translatorNameEnglish(ofSize: size)
        }
    }
}
