//
//  NoteEditorView.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/20/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Localization
import QuranAnnotations
import QuranKit
import SwiftUI
import UIx

@MainActor
public struct NoteEditorView: View {
    // MARK: Lifecycle

    public init(
        note: EditableNote,
        showsColors: Bool = true,
        done: @escaping () -> Void,
        delete: @escaping AsyncAction
    ) {
        _note = StateObject(wrappedValue: note)
        self.showsColors = showsColors
        self.done = done
        self.delete = delete
    }

    // MARK: Public

    public var body: some View {
        NoteEditorContent(
            note: note,
            showsColors: showsColors,
            delete: delete
        )
        .populateThemeStyle()
    }

    // MARK: Internal

    @StateObject var note: EditableNote

    let showsColors: Bool
    let done: () -> Void
    let delete: AsyncAction
}

@MainActor
private struct NoteEditorContent: View {
    @ObservedObject var note: EditableNote

    let showsColors: Bool
    let delete: AsyncAction

    @Environment(\.locale) private var locale
    @Environment(\.themeStyle) private var themeStyle
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ScaledMetric private var highlightSpacing = 12.0

    var body: some View {
        VStack(spacing: 0) {
            if verticalSizeClass != .compact && !showsColors {
                quranDivider
                quranText
            }

            if showsColors {
                highlightPicker
            }

            if verticalSizeClass != .compact {
                noteDivider
            }

            TextView(
                $note.note,
                editing: $note.editing,
                textColor: themeStyle.textColor
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .onTapGesture { } // Prevent the parent tap gesture from dismissing the keyboard.
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footer
        }
        .foregroundColor(Color(themeStyle.textColor))
        .background(Color(themeStyle.backgroundColor).ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture {
            note.editing = false
        }
        .onAppear {
            note.editing = note.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var quranText: some View {
        let text: MultipartText = "\(quran: note.ayahText, color: .clear, lineLimit: 2)"
        return text
            .view(ofSize: .footnote, alignment: .trailing)
            .foregroundColor(.secondaryLabel)
            .environment(\.layoutDirection, .rightToLeft)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding()
    }

    private var quranDivider: some View {
        sectionDivider {
            Text("✳︎")
                .font(.title3)
                .foregroundColor(Color(themeStyle.pageSeparatorLine))
                .accessibilityHidden(true)
        }
    }

    private var noteDivider: some View {
        sectionDivider {
            Text(l("notes.editor.note-divider"))
                .font(.footnote)
                .tracking(locale.isArabicLanguage ? 0 : 3)
                .foregroundColor(Color(themeStyle.secondaryTextColor))
                .lineLimit(1)
        }
    }

    private var highlightPicker: some View {
        HStack(spacing: highlightSpacing) {
            ForEach(HighlightColor.sortedColors, id: \.self) { color in
                Button {
                    note.selectedColor = color
                } label: {
                    NoteCircle(color: color.color, selected: color == note.selectedColor)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top)
        .padding(.bottom, verticalSizeClass == .compact ? 0 : nil)
    }

    private var footer: some View {
        HStack(alignment: .firstTextBaseline) {
            metadata
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer()

            AsyncButton(action: delete) {
                Text(l("notes.editor.delete"))
                    .foregroundColor(.red)
            }
        }
        .font(.footnote)
        .padding()
        .background(Color(themeStyle.backgroundColor))
        .overlay(alignment: .top) {
            thinDivider
        }
    }

    private var metadata: some View {
        HStack(spacing: 4) {
            if !note.modifiedSince.isEmpty {
                Text(lFormat("notes.editor.created", note.modifiedSince))
                Text("·")
                    .accessibilityHidden(true)
            }
            Text(lFormat("notes.editor.words-count", note.wordCount))
        }
        .foregroundColor(Color(themeStyle.secondaryTextColor))
        .accessibilityElement(children: .combine)
    }

    private var thinDivider: some View {
        Divider()
            .overlay(Color(themeStyle.secondaryTextColor).opacity(0.2))
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color(themeStyle.pageSeparatorLine))
            .frame(height: 1)
    }

    private func sectionDivider(
        @ViewBuilder label: () -> some View
    ) -> some View {
        HStack(spacing: 16) {
            dividerLine
            label()
            dividerLine
        }
        .padding(.horizontal)
    }
}

@MainActor
private struct NoteEditorPreview: View {
    let showsColors: Bool

    var body: some View {
        let verses = Quran.hafsMadani1405.suras[15].verses
        NoteEditorView(
            note: EditableNote(
                ayahRange: verses[34] ... verses[35],
                ayahText: "وَقَالَ ٱلَّذِينَ أَشْرَكُوا۟ لَوْ شَآءَ ٱللَّهُ مَا عَبَدْنَا مِن دُونِهِۦ مِن شَىْءٍ نَّحْنُ وَلَآ ءَابَآؤُنَا",
                modifiedSince: "2 hours ago",
                selectedColor: .blue,
                note: "The “if Allah willed” excuse — the same argument every nation made. Cross-ref 6:148."
            ),
            showsColors: showsColors,
            done: {},
            delete: {}
        )
    }
}

#Preview("Synced note") {
    NoteEditorPreview(showsColors: false)
}

#Preview("Legacy note") {
    NoteEditorPreview(showsColors: true)
}
