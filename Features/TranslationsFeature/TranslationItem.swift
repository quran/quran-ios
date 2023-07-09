import NoorUI
import QuranText
import UIKit

@dynamicMemberLookup
struct TranslationItem: Equatable, Sendable, Identifiable {
    enum DownloadingProgress: Hashable {
        case notDownloading
        case downloading(Double)
        case needsUpgrade
    }

    // MARK: Internal

    let info: Translation
    let progress: DownloadingProgress

    var id: Translation.ID { info.id }

    subscript<T>(dynamicMember keyPath: KeyPath<Translation, T>) -> T {
        info[keyPath: keyPath]
    }
}

extension Translation {
    var localizedLanguage: String? {
        Locale.localizedLanguage(forCode: languageCode)
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

extension Locale {
    static var currentLocalizedLanguage: String? {
        let langaugeCode = Locale.current.languageCode
        return langaugeCode.flatMap { localizedLanguage(forCode: $0) }
    }

    static func localizedLanguage(forCode code: String) -> String? {
        Locale(identifier: code).localizedString(forLanguageCode: code)
    }
}
