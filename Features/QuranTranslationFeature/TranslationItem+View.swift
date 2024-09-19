//
//  TranslationItem+View.swift
//
//
//  Created by Mohamed Afifi on 2023-12-28.
//

import NoorUI
import QuranKit
import QuranText
import SwiftUI

extension TranslationPageHeader: View {
    var body: some View {
        QuranPageHeader(quarterName: page.localizedQuarterName, suraNames: page.suraNames())
    }
}

extension TranslationPageFooter: View {
    var body: some View {
        QuranPageFooter(page: page.localizedNumber)
    }
}

extension TranslationSuraName: View {
    var body: some View {
        QuranSuraName(
            suraName: sura.localizedName(withPrefix: false),
            besmAllah: sura.startsWithBesmAllah ? sura.quran.arabicBesmAllah : "",
            besmAllahFontSize: arabicFontSize
        )
    }
}

extension TranslationArabicText: View {
    var body: some View {
        QuranArabicText(verse: verse, text: text, fontSize: arabicFontSize)
    }
}

extension TranslationTextChunk {
    var readMoreURL: URL {
        TranslationURL.readMore(
            translationId: translation.id,
            sura: verse.sura.suraNumber,
            ayah: verse.ayah
        ).url
    }
}

extension TranslationTextChunk: View {
    var body: some View {
        QuranTranslationTextChunk(
            text: text.text,
            chunk: chunks[chunkIndex],
            footnoteRanges: text.footnoteRanges,
            quranRanges: text.quranRanges,
            firstChunk: chunkIndex == 0,
            readMoreURL: readMore ? readMoreURL : nil,
            footnoteURL: { index in
                TranslationURL.footnote(
                    translationId: translation.id,
                    sura: verse.sura.suraNumber,
                    ayah: verse.ayah,
                    footnoteIndex: index
                ).url
            },
            font: translation.textFont,
            fontSize: translationFontSize,
            characterDirection: translation.characterDirection
        )
    }
}

extension TranslationReferenceVerse: View {
    var body: some View {
        QuranTranslationReferenceVerse(reference: reference, fontSize: translationFontSize, characterDirection: translation.characterDirection)
    }
}

extension TranslatorText: View {
    var body: some View {
        QuranTranslatorName(name: translation.translationName, fontSize: translationFontSize, characterDirection: translation.characterDirection)
    }
}

extension TranslationItem: View {
    var body: some View {
        VStack {
            switch self {
            case .pageHeader(let pageHeader):
                pageHeader
            case .pageFooter(let pageFooter):
                pageFooter
            case .verseSeparator:
                QuranVerseSeparator()
            case .suraName(let suraName, _):
                suraName
            case .arabicText(let arabicText, _):
                arabicText
            case .translationTextChunk(let translationTextChunk, _):
                translationTextChunk
            case .translationReferenceVerse(let translationReferenceVerse, _):
                translationReferenceVerse
            case .translatorText(let translatorText, _):
                translatorText
            }
        }
        .font(.footnote)
        .listRowSeparator(.hidden)
        .listRowInsets(.zero)
        .listRowBackground(Color.clear)
        .background(color)
        .trackingTarget(item: id)
    }
}

import NoorFont

#Preview {
    ContentTranslationPreview()
}

private struct ContentTranslationPreview: View {
    @State var readMore: Bool = true

    let quran = Quran.hafsMadani1405

    let fontSize = FontSize.large

    var translation: Translation {
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

    var translationText: String {
        """
        Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.
        """
    }

    var chunks: [Range<String.Index>] {
        translationText.chunkRanges(maxChunkSize: 70)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                TranslationItem.pageHeader(.init(page: quran.pages[0]))
                TranslationItem.suraName(.init(sura: quran.firstSura, arabicFontSize: fontSize), nil)
                TranslationItem.arabicText(.init(
                    verse: quran.firstVerse, text: quran.arabicBesmAllah, arabicFontSize: fontSize
                ), nil)
                ForEach(0 ..< (readMore ? 1 : chunks.count), id: \.self) { chunkIndex in
                    TranslationItem.translationTextChunk(
                        .init(
                            verse: quran.firstVerse,
                            translation: translation,
                            text: .init(text: translationText, quranRanges: [], footnoteRanges: [], footnotes: []),
                            chunks: chunks,
                            chunkIndex: chunkIndex,
                            readMore: readMore && chunkIndex == 0,
                            translationFontSize: fontSize
                        ), nil
                    )
                }
                TranslationItem.translatorText(.init(verse: quran.firstVerse, translation: translation, translationFontSize: fontSize), nil)
                TranslationItem.verseSeparator(.init(verse: quran.firstVerse), nil)

                TranslationItem.translationReferenceVerse(.init(verse: quran.firstVerse, translation: translation, reference: quran.lastVerse, translationFontSize: .medium), nil)
                TranslationItem.verseSeparator(.init(verse: quran.firstVerse), nil)

                TranslationItem.pageFooter(.init(page: quran.firstVerse.page))
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, 1)
            .populateReadableInsets()

            Button {
                readMore.toggle()
            } label: {
                Text("Toggle Read more")
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .padding()
        }
        .ignoresSafeArea()
        .onAppear {
            FontName.registerFonts()
        }
    }
}
