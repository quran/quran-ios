import Foundation
import QuranText

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
}

extension Locale {
    static func localizedLanguage(forCode code: String) -> String? {
        Locale(identifier: code).localizedString(forLanguageCode: code)
    }
}
