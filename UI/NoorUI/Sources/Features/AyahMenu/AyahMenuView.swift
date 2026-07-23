//
//  AyahMenuView.swift
//  Quran
//
//  Created by Afifi, Mohamed on 7/10/21.
//  Copyright © 2021 Quran.com. All rights reserved.
//

import Localization
import QuranAnnotations
import SwiftUI
import UIx

public struct AyahMenuView: View {
    // MARK: Lifecycle

    public init(dataObject: AyahMenuUI.DataObject) {
        self.dataObject = dataObject
    }

    // MARK: Public

    public var body: some View {
        ScrollView {
            AyahMenuViewList(dataObject: dataObject)
        }
        .preferredContentSizeMatchesScrollView()
    }

    // MARK: Internal

    let dataObject: AyahMenuUI.DataObject
}

private struct AyahMenuViewList: View {
    // MARK: Internal

    let dataObject: AyahMenuUI.DataObject

    var noteDeleteText: String {
        switch dataObject.state {
        case .noHighlight:
            return "-"
        case .highlighted:
            return l("ayah.menu.delete-highlight")
        case .noted:
            return l("ayah.menu.delete-note")
        }
    }

    var editNote: some View {
        Row(title: l("ayah.menu.edit-note"), action: dataObject.actions.addNote) {
            noteIcon
        }
    }

    var addNote: some View {
        Row(title: l("ayah.menu.add-note"), action: dataObject.actions.addNote) {
            noteIcon
        }
    }

