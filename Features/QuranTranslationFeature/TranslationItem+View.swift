//
//  TranslationItem+View.swift
//
//
//  Created by Mohamed Afifi on 2023-12-28.
//

import Localization
import NoorUI
import QuranKit
import QuranText
import SwiftUI

extension TranslationPageHeader: View {
    var body: some View {
        HStack {
            Text(page.localizedQuarterName)
            Spacer()
            page.suraNames()
                .view(ofSize: .footnote, alignment: .trailing)
        }
        .readableInsetsPadding([.top, .horizontal])
        .padding(.bottom, ContentDimension.interSpacing)
    }
}

extension TranslationPageFooter: View {
    var body: some View {
        HStack {
            Spacer()
            Text(page.localizedNumber)
            Spacer()
        }
        .padding(.top, ContentDimension.interSpacing)
        .readableInsetsPadding([.bottom, .horizontal])
    }
}

extension TranslationVerseSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color.systemGray4)
            .frame(height: 1)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, ContentDimension.interSpacing)
    }
}

struct TranslationSuraNameView: View {
    @ScaledMetric var bottomPadding = 5
    @ScaledMetric var topPadding = 10

    let suraName: TranslationSuraName

    var body: some View {
        VStack {
            NoorImage.suraHeader.image.resizable()
                .aspectRatio(contentMode: .fit)
                .overlay {
                    Text(suraName.sura.localizedName(withPrefix: false))
                        .font(.title3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                }
            Text(suraName.sura.quran.arabicBesmAllah)
                .font(.quran())
                .dynamicTypeSize(suraName.arabicFontSize.dynamicTypeSize)
        }
        .padding(.bottom, bottomPadding)
        .padding(.top, topPadding)
        .readableInsetsPadding(.horizontal)
    }
}

struct TranslationArabicTextView: View {
    @ScaledMetric var bottomPadding = 5
    @ScaledMetric var topPadding = 10

    let arabicText: TranslationArabicText

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(lFormat("translation.text.ayah-number", arabicText.verse.sura.suraNumber, arabicText.verse.ayah))
                .padding(8)
                .foregroundColor(.secondaryLabel)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.systemGray5.opacity(0.5))
                )

            Text(arabicText.text)
                .font(.quran())
                .dynamicTypeSize(arabicText.arabicFontSize.dynamicTypeSize)
                .textAlignment(follows: .rightToLeft)
        }
        .padding(.bottom, bottomPadding)
        .padding(.top, topPadding)
        .readableInsetsPadding(.horizontal)
    }
}

struct TranslationTextChunkView: View {
    @ScaledMetric var topPadding = 10
    @ScaledMetric var baselineOffset = 5

    let chunk: TranslationTextChunk

    var body: some View {
        Text(string)
            .font(chunk.translation.textFont)
            .dynamicTypeSize(chunk.translationFontSize.dynamicTypeSize)
            .textAlignment(follows: chunk.translation.characterDirection)
            .padding(.top, chunk.chunkIndex == 0 ? topPadding : 0)
            .readableInsetsPadding(.horizontal)
    }

    private var string: AttributedString {
        let chunkRange = chunk.chunks[chunk.chunkIndex]
        let chunkText = chunk.text.text[chunkRange]

        var string = AttributedString(chunkText)
        for (index, footnoteRange) in chunk.text.footnoteRanges.enumerated() {
            if let range = string.range(from: footnoteRange, overallRange: chunkRange, overallText: chunk.text.text) {
                string[range].link = TranslationURL.footnote(
                    translationId: chunk.translation.id,
                    sura: chunk.verse.sura.suraNumber,
                    ayah: chunk.verse.ayah,
                    footnoteIndex: index
                ).url
                string[range].font = .footnote
                string[range].baselineOffset = baselineOffset
            }
        }

        for quranRange in chunk.text.quranRanges {
            if let range = string.range(from: quranRange, overallRange: chunkRange, overallText: chunk.text.text) {
                string[range].foregroundColor = .accentColor
            }
        }

        if chunk.readMore {
            var readMore = AttributedString("\n\(l("translation.text.read-more"))")
            readMore.foregroundColor = .accentColor
            readMore.link = TranslationURL.readMore(
                translationId: chunk.translation.id,
                sura: chunk.verse.sura.suraNumber,
                ayah: chunk.verse.ayah
            ).url
            readMore.font = .body
            string.append(readMore)
        }

        return string
    }
}

struct TranslationReferenceVerseView: View {
    @ScaledMetric var topPadding = 10
    let referenceVerse: TranslationReferenceVerse

    var body: some View {
        Text(lFormat("translation.text.see-referenced-verse", referenceVerse.reference.ayah))
            .font(.body)
            .dynamicTypeSize(referenceVerse.translationFontSize.dynamicTypeSize)
            .textAlignment(follows: referenceVerse.translation.characterDirection)
            .padding(.top, topPadding)
            .readableInsetsPadding(.horizontal)
    }
}

struct TranslatorTextView: View {
    @ScaledMetric var bottomPadding = 10
    let translator: TranslatorText
    var body: some View {
        Text(verbatim: "- \(translator.translation.translationName)")
            .foregroundColor(.secondaryLabel)
            .font(.body)
            .dynamicTypeSize(translator.translationFontSize.dynamicTypeSize)
            .textAlignment(follows: translator.translation.characterDirection)
            .padding(.bottom, bottomPadding)
            .readableInsetsPadding(.horizontal)
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
            case .verseSeparator(let separator, _):
                separator
            case .suraName(let suraName, _):
                TranslationSuraNameView(suraName: suraName)
            case .arabicText(let arabicText, _):
                TranslationArabicTextView(arabicText: arabicText)
            case .translationTextChunk(let translationTextChunk, _):
                TranslationTextChunkView(chunk: translationTextChunk)
            case .translationReferenceVerse(let translationReferenceVerse, _):
                TranslationReferenceVerseView(referenceVerse: translationReferenceVerse)
            case .translatorText(let translatorText, _):
                TranslatorTextView(translator: translatorText)
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

    let fontSize = FontSize.medium

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
