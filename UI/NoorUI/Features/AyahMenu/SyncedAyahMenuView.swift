import Localization
import QuranAnnotations
import SwiftUI
import UIx

private enum SyncedMenuState {
    case list
    case highlights
}

public struct SyncedAyahMenuView: View {
    // MARK: Lifecycle

    public init(dataObject: SyncedAyahMenuUI.DataObject) {
        self.dataObject = dataObject
    }

    // MARK: Public

    public var body: some View {
        switch state {
        case .list:
            ScrollView {
                SyncedAyahMenuViewList(dataObject: dataObject) {
                    withAnimation {
                        state = .highlights
                    }
                }
            }
            .preferredContentSizeMatchesScrollView()
            .transition(.opacity)
        case .highlights:
            ScrollView {
                SyncedHighlightCircles(selectedColor: existingHighlightedColor, tapped: dataObject.actions.highlight)
            }
            .preferredContentSizeMatchesScrollView()
            .transition(AnyTransition.scale(scale: 2.0).combined(with: .opacity))
        }
    }

    // MARK: Internal

    let dataObject: SyncedAyahMenuUI.DataObject

    // MARK: Private

    @State private var state: SyncedMenuState = .list

    private var existingHighlightedColor: HighlightColor? {
        dataObject.hasHighlight ? dataObject.highlightingColor : nil
    }
}

private struct SyncedAyahMenuViewList: View {
    let dataObject: SyncedAyahMenuUI.DataObject
    let showHighlights: AsyncAction

    var editNote: some View {
        SyncedRow(title: l("ayah.menu.edit-note"), action: dataObject.actions.addNote) {
            NoorSystemImage.note.image
                .foregroundColor(.primary)
        }
    }

    var addNote: some View {
        SyncedRow(title: l("ayah.menu.add-note"), action: dataObject.actions.addNote) {
            NoorSystemImage.note.image
                .foregroundColor(.primary)
        }
    }

    var translation: some View {
        SyncedMenuGroup {
            Divider()
            SyncedRow(title: l("menu.translation"), action: dataObject.actions.showTranslation) {
                Image(systemName: "globe")
            }
            Divider()
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            SyncedMenuGroup {
                SyncedRow(
                    title: lAndroid("play"),
                    subtitle: dataObject.playSubtitle,
                    action: dataObject.actions.play
                ) {
                    NoorSystemImage.play.image
                }
                Divider()
                SyncedRow(
                    title: l("ayah.menu.repeat"),
                    subtitle: dataObject.repeatSubtitle,
                    action: dataObject.actions.repeatVerses
                ) {
                    Image(systemName: "repeat")
                }
                Divider()
            }

            SyncedMenuGroup {
                Divider()

                if !dataObject.hasHighlight {
                    SyncedRow(
                        title: l("ayah.menu.highlight"),
                        action: {
                            Task {
                                await dataObject.actions.highlight(dataObject.highlightingColor)
                            }
                        }
                    ) {
                        SyncedIconCircle(color: dataObject.highlightingColor)
                    }
                    Divider()
                        .padding(.leading)
                }
                SyncedRow(
                    title: l("ayah.menu.highlight"),
                    subtitle: l("ayah.menu.highlight-select-color"),
                    action: showHighlights
                ) {
                    SyncedIconCircles()
                }
                Divider()
                    .padding(.leading)

                if dataObject.hasNoteText {
                    editNote
                } else {
                    addNote
                }

                if let deleteHighlight = dataObject.actions.deleteHighlight, dataObject.hasHighlight {
                    Divider()
                        .padding(.leading)

                    SyncedRow(title: l("ayah.menu.delete-highlight"), action: deleteHighlight) {
                        Image(systemName: "trash")
                            .foregroundColor(Color.red)
                    }
                }

                if let deleteNote = dataObject.actions.deleteNote, dataObject.hasNoteText {
                    Divider()
                        .padding(.leading)

                    SyncedRow(title: l("ayah.menu.delete-note"), action: deleteNote) {
                        Image(systemName: "trash")
                            .foregroundColor(Color.red)
                    }
                }

                Divider()
            }

            if !dataObject.isTranslationView {
                translation
            }

            SyncedMenuGroup {
                Divider()

                SyncedRow(title: l("ayah.menu.copy"), action: dataObject.actions.copy) {
                    Image(systemName: "doc.on.doc")
                }
                Divider()
                    .padding(.leading)
                SyncedRow(title: l("ayah.menu.share"), action: dataObject.actions.share) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct SyncedRow<Symbol: View>: View {
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
                    SyncedIconCircles()
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

private struct SyncedMenuGroup<Content: View>: View {
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

private struct SyncedIconCircles: View {
    @ScaledMetric var trailingPadding = 8
    @ScaledMetric var purpleOffset = 8
    @ScaledMetric var blueOffset = 4
    @ScaledMetric var radius = 1

    var body: some View {
        ZStack {
            SyncedIconCircle(color: .purple)
                .offset(x: purpleOffset)
            SyncedIconCircle(color: .blue)
                .offset(x: blueOffset)
            SyncedIconCircle(color: .green)
        }
        .compositingGroup()
        .shadow(color: Color.tertiarySystemGroupedBackground, radius: radius)
        .padding(.trailing, trailingPadding)
    }
}

private struct SyncedIconCircle: View {
    @ScaledMetric var minLength = 20

    var color: HighlightColor

    var body: some View {
        ColoredCircle(color: color.color, selected: false, minLength: minLength)
    }
}

private struct SyncedHighlightCircles: View {
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
            }
        }
        .padding()
    }
}

struct SyncedAyahMenuView_Previews: PreviewProvider {
    static let actions = SyncedAyahMenuUI.Actions(
        play: {},
        repeatVerses: {},
        highlight: { _ in },
        addNote: {},
        deleteHighlight: {},
        deleteNote: {},
        showTranslation: {},
        copy: {},
        share: {}
    )

    static var previews: some View {
        Group {
            VStack {
                Spacer()
                SyncedAyahMenuView(dataObject: SyncedAyahMenuUI.DataObject(
                    highlightingColor: .green,
                    hasHighlight: true,
                    hasNoteText: true,
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
                SyncedAyahMenuView(dataObject: SyncedAyahMenuUI.DataObject(
                    highlightingColor: .red,
                    hasHighlight: true,
                    hasNoteText: false,
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
                SyncedAyahMenuView(dataObject: SyncedAyahMenuUI.DataObject(
                    highlightingColor: .green,
                    hasHighlight: false,
                    hasNoteText: false,
                    playSubtitle: "To the end of Juz'",
                    repeatSubtitle: "selected verses",
                    actions: actions,
                    isTranslationView: false
                ))
                Spacer()
            }
            .background(Color.systemGroupedBackground)
        }
        .previewLayout(.sizeThatFits)
    }
}
