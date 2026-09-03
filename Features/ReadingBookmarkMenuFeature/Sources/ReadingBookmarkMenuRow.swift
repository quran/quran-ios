#if QURAN_SYNC
import NoorUI
import SwiftUI
import UIx

@MainActor
struct ReadingBookmarkMenuRow: View {
    let item: ReadingBookmarkMenuViewModel.Item
    let title: String
    @Binding var name: String
    @Binding var editMode: EditMode
    let select: AsyncAction

    @ScaledMetric private var verticalPadding = 12.0
    @ScaledMetric private var actionHorizontalPadding = 12.0
    @ScaledMetric private var actionVerticalPadding = 6.0

    var body: some View {
        VStack(spacing: 0) {
            if editMode.isEditing {
                editingRow
            } else {
                bookmarkRow
            }
        }
        .disabled(!item.isEnabled)
    }

    private var editingRow: some View {
        HStack {
            pin
            TextField(item.slot.displayName, text: $name)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .submitLabel(.done)
                .onSubmit { editMode = .inactive }
                .accessibilityLabel("\(item.slot.displayName) pin name")
        }
        .padding(.horizontal)
        .padding(.vertical, verticalPadding)
    }

    private var bookmarkRow: some View {
        AsyncButton {
            await select()
        } label: {
            HStack {
                pin
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .fontWeight(.semibold)
                        .foregroundColor(item.isEnabled ? .label : .tertiaryLabel)
                    item.subtitle.view(ofSize: .footnote)
                        .foregroundColor(item.isEnabled ? .secondaryLabel : .tertiaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                actionLabel
                    .opacity(item.isEnabled ? 1 : 0.4)
            }
            .padding(.horizontal)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(BackgroundHighlightingStyle())
    }

    private var pin: some View {
        ReadingBookmarkPin(style: .filled)
            .foregroundColor(item.isEnabled ? item.slot.swiftUIColor : .tertiaryLabel)
            .accessibilityHidden(true)
    }

    private var actionLabel: some View {
        Group {
            switch item.action {
            case .remove:
                Text(item.action.title)
                    .foregroundStyle(Color.systemRed)
            case .moveHere, .setHere:
                Text(item.action.title)
                    .foregroundStyle(item.action == .moveHere ? Color.white : Color.accentColor)
                    .padding(.horizontal, actionHorizontalPadding)
                    .padding(.vertical, actionVerticalPadding)
                    .background(
                        Color.accentColor.opacity(item.action == .moveHere ? 1 : 0.1),
                        in: Capsule()
                    )
            }
        }
        .font(.footnote.bold())
        .fixedSize()
    }
}

#Preview {
    ReadingBookmarkMenuRow(
        item: .init(
            slot: .coral,
            subtitle: .text("Saved here"),
            action: .remove,
            isCurrent: true,
            isEnabled: true
        ),
        title: "Coral",
        name: .constant("Coral"),
        editMode: .constant(.active),
        select: {}
    )
}

private extension ReadingBookmarkMenuViewModel.Item.Action {
    var title: String {
        switch self {
        case .remove:
            "Remove"
        case .moveHere:
            "Move here"
        case .setHere:
            "Set here"
        }
    }
}
#endif
