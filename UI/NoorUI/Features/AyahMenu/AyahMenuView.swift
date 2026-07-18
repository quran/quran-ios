//
//  AyahMenuView.swift
//  Quran
//
//  Created by Afifi, Mohamed on 7/10/21.
//  Copyright © 2021 Quran.com. All rights reserved.
//

import Localization
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
                Row(title: dataObject.bookmarkTitle, action: dataObject.actions.bookmark) {
                    NoorSystemImage.bookmark.image
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

private struct Row<Symbol: View, Accessory: View>: View {
    // MARK: Lifecycle

    init(
        title: String,
        subtitle: String? = nil,
        action: @Sendable @escaping () async -> Void,
        @ViewBuilder symbol: () -> Symbol
    ) where Accessory == EmptyView {
        self.symbol = symbol()
        accessory = EmptyView()
        self.title = title
        self.subtitle = subtitle
        self.action = action
        hasAccessory = false
    }

    init(
        title: String,
        subtitle: String? = nil,
        action: @Sendable @escaping () async -> Void,
        @ViewBuilder symbol: () -> Symbol,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.symbol = symbol()
        self.accessory = accessory()
        self.title = title
        self.subtitle = subtitle
        self.action = action
        hasAccessory = true
    }

    // MARK: Internal

    let symbol: Symbol
    let accessory: Accessory
    let title: String
    let subtitle: String?
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

    static var previews: some View {
        Group {
            VStack {
                Spacer()
                AyahMenuView(dataObject: AyahMenuUI.DataObject(
                    highlightingColor: .green,
                    state: .noted,
                    bookmarkTitle: "Bookmark Ayah",
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
                    bookmarkTitle: "Bookmark 3 Ayahs",
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
                    bookmarkTitle: "Bookmark Ayah",
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
