#if QURAN_SYNC
import NoorUI
import QuranAnnotations
import SwiftUI
import UIx

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

private struct ReadingBookmarkMenuContent: View {
    @Binding var error: Error?

    let items: [ReadingBookmarkMenuViewModel.Item]
    let start: AsyncAction
    let select: AsyncItemAction<ReadingBookmarkSlot>

    @ScaledMetric private var minimumWidth = 280.0
    @ScaledMetric private var verticalPadding = 12.0

    var body: some View {
        PreferredContentSizeMatchesScrollView {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        row(item)
                        Divider()
                    }
                    editBookmarksRow
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

    private func row(_ item: ReadingBookmarkMenuViewModel.Item) -> some View {
        AsyncButton {
            await select(item.slot)
        } label: {
            HStack(spacing: 14) {
                Image(uiImage: ReadingBookmarkPin.image(style: item.isCurrent ? .filled : .outline))
                    .foregroundColor(item.isEnabled ? item.slot.swiftUIColor : .tertiaryLabel)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.slot.displayName)
                        .foregroundColor(item.isEnabled ? .label : .tertiaryLabel)
                    item.subtitle.view(ofSize: .footnote, allowsWrapping: false)
                        .foregroundColor(item.isEnabled ? .secondaryLabel : .tertiaryLabel)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(BackgroundHighlightingStyle())
        .disabled(!item.isEnabled)
    }

    private var editBookmarksRow: some View {
        Button(action: {}) {
            HStack(spacing: 14) {
                Image(systemName: "pencil")
                    .foregroundColor(.label)
                    .frame(width: 24)
                Text("Edit reading bookmarks")
                    .foregroundColor(.label)
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(BackgroundHighlightingStyle())
    }
}

#Preview {
    ReadingBookmarkMenuContent(
        error: .constant(nil),
        items: ReadingBookmarkSlot.allCases.map { slot in
            ReadingBookmarkMenuViewModel.Item(
                slot: slot,
                subtitle: .text("Not placed — tap to set here"),
                isCurrent: false,
                isEnabled: true
            )
        },
        start: {},
        select: { _ in }
    )
}
#endif