    var translation: some View {
        MenuGroup {
            Divider()
            Row(title: l("menu.translation"), action: dataObject.actions.showTranslation) {
                Image(systemName: "globe")
            }
            Divider()
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            MenuGroup {
                Row(
                    title: lAndroid("play"),
                    subtitle: .text(dataObject.playSubtitle),
                    action: dataObject.actions.play
                ) {
                    NoorSystemImage.play.image
                }
                Divider()
                Row(
                    title: l("ayah.menu.repeat"),
                    subtitle: .text(dataObject.repeatSubtitle),
                    action: dataObject.actions.repeatVerses
                ) {
                    Image(systemName: "repeat")
                }
                Divider()
            }

            MenuGroup {
                Divider()

                #if QURAN_SYNC
                readingBookmarkRow(dataObject.readingBookmarkState)
                Divider()
                    .padding(.leading)
                #endif

                Row(title: dataObject.bookmarkTitle, action: dataObject.actions.bookmark) {
                    bookmarkIcon
                }
                Divider()
                    .padding(.leading)

                switch dataObject.state {
                case .noHighlight, .highlighted:
                    addNote
                case .noted:
                    editNote
                }

                if dataObject.state != .noHighlight {
                    Divider()
                        .padding(.leading)

                    Row(title: noteDeleteText, action: dataObject.actions.deleteNote) {
                        Image(systemName: "trash")
                            .foregroundColor(Color.red)
                    }
                }

                Divider()
            }

            if !dataObject.isTranslationView {
                translation
            }

            MenuGroup {
                Divider()

                Row(title: l("ayah.menu.copy"), action: dataObject.actions.copy) {
                    Image(systemName: "doc.on.doc")
                }
                Divider()
                    .padding(.leading)
                Row(title: l("ayah.menu.share"), action: dataObject.actions.share) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    // MARK: Private

    @ViewBuilder private var bookmarkIcon: some View {
        switch dataObject.bookmarkState {
        case .unhighlighted:
            NoorSystemImage.bookmarkOutline.image
        case .bookmarked, .partiallyHighlighted:
            NoorSystemImage.bookmark.image
        case .highlighted(let color):
            NoorSystemImage.bookmark.image
                .foregroundColor(color.color)
        }
    }

    #if QURAN_SYNC
    @ViewBuilder
    private func readingBookmarkRow(_ state: AyahMenuUI.ReadingBookmarkState) -> some View {
        switch state {
        case .disabled(let message):
            Row(
                title: l("ayah.menu.reading-bookmark.title"),
                subtitle: .text(message),
                subtitlePlacement: .below,
                isEnabled: false,
                action: dataObject.actions.setReadingBookmark
            ) {
                ReadingBookmarkPin(style: .outline)
            }
        case .unset:
            Row(
                title: l("ayah.menu.reading-bookmark.title"),
                subtitle: .text(l("ayah.menu.reading-bookmark.save-here")),
                subtitlePlacement: .below,
                action: dataObject.actions.setReadingBookmark
            ) {
                ReadingBookmarkPin(style: .outline)
            }
        case .elsewhere(let location):
            Row(
                title: l("ayah.menu.reading-bookmark.title"),
                subtitle: location,
                subtitlePlacement: .below,
                action: dataObject.actions.setReadingBookmark
            ) {
                ReadingBookmarkPin(style: .outline)
            }
        case .current:
            Row(
                title: l("ayah.menu.reading-bookmark.title"),
                subtitle: .text(l("ayah.menu.reading-bookmark.saved-here")),
                subtitlePlacement: .below,
                action: dataObject.actions.removeReadingBookmark
            ) {
                ReadingBookmarkPin(style: .filled)
                    .foregroundColor(.red)
            }
        }
    }

    #endif

    private var noteIcon: some View {
        Group {
            if dataObject.usesSyncedNotesIcon {
                NoorSystemImage.note.image
            } else {
                NoorSystemImage.note.image
                    .foregroundColor(dataObject.highlightingColor.color)
            }
        }
    }
}

private struct Row<Symbol: View, Accessory: View>: View {
    enum SubtitlePlacement {
        case inline
        case below
    }

    // MARK: Lifecycle

    init(
        title: String,
        subtitle: MultipartText? = nil,
        subtitlePlacement: SubtitlePlacement = .inline,
        isEnabled: Bool = true,
        action: @Sendable @escaping () async -> Void,
        @ViewBuilder symbol: () -> Symbol
    ) where Accessory == EmptyView {
        self.symbol = symbol()
        accessory = EmptyView()
        self.title = title
        self.subtitle = subtitle
        self.subtitlePlacement = subtitlePlacement
        self.isEnabled = isEnabled
        self.action = action
        hasAccessory = false
    }

    init(
        title: String,
        subtitle: MultipartText? = nil,
        subtitlePlacement: SubtitlePlacement = .inline,
        isEnabled: Bool = true,
        action: @Sendable @escaping () async -> Void,
        @ViewBuilder symbol: () -> Symbol,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.symbol = symbol()
        self.accessory = accessory()
        self.title = title
        self.subtitle = subtitle
        self.subtitlePlacement = subtitlePlacement
        self.isEnabled = isEnabled
        self.action = action
        hasAccessory = true
    }

    // MARK: Internal

    let symbol: Symbol
    let accessory: Accessory
    let title: String
    let subtitle: MultipartText?
    let subtitlePlacement: SubtitlePlacement
    let isEnabled: Bool
    let action: @Sendable () async -> Void
    let hasAccessory: Bool
    @ScaledMetric var verticalPadding = 12

    var body: some View {
        AsyncButton(action: action) {
            HStack {
                ZStack {
                    HighlightPaletteIcon()
                        .hidden()
                    symbol
                        .foregroundColor(primaryColor)
                }
                label
                if hasAccessory {
                    Spacer(minLength: 12)
                    accessory
                }
            }
            .padding(.horizontal)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(BackgroundHighlightingStyle())
        .disabled(!isEnabled)
    }

    // MARK: Private

    private var primaryColor: Color {
        isEnabled ? .label : .tertiaryLabel
    }

    private var secondaryColor: Color {
        isEnabled ? .secondaryLabel : .tertiaryLabel
    }

    @ViewBuilder private var label: some View {
        switch subtitlePlacement {
        case .inline:
            HStack(spacing: 0) {
                Text(title)
                    .foregroundColor(primaryColor)
                if let subtitle {
                    Text(" ")
                    subtitle.view(ofSize: .footnote, allowsWrapping: false)
                        .foregroundColor(secondaryColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        case .below:
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .foregroundColor(primaryColor)
                if let subtitle {
                    subtitle.view(ofSize: .footnote, allowsWrapping: false)
                        .foregroundColor(secondaryColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        }
    }
}

private struct MenuGroup<Content: View>: View {
    // MARK: Internal

    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .background(Color.secondarySystemGroupedBackground)
    }
}

struct AyahMenuView_Previews: PreviewProvider {
    #if QURAN_SYNC
    static let actions = AyahMenuUI.Actions(
        play: {},
        repeatVerses: {},
        bookmark: {},
        addNote: {},
        deleteNote: {},
        showTranslation: {},
        copy: {},
        share: {},
        setReadingBookmark: {},
        removeReadingBookmark: {}
    )
    #else
    static let actions = AyahMenuUI.Actions(
        play: {},
        repeatVerses: {},
        bookmark: {},
        addNote: {},
        deleteNote: {},
        showTranslation: {},
        copy: {},
        share: {}
    )
    #endif

    static var previews: some View {
        Group {
            VStack {
                Spacer()
                AyahMenuView(dataObject: dataObject(
                    highlightingColor: .green,
                    state: .noted,
                    bookmarkTitle: "Save Ayah...",
                    bookmarkState: .highlighted(.green),
                    isTranslationView: true
                ))
                Spacer()
            }
            .background(Color.systemGroupedBackground)

            VStack {
                Spacer()
                AyahMenuView(dataObject: dataObject(
                    highlightingColor: .red,
                    state: .highlighted,
                    bookmarkTitle: "Save Ayahs...",
                    bookmarkState: .partiallyHighlighted,
                    isTranslationView: true
                ))
                Spacer()
            }
            .background(Color.systemGroupedBackground)
            .colorScheme(.dark)

            VStack {
                Spacer()
                AyahMenuView(dataObject: dataObject(
                    highlightingColor: .green,
                    state: .noHighlight,
                    bookmarkTitle: "Save Ayah...",
                    bookmarkState: .unhighlighted,
                    isTranslationView: true
                ))
                Spacer()
            }
            .background(Color.systemGroupedBackground)
            .environment(\.sizeCategory, .extraExtraExtraLarge)
        }
        .previewLayout(.fixed(width: 320, height: 470))
    }

    private static func dataObject(
        highlightingColor: HighlightColor,
        state: AyahMenuUI.NoteState,
        bookmarkTitle: String,
        bookmarkState: AyahMenuUI.BookmarkState,
        isTranslationView: Bool
    ) -> AyahMenuUI.DataObject {
        #if QURAN_SYNC
        AyahMenuUI.DataObject(
            highlightingColor: highlightingColor,
            state: state,
            bookmarkTitle: bookmarkTitle,
            bookmarkState: bookmarkState,
            playSubtitle: "To the end of Juz'",
            repeatSubtitle: "selected verses",
            actions: actions,
            isTranslationView: isTranslationView,
            readingBookmarkState: .unset
        )
        #else
        AyahMenuUI.DataObject(
            highlightingColor: highlightingColor,
            state: state,
            bookmarkTitle: bookmarkTitle,
            bookmarkState: bookmarkState,
            playSubtitle: "To the end of Juz'",
            repeatSubtitle: "selected verses",
            actions: actions,
            isTranslationView: isTranslationView
        )
        #endif
    }
}
