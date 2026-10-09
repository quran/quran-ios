#if QURAN_SYNC
import Localization
import NoorUI
import QuranAnnotations
import QuranKit
import SwiftUI
import UIx

@MainActor
struct ReadingBookmarkMenuRow: View {
    enum Action {
        case remove
        case moveHere
        case setHere
    }

    let item: ReadingBookmarkMenuViewModel.Item
    let target: PlacedReadingBookmark.Placement
    @Binding var name: String
    let isEnabled: Bool
    let editMode: EditMode
    let save: () async -> Bool
    let select: AsyncAction

    @FocusState private var isNameFocused: Bool

    @ScaledMetric private var verticalPadding = 12.0
    @ScaledMetric private var actionHorizontalPadding = 12.0
    @ScaledMetric private var actionVerticalPadding = 6.0

    var action: Action {
        switch item.placement {
        case .unplaced:
            .setHere
        case .ayah(let ayah):
            target == .ayah(ayah) ? .remove : .moveHere
        case .page(let page):
            target == .page(page) ? .remove : .moveHere
        }
    }

    var subtitle: MultipartText {
        switch action {
        case .remove:
            return .text(l("bookmarks.reading.saved-here"))
        case .setHere:
            return .text(l("bookmarks.reading.not-placed"))
        case .moveHere:
            switch item.placement {
            case .ayah(let ayah):
                return .localizedFormat("bookmarks.reading.location", "\(ayah: ayah, nameStyle: .text)")
            case .page(let page):
                return .localizedFormat("bookmarks.reading.location", .text(page.localizedName))
            case .unplaced:
                return .text(l("bookmarks.reading.not-placed"))
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if editMode.isEditing {
                editingRow
            } else {
                bookmarkRow
            }
        }
        .disabled(!isEnabled)
    }

    private var editingRow: some View {
        HStack {
            icon
            TextField(item.slot.displayName, text: $name)
                .focused($isNameFocused)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .submitLabel(.done)
                .onSubmit {
                    Task { @MainActor in
                        if await save() {
                            isNameFocused = false
                        }
                    }
                }
                .accessibilityLabel(lFormat("bookmarks.reading.name.accessibility-label", item.slot.displayName))
        }
        .padding(.horizontal)
        .padding(.vertical, verticalPadding)
    }

    private var bookmarkRow: some View {
        AsyncButton {
            await select()
        } label: {
            HStack {
                icon
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.displayName)
                        .fontWeight(.semibold)
                        .foregroundColor(isEnabled ? .label : .tertiaryLabel)
                    subtitle.view(ofSize: .footnote)
                        .foregroundColor(isEnabled ? .secondaryLabel : .tertiaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                actionLabel
                    .opacity(isEnabled ? 1 : 0.4)
            }
            .padding(.horizontal)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(BackgroundHighlightingStyle())
    }

    private var icon: some View {
        ReadingBookmarkIcon(style: item.placement == .unplaced ? .outline : .filled)
            .foregroundColor(isEnabled ? item.slot.swiftUIColor : .tertiaryLabel)
            .accessibilityHidden(true)
    }

    private var actionLabel: some View {
        Group {
            switch action {
            case .remove:
                Text(action.title)
                    .foregroundStyle(Color.systemRed)
            case .moveHere, .setHere:
                Text(action.title)
                    .foregroundStyle(Color.onAccent)
                    .padding(.horizontal, actionHorizontalPadding)
                    .padding(.vertical, actionVerticalPadding)
                    .background(Color.accentColor, in: Capsule())
            }
        }
        .font(.footnote.bold())
        .fixedSize()
    }
}

#Preview {
    ReadingBookmarkMenuRow(
        item: .init(
            slot: .teal,
            name: nil,
            placement: .page(Quran.hafsMadani1405.pages[0])
        ),
        target: .page(Quran.hafsMadani1405.pages[0]),
        name: .constant(""),
        isEnabled: true,
        editMode: .active,
        save: { true },
        select: {}
    )
}

private extension ReadingBookmarkMenuRow.Action {
    var title: String {
        switch self {
        case .remove:
            lAndroid("remove_button")
        case .moveHere:
            l("bookmarks.reading.move-here")
        case .setHere:
            l("bookmarks.reading.set-here")
        }
    }
}
#endif
