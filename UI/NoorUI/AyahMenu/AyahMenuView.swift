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

    private var existingHighlightedColor: NoteColor? {
        switch dataObject.state {
        case .highlighted, .noted:
            return dataObject.highlightingColor
        case .noHighlight:
            return nil
        }
    }
}

private struct AyahMenuViewList: View {
    let dataObject: AyahMenuUI.DataObject
    let showHighlights: () -> Void

    var noteEditText: String {
        switch dataObject.state {
        case .noHighlight, .highlighted:
            return l("ayah.menu.add-note")
        case .noted:
            return l("ayah.menu.edit-note")
        }
    }

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
            Image(systemName: "text.bubble.fill")
                .foregroundColor(dataObject.highlightingColor.color)
        }
    }

    var addNote: some View {
        Row(title: l("ayah.menu.add-note"), action: dataObject.actions.addNote) {
            Image(systemName: "plus.bubble.fill")
                .foregroundColor(dataObject.highlightingColor.color)
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
                    Image(systemName: "play.fill")
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

                if dataObject.state == .noHighlight {
                    Row(
                        title: l("ayah.menu.highlight"),
                        action: { dataObject.actions.highlight(dataObject.highlightingColor) }
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
}

private struct Row<Symbol: View>: View {
    // MARK: Lifecycle

    init(
        title: String,
        subtitle: String? = nil,
        action: @escaping () -> Void,
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
    let action: () -> Void
    @ScaledMetric var verticalPadding = 12

    var body: some View {
        Button {
            action()
        }
        label: {
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
    @ScaledMetric var trailingPadding = 8
    @ScaledMetric var purpleOffset = 8
    @ScaledMetric var blueOffset = 4
    @ScaledMetric var radius = 1

    var body: some View {
        ZStack {
            IconCircle(color: .purple)
                .offset(x: purpleOffset)
            IconCircle(color: .blue)
                .offset(x: blueOffset)
            IconCircle(color: .green)
        }
        .compositingGroup()
        .shadow(color: Color.tertiarySystemGroupedBackground, radius: radius)
        .padding(.trailing, trailingPadding)
    }
}

private struct IconCircle: View {
    @ScaledMetric var minLength = 20

    var color: NoteColor

    var body: some View {
        ColoredCircle(color: color.color, selected: false, minLength: minLength)
    }
}

private struct NoteCircles: View {
    let selectedColor: NoteColor?
    let tapped: (NoteColor) -> Void

    var body: some View {
        HStack {
            ForEach(NoteColor.sortedColors, id: \.self) { color in
                Button(
                    action: { tapped(color) },
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
