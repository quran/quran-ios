//
//  TranslationURL.swift
//
//
//  Created by Mohamed Afifi on 2024-01-24.
//

import Foundation
import QuranKit
import QuranText
import SwiftUI
import UIx

enum TranslationURL: Codable {
    case footnote(translationId: Translation.ID, sura: Int, ayah: Int, footnoteIndex: Int)
    case readMore(translationId: Translation.ID, sura: Int, ayah: Int)
    /// A verse that a footnote of `sura`:`ayah` refers to.
    case verseReference(sura: Int, ayah: Int, referencedSura: Int, referencedAyah: Int)

    private static let scheme = "quran-ios"
    private static let host = "translationURL"
    private static let data = "data"

    var url: URL {
        let encoder = JSONEncoder()
        let jsonData = try! encoder.encode(self)
        let jsonString = String(data: jsonData, encoding: .utf8)?
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = Self.host
        components.queryItems = [URLQueryItem(name: Self.data, value: jsonString)]
        return components.url!
    }

    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              components.scheme == Self.scheme,
              components.host == Self.host,
              let queryItems = components.queryItems,
              let dataItem = queryItems.first(where: { $0.name == Self.data }),
              let dataString = dataItem.value,
              let jsonData = dataString.removingPercentEncoding?.data(using: .utf8)
        else {
            return nil
        }

        let decoder = JSONDecoder()
        self = try! decoder.decode(TranslationURL.self, from: jsonData)
    }
}

extension FootnoteVerseReference {
    /// Follows this reference from a footnote of `verse`.
    func url(from verse: AyahNumber) -> URL {
        TranslationURL.verseReference(
            sura: verse.sura.suraNumber,
            ayah: verse.ayah,
            referencedSura: sura,
            referencedAyah: ayah
        ).url
    }
}

extension View {
    func openTranslationURL(_ openURL: @escaping (TranslationURL) -> Void) -> some View {
        tryOpenURL { url in
            if let translationURL = TranslationURL(url: url) {
                openURL(translationURL)
                return .handled
            } else {
                return .systemAction
            }
        }
    }
}
