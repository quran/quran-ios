//
//  NoteCell.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/26/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Localization
import SwiftUI
import UIx

public struct NoteCell: View {
    // MARK: Lifecycle

    public init(
        page: Int,
        localizedVerse: String,
        arabicSuraName: String,
        versesCount: Int,
        ayahText: String,
        note: String,
        createdSince: String,
        color: NoteColor
    ) {
        self.page = page
        self.localizedVerse = localizedVerse
        self.arabicSuraName = arabicSuraName
        self.versesCount = versesCount
        self.ayahText = ayahText
        self.note = note
        self.createdSince = createdSince
        self.color = color
    }

    // MARK: Public

    public var body: some View {
        HStack {
            color.color
                .frame(width: 4)

            VStack(alignment: .leading) {
                HStack {
                    SuraTextView(style: .caption, title: localizedVerse, arabicSuraName: arabicSuraName, withSpacer: false)
                    if versesCount > 1 {
                        Text(lFormat("notes.verses-count", versesCount - 1))
                            .font(.caption)
                    }
                }
                .foregroundColor(Color.secondaryLabel)

                HStack {
                    Text(ayahText)
                        .lineLimit(2)
                        .font(.quran(ofSize: .small))

                    Spacer()
                }
                .environment(\.layoutDirection, .rightToLeft)

                if !note.isEmpty {
                    // add padding on different views as Text gets truncated if applied to to Text even for iOS 14
                    Spacer()
                        .frame(height: 0)
                        .padding(.bottom)
                    Text(note)
                        .lineLimit(3)
                    Spacer()
                        .frame(height: 0)
                        .padding(.bottom)
                }

                DateSinceTextView(since: createdSince)
            }
            .padding(.trailing)

            PageNumberListItemView(page: page)
        }
        .padding()
    }

    // MARK: Internal

    let page: Int
    let localizedVerse: String
    let arabicSuraName: String
    let versesCount: Int
    let ayahText: String
    let note: String
    let createdSince: String
    let color: NoteColor
}

// swiftlint:disable line_length
struct NoteCellCell_Previews: PreviewProvider {
    // MARK: Internal

    static var previews: some View {
        Previewing.list {
            NoteCell(
                page: 1,
                localizedVerse: "Sura 1, Verse: 2",
                arabicSuraName: suraName,
                versesCount: 1,
                ayahText: "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ",
                note: "Some note1 Some note1 Some note1 Some note1 Some note1 Some note1 Some note1",
                createdSince: "Just now",
                color: .red
            )
            Divider()

            NoteCell(
                page: 44,
                localizedVerse: "Sura 1, Verse: 2",
                arabicSuraName: suraName,
                versesCount: 4,
                ayahText: "وَإِذۡ قَالَ مُوسَىٰ لِقَوۡمِهِۦ يَٰقَوۡمِ إِنَّكُمۡ ظَلَمۡتُمۡ أَنفُسَكُم بِٱتِّخَاذِكُمُ ٱلۡعِجۡلَ فَتُوبُوٓاْ إِلَىٰ بَارِئِكُمۡ فَٱقۡتُلُوٓاْ أَنفُسَكُمۡ ذَٰلِكُمۡ خَيۡرٞ لَّكُمۡ عِندَ بَارِئِكُمۡ فَتَابَ عَلَيۡكُمۡۚ إِنَّهُۥ هُوَ ٱلتَّوَّابُ ٱلرَّحِيمُ",
                note: "A single line note",
                createdSince: "Just now",
                color: .purple
            )
            Divider()
        }
    }

    // MARK: Private

    private static let suraName = String(UnicodeScalar(0xE907)!)
}

// swiftlint:enable line_length
