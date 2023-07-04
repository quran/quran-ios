import NoorUI
import QuranText
import UIKit

@dynamicMemberLookup
struct TranslationItem: Equatable, Sendable {
    enum DownloadingProgress: Hashable {
        case notDownloading
        case downloading(Double)
    }

    // MARK: Internal

    let info: Translation

    let isDownloaded: Bool

    // TODO: Remove
    let downloadState: DownloadState

    let progress: DownloadingProgress

    // TODO: Remove
    let isSelected: Bool

    subscript<T>(dynamicMember keyPath: KeyPath<Translation, T>) -> T {
        info[keyPath: keyPath]
    }
}

extension Translation {
    var translatorDisplayName: String? {
        translatorForeign ?? translator
    }

    // TODO: Reuse in QuranTranslationTranslatorNameCollectionViewCell
    func preferredTranslatorNameFont(ofSize size: FontSize) -> UIFont {
        if languageCode == "am" {
            return .translatorNameAmharic(ofSize: size)
        } else if languageCode == "ar" {
            return .translatorNameArabic(ofSize: size)
        } else {
            return .translatorNameEnglish(ofSize: size)
        }
    }
}
