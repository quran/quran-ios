//
//  TranslationFootnote.swift
//
//
//  Created by Mohamed Afifi on 2024-01-20.
//

import Localization
import NoorUI
import QuranKit
import QuranText
import SwiftUI
import UIx

struct TranslationFootnote: View, Identifiable {
    struct Id: Hashable {
        let string: TranslationString
        let footnoteIndex: Int
        let verse: AyahNumber

        let translation: Translation
        let translationFontSize: FontSize
    }

    var id: Id { Id(string: string, footnoteIndex: footnoteIndex, verse: verse, translation: translation, translationFontSize: translationFontSize) }

    var text: String {
        string.footnoteText(at: footnoteIndex)
    }

    let string: TranslationString
    let footnoteIndex: Int
    /// The verse with the footnote.
    let verse: AyahNumber
    /// The verse references in `text` that the reader can follow.
    var verseReferences: [FootnoteVerseReference] = []

    let translation: Translation
    let translationFontSize: FontSize

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(attributedText)
                    .font(translation.textFont)
                    .dynamicTypeSize(translationFontSize.dynamicTypeSize)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .themedForeground()
            .themedBackground()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(lFormat("translation.text.footnote-title", footnoteIndex + 1))
            .toolbar {
                CloseToolbarItem {
                    dismiss()
                }
            }
        }
        .sheetPresentationDetents([.medium, .large])
    }

    private var attributedText: AttributedString {
        let text = text
        var string = AttributedString(text)
        for reference in verseReferences {
            if let range = string.range(from: reference.range, overallRange: text.startIndex ..< text.endIndex, overallText: text) {
                string[range].link = reference.url(from: verse)
            }
        }
        return string
    }
}

private struct TranslationFootnotePreview: View {
    static let string = TranslationString(
        text: "",
        quranRanges: [],
        footnoteRanges: [],
        footnotes: ["Footnote # 1", "See footnote for {6:38}."]
    )

    static var translation: Translation {
        Translation(
            id: 1,
            displayName: "",
            translator: "",
            translatorForeign: "Khan & Hilai",
            fileURL: URL(validURL: "a"),
            fileName: "quran.en.khanhilali.db",
            languageCode: "",
            version: 5,
            installedVersion: 5
        )
    }

    @State var footnote: TranslationFootnote? = buildFootnote(index: 0)

    var body: some View {
        List {
            ForEach(0 ..< Self.string.footnotes.count, id: \.self) { index in
                Button {
                    footnote = Self.buildFootnote(index: index)
                } label: {
                    Text("Footnote \(index + 1)")
                }
            }
        }
        .sheet(item: $footnote) { $0 }
    }

    private static func buildFootnote(index: Int) -> TranslationFootnote {
        let verse = Quran.hafsMadani1405.firstVerse
        return TranslationFootnote(
            string: string,
            footnoteIndex: index,
            verse: verse,
            verseReferences: string.footnoteText(at: index).footnoteVerseReferences(),
            translation: translation,
            translationFontSize: .medium
        )
    }
}

#Preview {
    TranslationFootnotePreview()
        .environment(\.themeStyle, .calm)
}
