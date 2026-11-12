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
                    withAnimation(NoorAnimation.standard) {
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
        #if QURAN_SYNC
        Row(title: dataObject.notesTitle, action: dataObject.actions.addNote) {
            noteIcon
        }
        #else
        Row(title: l("ayah.menu.edit-note"), action: dataObject.actions.addNote) {
            noteIcon
        }
        #endif
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

                    Row(
                        title: noteDeleteText,
                        isDestructive: true,
                        action: dataObject.actions.deleteNote
                    ) {
                        Image(systemName: "xmark")
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
        .idealWidthUpToOffered()
    }

    // MARK: Private

    #if QURAN_SYNC
    @ViewBuilder private var bookmarkIcon: some View {
        switch dataObject.bookmarkState {
        case .unhighlighted:
            NoorSystemImage.star.image
        case .bookmarked:
            NoorSystemImage.starFilled.image
        case .partiallyHighlighted:
            HighlightPaletteIcon()
        case .highlighted(let color):
            IconCircle(color: color)
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
                action: dataObject.actions.showReadingBookmarkMenu
            ) {
                Image(uiImage: ReadingBookmarkIcon.image(style: .outline, badge: .ellipsis))
            }
        case let .available(bookmark, subtitle, showsNewBadge):
            Row(
                title: l("ayah.menu.reading-bookmark.title"),
                subtitle: .text(subtitle),
                subtitlePlacement: .below,
                action: dataObject.actions.showReadingBookmarkMenu,
                accessory: showsNewBadge
                    ? NoorTagView(NoorTag(title: l("ayah.menu.reading-bookmark.new"), tone: .accent), style: .filled)
                    : nil
            ) {
                Image(uiImage: ReadingBookmarkIcon.image(
                    style: bookmark == nil ? .outline : .filled,
                    badge: .ellipsis
                ))
                .foregroundColor(bookmark?.slot.swiftUIColor ?? .label)
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
        isDestructive: Bool = false,
        action: @Sendable @escaping () async -> Void,
        @ViewBuilder symbol: () -> Symbol
    ) where Accessory == EmptyView {
        self.symbol = symbol()
        accessory = nil
        self.title = title
        self.subtitle = subtitle
        self.subtitlePlacement = subtitlePlacement
        self.isEnabled = isEnabled
        self.isDestructive = isDestructive
        self.action = action
    }

    init(
        title: String,
        subtitle: MultipartText? = nil,
        subtitlePlacement: SubtitlePlacement = .inline,
        isEnabled: Bool = true,
        action: @Sendable @escaping () async -> Void,
        accessory: Accessory?,
        @ViewBuilder symbol: () -> Symbol
    ) {
        self.symbol = symbol()
        self.accessory = accessory
        self.title = title
        self.subtitle = subtitle
        self.subtitlePlacement = subtitlePlacement
        self.isEnabled = isEnabled
        isDestructive = false
        self.action = action
    }

    // MARK: Internal

    let symbol: Symbol
    let accessory: Accessory?
    let title: String
    let subtitle: MultipartText?
    let subtitlePlacement: SubtitlePlacement
    let isEnabled: Bool
    let isDestructive: Bool
    let action: @Sendable () async -> Void
    @ScaledMetric var verticalPadding = 12

    var body: some View {
        AsyncButton(action: action) {
            Group {
                if dynamicTypeSize.isAccessibilitySize, #available(iOS 16.0, *) {
                    // The symbol goes above the text, so the text gets the row's full width and words don't break.
                    VStack(alignment: .leading) {
                        coloredSymbol
                        stacked
                    }
                } else {
                    HStack {
                        ZStack {
                            HighlightPaletteIcon()
                                .hidden()
                            coloredSymbol
                        }
                        content
                    }
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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var coloredSymbol: some View {
        symbol
            .foregroundColor(primaryColor)
    }

    private var primaryColor: Color {
        if !isEnabled {
            return .tertiaryLabel
        }
        return isDestructive ? .red : .label
    }

    private var secondaryColor: Color {
        isEnabled ? .secondaryLabel : .tertiaryLabel
    }

    /// Where the row doesn't fit on one line, the subtitle and accessory move under the title and the text wraps.
    @ViewBuilder private var content: some View {
        if #available(iOS 16.0, *) {
            ViewThatFits(in: .horizontal) {
                oneLine
                stacked
            }
        } else {
            oneLine
        }
    }

    private var oneLine: some View {
        HStack {
            label
            if let accessory {
                Spacer(minLength: 12)
                accessory
            }
        }
    }

    private var stacked: some View {
        VStack(alignment: .leading) {
            titleOverSubtitle(wraps: true)
            if let accessory {
                accessory
            }
        }
        .fixedSize(horizontal: false, vertical: true)
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
            titleOverSubtitle(wraps: false)
        }
    }

    private func titleOverSubtitle(wraps: Bool) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .foregroundColor(primaryColor)
            if let subtitle {
                subtitle.view(ofSize: .footnote, allowsWrapping: wraps)
                    .foregroundColor(secondaryColor)
                    .lineLimit(wraps ? nil : 1)
                    .truncationMode(.tail)
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

private extension View {
    /// Takes the content's one-line width, so the popover hugs it, but no more than the width offered, so at
    /// large text sizes the popover keeps to the screen and the text wraps.
    @ViewBuilder
    func idealWidthUpToOffered() -> some View {
        if #available(iOS 16.0, *) {
            IdealWidthUpToOfferedLayout {
                self
            }
        } else {
            fixedSize(horizontal: true, vertical: false)
        }
    }
}

@available(iOS 16.0, *)
private struct IdealWidthUpToOfferedLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let subview = subviews.first else {
            return .zero
        }
        return subview.sizeThatFits(widthCapped(proposal, subview))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let subview = subviews.first else {
            return
        }
        let width = widthCapped(proposal, subview).width
        subview.place(at: bounds.origin, proposal: ProposedViewSize(width: width, height: bounds.height))
    }

    /// Below this shortfall, the offered width is the ideal one: the popover rounds the width it gives the menu to
    /// pixels, and a fraction of a point short would otherwise move a row's subtitle under its title.
    private let roundingTolerance: CGFloat = 1

    private func widthCapped(_ proposal: ProposedViewSize, _ subview: LayoutSubview) -> ProposedViewSize {
        let idealWidth = subview.sizeThatFits(ProposedViewSize(width: nil, height: proposal.height)).width
        let width = proposal.width.map { $0 + roundingTolerance >= idealWidth ? idealWidth : $0 } ?? idealWidth
        return ProposedViewSize(width: width, height: proposal.height)
    }
}

private struct IconCircle: View {
    @ScaledMetric private var minLength = 20.0

    let color: HighlightColor

    var body: some View {
        ColoredCircle(color: color.color, selected: false, minLength: minLength)
    }
}

#if !QURAN_SYNC
struct NoteCircles: View {
    // MARK: Internal

    let selectedColor: HighlightColor?
    let tapped: @Sendable (HighlightColor) async -> Void

    var body: some View {
        row {
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

    // MARK: Private

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Below accessibility sizes the circles stay on one row, and the popover widens to fit them if the menu was
    /// narrower. At accessibility sizes one row is wider than the screen, so the circles wrap to the menu's width.
    @ViewBuilder
    private func row(@ViewBuilder content: () -> some View) -> some View {
        if dynamicTypeSize.isAccessibilitySize, #available(iOS 16.0, *) {
            WrappingHStack(fitContentWidth: true) {
                content()
            }
        } else {
            HStack(content: content)
        }
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
    showReadingBookmarkMenu: {}
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
            highlightingColor: .pink,
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
        notesTitle: "Notes (3)",
        bookmarkState: bookmarkState,
        playSubtitle: "To the end of Juz'",
        repeatSubtitle: "selected verses",
        actions: previewActions,
        isTranslationView: isTranslationView,
        readingBookmarkState: .available(bookmark: nil, subtitle: "Set here", showsNewBadge: true)
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
