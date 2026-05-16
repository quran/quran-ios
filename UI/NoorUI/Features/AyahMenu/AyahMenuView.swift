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

private enum MenuState {
    case list
    case highlights
}

public struct AyahMenuView: View {
    // MARK: Lifecycle

    public init(dataObject: AyahMenuUI.DataObject) {
        self.dataObject = dataObject
    }

    // MARK: Public

    public var body: some View {
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
            .transition(AnyTransition.scale(scale: 2.0).combined(with: .opacity))
        }
    }

    // MARK: Internal

    let dataObject: AyahMenuUI.DataObject

    // MARK: Private

    @State private var state: MenuState = .list

    private var existingHighlightedColor: HighlightColor? {
        switch dataObject.state {
        case .highlighted, .noted:
            return dataObject.highlightingColor
        case .noHighlight:
            return nil
        }
    }
}

private struct AyahMenuViewList: View {
    // MARK: Internal

    let dataObject: AyahMenuUI.DataObject
    let showHighlights: AsyncAction

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
            noteIcon(legacySystemName: "text.bubble.fill")
        }
    }

    var addNote: some View {
        Row(title: l("ayah.menu.add-note"), action: dataObject.actions.addNote) {
            noteIcon(legacySystemName: "plus.bubble.fill")
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
                    subtitle: dataObject.playSubtitle,
                    action: dataObject.actions.play
                ) {
                    NoorSystemImage.play.image
                }
                Divider()
                Row(
                    title: l("ayah.menu.repeat"),
                    subtitle: dataObject.repeatSubtitle,
                    action: dataObject.actions.repeatVerses
                ) {
                    Image(systemName: "repeat")
                }
                Divider()
            }

            MenuGroup {
                Divider()

                if dataObject.usesCollectionBookmarks {
                    Row(
                        title: dataObject.isCollectionBookmarked ? l("ayah-bookmark.remove-verse") : l("ayah-bookmark.save-verse"),
                        action: dataObject.actions.saveVerse
                    ) {
                        NoorSystemImage.bookmark.image
                    }
                    Divider()
                        .padding(.leading)
                } else {
                    if dataObject.state == .noHighlight {
                        Row(
                            title: l("ayah.menu.highlight"),
                            action: {
                                Task {
                                    await dataObject.actions.highlight(dataObject.highlightingColor)
                                }
                            }
                        ) {
                            IconCircle(color: dataObject.highlightingColor)
                        }
                        Divider()
                            .padding(.leading)
                    }
                    Row(
                        title: l("ayah.menu.highlight"),
                        subtitle: l("ayah.menu.highlight-select-color"),
                        action: showHighlights
                    ) {
                        IconCircles()
                    }
                    Divider()
                        .padding(.leading)
                }

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

    private func noteIcon(legacySystemName: String) -> some View {
        Group {
            if dataObject.usesSyncedNotesIcon {
                NoorSystemImage.note.image
            } else {
                Image(systemName: legacySystemName)
                    .foregroundColor(dataObject.highlightingColor.color)
            }
        }
    }
}

private struct Row<Symbol: View>: View {
    // MARK: Lifecycle

    init(
        title: String,
        subtitle: String? = nil,
        action: @Sendable @escaping () async -> Void,
        @ViewBuilder symbol: () -> Symbol
    ) {
        self.symbol = symbol()
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    // MARK: Internal

    let symbol: Symbol
    let title: String
    let subtitle: String?
    let action: @Sendable () async -> Void
    @ScaledMetric var verticalPadding = 12

    var body: some View {
        AsyncButton(action: action) {
            HStack {
                ZStack {
                    IconCircles()
                        .hidden()
                    symbol
                        .foregroundColor(Color.label)
                }
                HStack(spacing: 0) {
                    Text(title)
                        .foregroundColor(Color.label)
                    if let subtitle {
                        Group {
                            Text(" ")
                            Text(subtitle)
                        }
                        .font(.footnote)
                        .foregroundColor(.secondaryLabel)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(BackgroundHighlightingStyle())
    }
}

private struct MenuGroup<Content: View>: View {
    // MARK: Lifecycle

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    // MARK: Internal

    let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .background(Color.secondarySystemGroupedBackground)
    }
}

private struct IconCircles: View {
    var body: some View {
        HighlightPaletteIcon()
    }
}

private struct IconCircle: View {
    @ScaledMetric var minLength = 20

    var color: HighlightColor

    var body: some View {
        ColoredCircle(color: color.color, selected: false, minLength: minLength)
    }
}

private struct NoteCircles: View {
    let selectedColor: HighlightColor?
    let tapped: @Sendable (HighlightColor) async -> Void

    var body: some View {
        HStack {
            ForEach(HighlightColor.allCases, id: \.self) { color in
                AsyncButton(
                    action: { await tapped(color) },
                    label: { NoteCircle(color: color.color, selected: color == selectedColor) }
                )
                .shadow(color: Color.tertiarySystemGroupedBackground, radius: 1)
            }
        }
        .padding()
    }
}

struct AyahMenuView_Previews: PreviewProvider {
    static let actions = AyahMenuUI.Actions(
        play: {},
        repeatVerses: {},
        highlight: { _ in },
        saveVerse: {},
        addNote: {},
        deleteNote: {},
        showTranslation: {},
        copy: {},
        share: {}
    )

    static var previews: some View {
        Group {
            VStack {
                Spacer()
                AyahMenuView(dataObject: AyahMenuUI.DataObject(
                    highlightingColor: .green,
                    state: .noted,
                    playSubtitle: "To the end of Juz'",
                    repeatSubtitle: "selected verses",
                    actions: actions,
                    isTranslationView: true
                ))
                Spacer()
            }
            .background(Color.systemGroupedBackground)

            VStack {
                Spacer()
                AyahMenuView(dataObject: AyahMenuUI.DataObject(
                    highlightingColor: .red,
                    state: .highlighted,
                    playSubtitle: "To the end of Juz'",
                    repeatSubtitle: "selected verses",
                    actions: actions,
                    isTranslationView: true
                ))
                Spacer()
            }
            .background(Color.systemGroupedBackground)
            .colorScheme(.dark)

            VStack {
                Spacer()
                AyahMenuView(dataObject: AyahMenuUI.DataObject(
                    highlightingColor: .green,
                    state: .noHighlight,
                    playSubtitle: "To the end of Juz'",
                    repeatSubtitle: "selected verses",
                    actions: actions,
                    isTranslationView: true
                ))
                Spacer()
            }
            .background(Color.systemGroupedBackground)
            .environment(\.sizeCategory, .extraExtraExtraLarge)
        }
        .previewLayout(.fixed(width: 320, height: 470))
    }
}
