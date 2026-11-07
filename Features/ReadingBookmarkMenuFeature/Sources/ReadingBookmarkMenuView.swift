#if QURAN_SYNC
import Localization
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
            isFirstRun: viewModel.isFirstRun,
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
    let isFirstRun: Bool
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
                            isFirstRun: isFirstRun,
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
                Text(l("bookmarks.reading.title"))
                    .font(.headline.bold())
                    .foregroundStyle(Color.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                if !isFirstRun {
                    EditModeButton(editMode: $editMode)
                        .buttonStyle(.plain)
                        .disabled(items.isEmpty || !isEnabled)
                }
            }
            .font(.subheadline.weight(.semibold))
            Divider()
            // Waits for the bookmarks so the explanation doesn't switch to the first-run copy after it appears.
            if !items.isEmpty {
                if isFirstRun {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l("bookmarks.reading.first-run.title"))
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.label)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        description(l("bookmarks.reading.first-run.description"))
                    }
                    // A zero ideal width lets the rows set the popover's width; the copy wraps within it.
                    .frame(idealWidth: 0, maxWidth: .infinity, alignment: .leading)
                } else {
                    description(l("bookmarks.reading.description"))
                }
            }
        }
        .padding()
    }

    private func description(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(Color.secondaryLabel)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    ReadingBookmarkMenuContent(
        error: .constant(nil),
        draftNames: .constant([:]),
        editMode: .constant(.inactive),
        items: [
            .init(
                slot: .teal,
                name: nil,
                placement: .page(Quran.hafsMadani1405.pages[0])
            ),
            .init(
                slot: .orange,
                name: nil,
                placement: .ayah(Quran.hafsMadani1405.suras[1].verses[29])
            ),
            .init(
                slot: .red,
                name: nil,
                placement: .unplaced
            ),
        ],
        target: .page(Quran.hafsMadani1405.pages[0]),
        isFirstRun: false,
        isEnabled: true,
        start: {},
        saveNames: { _ in true },
        select: { _ in }
    )
}

#Preview("First run") {
    ReadingBookmarkMenuContent(
        error: .constant(nil),
        draftNames: .constant([:]),
        editMode: .constant(.inactive),
        items: ReadingBookmarkSlot.allCases.map { .init(slot: $0, name: nil, placement: .unplaced) },
        target: .page(Quran.hafsMadani1405.pages[0]),
        isFirstRun: true,
        isEnabled: true,
        start: {},
        saveNames: { _ in true },
        select: { _ in }
    )
}

#endif
