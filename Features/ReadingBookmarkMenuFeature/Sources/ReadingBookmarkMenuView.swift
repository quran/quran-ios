#if QURAN_SYNC
import NoorUI
import QuranAnnotations
import QuranKit
import SwiftUI
import UIx

@MainActor
struct ReadingBookmarkMenuView: View {
    // MARK: Lifecycle

    init(viewModel: ReadingBookmarkMenuViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Internal

    @StateObject var viewModel: ReadingBookmarkMenuViewModel

    var body: some View {
        ReadingBookmarkMenuContent(
            error: $viewModel.error,
            items: viewModel.items,
            start: { await viewModel.start() },
            select: { slot in await select(slot) }
        )
    }

    // MARK: Private

    @Environment(\.dismiss) private var dismiss
    @Environment(\.showToast) private var showToast

    private func select(_ slot: ReadingBookmarkSlot) async {
        guard let toast = await viewModel.select(slot) else {
            return
        }
        showToast?(toast)
        dismiss()
    }
}

@MainActor
private struct ReadingBookmarkMenuContent: View {
    @Binding var error: Error?

    let items: [ReadingBookmarkMenuViewModel.Item]
    let start: AsyncAction
    let select: AsyncItemAction<ReadingBookmarkSlot>

    @State private var editMode: EditMode = .inactive
    @State private var draftNames: [ReadingBookmarkSlot: String] = [:]

    @ScaledMetric private var minimumWidth = 320.0

    var body: some View {
        PreferredContentSizeMatchesScrollView {
            ScrollView {
                VStack(spacing: 0) {
                    header

                    ForEach(items) { item in
                        ReadingBookmarkMenuRow(
                            item: item,
                            title: displayName(for: item.slot),
                            name: Binding(
                                get: { draftNames[item.slot] ?? item.slot.displayName },
                                set: { draftNames[item.slot] = $0 }
                            ),
                            editMode: $editMode,
                            select: { await select(item.slot) }
                        )
                        if item.id != items.last?.id {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .frame(minWidth: minimumWidth)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .task {
            await start()
        }
        .errorAlert(error: $error)
        .onChange(of: editMode) { mode in
            if mode.isEditing {
                draftNames.removeAll()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Reading bookmarks")
                    .font(.headline.bold())
                    .foregroundStyle(Color.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                EditModeButton(editMode: $editMode)
                    .buttonStyle(.plain)
                    .disabled(items.isEmpty || items.contains { !$0.isEnabled })
            }
            .font(.subheadline.weight(.semibold))
            Divider()
            Text("Each pin marks one place — move it as you go")
                .font(.footnote)
                .foregroundStyle(Color.secondaryLabel)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
    }

    private func displayName(for slot: ReadingBookmarkSlot) -> String {
        let name = draftNames[slot]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? slot.displayName : name
    }
}

#Preview {
    ReadingBookmarkMenuContent(
        error: .constant(nil),
        items: [
            .init(
                slot: .coral,
                subtitle: .text("Saved here"),
                action: .remove,
                isCurrent: true,
                isEnabled: true
            ),
            .init(
                slot: .teal,
                subtitle: "at \(ayah: Quran.hafsMadani1405.suras[1].verses[29], decorationHidden: true)",
                action: .moveHere,
                isCurrent: false,
                isEnabled: true
            ),
            .init(
                slot: .indigo,
                subtitle: .text("Not placed yet"),
                action: .setHere,
                isCurrent: false,
                isEnabled: true
            ),
        ],
        start: {},
        select: { _ in }
    )
}

#endif
