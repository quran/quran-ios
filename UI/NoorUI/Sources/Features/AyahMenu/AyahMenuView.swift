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

#if !QURAN_SYNC
private enum MenuState {
    case list
    case highlights
}
#endif

public struct AyahMenuView: View {
    // MARK: Lifecycle

    public init(dataObject: AyahMenuUI.DataObject) {
        self.dataObject = dataObject
    }

    // MARK: Public

    public var body: some View {
        #if QURAN_SYNC
        ScrollView {
            AyahMenuViewList(dataObject: dataObject)
        }
        .preferredContentSizeMatchesScrollView()
        #else
        switch state {
        case .list:
            ScrollView {
                AyahMenuViewList(dataObject: dataObject) {
                    withAnimation {
                        state = .highlights
                    }
                }
            }
            .preferredContentSizeMatchesScrollView()
            .transition(.opacity)
        case .highlights:
            ScrollView {
                NoteCircles(selectedColor: existingHighlightedColor, tapped: dataObject.actions.highlight)
            }
            .preferredContentSizeMatchesScrollView()
            .transition(.scale(scale: 2).combined(with: .opacity))
        }
        #endif
    }

    // MARK: Internal

    let dataObject: AyahMenuUI.DataObject

    // MARK: Private

    #if !QURAN_SYNC
    @State private var state: MenuState = .list

    private var existingHighlightedColor: HighlightColor? {
        switch dataObject.state {
        case .highlighted, .noted:
            return dataObject.highlightingColor
        case .noHighlight:
            return nil
        }
    }
    #endif
}

private struct AyahMenuViewList: View {
    // MARK: Internal

    let dataObject: AyahMenuUI.DataObject
    #if !QURAN_SYNC
    let showHighlights: AsyncAction
    #endif

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

                #if QURAN_SYNC
                Row(title: dataObject.bookmarkTitle, action: dataObject.actions.bookmark) {
                    bookmarkIcon
                }
                #else
                if dataObject.state == .noHighlight {
                    Row(
                        title: l("ayah.menu.highlight"),
                        action: {
                            await dataObject.actions.highlight(dataObject.highlightingColor)
                        }
                    ) {
                        IconCircle(color: dataObject.highlightingColor)
                    }
                    Divider()
                        .padding(.leading)
                }
                Row(
                    title: l("ayah.menu.highlight"),
                    subtitle: .text(l("ayah.menu.highlight-select-color")),
                    action: showHighlights
                ) {
                    HighlightPaletteIcon()
                }
                #endif
                Divider()
                    .padding(.leading)

                switch dataObject.state {
                case .noHighlight, .highlighted:
                    addNote
                case .noted:
                    editNote
                }

                #if !QURAN_SYNC
                if dataObject.state != .noHighlight {
                    Divider()
                        .padding(.leading)

                    Row(title: noteDeleteText, action: dataObject.actions.deleteNote) {
                        Image(systemName: "trash")
                            .foregroundColor(Color.red)
                    }
                }
                #endif

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

    #if QURAN_SYNC
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
    #endif

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

#if !QURAN_SYNC
private struct IconCircle: View {
    @ScaledMetric private var minLength = 20.0

    let color: HighlightColor

    var body: some View {
        ColoredCircle(color: color.color, selected: false, minLength: minLength)
    }
}

private struct NoteCircles: View {
    let selectedColor: HighlightColor?
    let tapped: @Sendable (HighlightColor) async -> Void

    var body: some View {
        HStack {
            ForEach(HighlightColor.sortedColors, id: \.self) { color in
                AsyncButton(
                    action: { await tapped(color) },
                    label: { NoteCircle(color: color.color, selected: color == selectedColor) }
                )
                .shadow(color: Color.tertiarySystemGroupedBackground, radius: 1)
                .accessibilityLabel(color.localizedName)
                .accessibilityAddTraits(color == selectedColor ? .isSelected : [])
            }
        }
        .padding()
    }
}
#endif

#if QURAN_SYNC
private let previewActions = AyahMenuUI.Actions(
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
private let previewActions = AyahMenuUI.Actions(
    play: {},
    repeatVerses: {},
    highlight: { _ in },
    addNote: {},
    deleteNote: {},
    showTranslation: {},
    copy: {},
    share: {}
)
#endif

#Preview("Noted") {
    VStack {
        Spacer()
        AyahMenuView(dataObject: previewDataObject(
            highlightingColor: .green,
            state: .noted,
            isTranslationView: true
        ))
        Spacer()
    }
    .frame(width: 320, height: 470)
    .background(Color.systemGroupedBackground)
}

#Preview("Highlighted · Dark") {
    VStack {
        Spacer()
        AyahMenuView(dataObject: previewDataObject(
            highlightingColor: .red,
            state: .highlighted,
            isTranslationView: true
        ))
        Spacer()
    }
    .frame(width: 320, height: 470)
    .background(Color.systemGroupedBackground)
    .colorScheme(.dark)
}

#Preview("No Highlight · XXXL") {
    VStack {
        Spacer()
        AyahMenuView(dataObject: previewDataObject(
            highlightingColor: .green,
            state: .noHighlight,
            isTranslationView: true
        ))
        Spacer()
    }
    .frame(width: 320, height: 470)
    .background(Color.systemGroupedBackground)
    .environment(\.sizeCategory, .extraExtraExtraLarge)
}

#if !QURAN_SYNC
#Preview("Highlight Colors") {
    NoteCircles(selectedColor: .blue, tapped: { _ in })
        .background(Color.secondarySystemGroupedBackground)
}
#endif

private func previewDataObject(
    highlightingColor: HighlightColor,
    state: AyahMenuUI.NoteState,
    isTranslationView: Bool
) -> AyahMenuUI.DataObject {
    #if QURAN_SYNC
    let bookmarkState: AyahMenuUI.BookmarkState = switch state {
    case .noHighlight:
        .unhighlighted
    case .highlighted:
        .partiallyHighlighted
    case .noted:
        .highlighted(highlightingColor)
    }
    let bookmarkTitle = switch state {
    case .highlighted:
        "Save Ayahs..."
    case .noHighlight, .noted:
        "Save Ayah..."
    }
    return AyahMenuUI.DataObject(
        highlightingColor: highlightingColor,
        state: state,
        bookmarkTitle: bookmarkTitle,
        bookmarkState: bookmarkState,
        playSubtitle: "To the end of Juz'",
        repeatSubtitle: "selected verses",
        actions: previewActions,
        isTranslationView: isTranslationView,
        readingBookmarkState: .unset
    )
    #else
    return AyahMenuUI.DataObject(
        highlightingColor: highlightingColor,
        state: state,
        playSubtitle: "To the end of Juz'",
        repeatSubtitle: "selected verses",
        actions: previewActions,
        isTranslationView: isTranslationView
    )
    #endif
}
