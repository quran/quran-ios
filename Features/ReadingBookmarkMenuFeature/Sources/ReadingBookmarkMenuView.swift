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
            draftNames: $viewModel.draftNames,
            editMode: viewModel.editModeBinding,
            items: viewModel.items,
            target: viewModel.target.placement,
            isEnabled: !viewModel.isMutating,
            start: { await viewModel.start() },
            saveNames: { await viewModel.saveNames(in: $0) },
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
    @Binding var draftNames: [ReadingBookmarkSlot: String]
    @Binding var editMode: EditMode

    let items: [ReadingBookmarkMenuViewModel.Item]
    let target: PlacedReadingBookmark.Placement
    let isEnabled: Bool
    let start: AsyncAction
    let saveNames: ([ReadingBookmarkSlot]) async -> Bool
    let select: AsyncItemAction<ReadingBookmarkSlot>

    @ScaledMetric private var minimumWidth = 320.0

    var body: some View {
        PreferredContentSizeMatchesScrollView {
            ScrollView {
                VStack(spacing: 0) {
                    header

                    ForEach(items) { item in
                        ReadingBookmarkMenuRow(
                            item: item,
                            target: target,
                            name: Binding(
                                get: { draftNames[item.slot] ?? item.name ?? "" },
                                set: { draftNames[item.slot] = $0 }
                            ),
                            isEnabled: isEnabled,
                            editMode: editMode,
                            save: { await saveNames([item.slot]) },
                            select: { await select(item.slot) }
                        )
                        if item.slot != items.last?.slot {
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
                    .disabled(items.isEmpty || !isEnabled)
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
}

#Preview {
    ReadingBookmarkMenuContent(
        error: .constant(nil),
        draftNames: .constant([:]),
        editMode: .constant(.inactive),
        items: [
            .init(
                slot: .coral,
                name: nil,
                placement: .page(Quran.hafsMadani1405.pages[0])
            ),
            .init(
                slot: .teal,
                name: nil,
                placement: .ayah(Quran.hafsMadani1405.suras[1].verses[29])
            ),
            .init(
                slot: .indigo,
                name: nil,
                placement: .unplaced
            ),
        ],
        target: .page(Quran.hafsMadani1405.pages[0]),
        isEnabled: true,
        start: {},
        saveNames: { _ in true },
        select: { _ in }
    )
}

#endif
