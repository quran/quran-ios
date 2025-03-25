//
//  TranslationFootnote.swift
//
//
//  Created by Mohamed Afifi on 2024-01-20.
//

import Localization
import QuranText
import SwiftUI

struct TranslationFootnote: View, Identifiable {
    struct Id: Hashable {
        let string: TranslationString
        let footnoteIndex: Int

        let translation: Translation
        let translationFontSize: FontSize
    }

    var id: Id { Id(string: string, footnoteIndex: footnoteIndex, translation: translation, translationFontSize: translationFontSize) }

    var text: String {
        let text = string.footnotes[footnoteIndex]
        return text.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
    }

    let string: TranslationString
    let footnoteIndex: Int

    let translation: Translation
    let translationFontSize: FontSize

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(text)
                    .font(translation.textFont)
                    .dynamicTypeSize(translationFontSize.dynamicTypeSize)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.readingBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(lFormat("translation.text.footnote-title", footnoteIndex + 1))
            .toolbar {
                Button {
                    dismiss()
                } label: {
                    Text(l("button.done"))
                        .bold()
                }
            }
        }
        .sheetPresentationDetents([.medium, .large])
    }
}

private struct TranslationFootnotePreview: View {
    static let string = TranslationString(
        text: "",
        quranRanges: [],
        footnoteRanges: [],
        footnotes: ["Footnote # 1", "Footnote # 2"]
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
        TranslationFootnote(string: string, footnoteIndex: index, translation: translation, translationFontSize: .medium)
    }
}

#Preview {
    TranslationFootnotePreview()
}
