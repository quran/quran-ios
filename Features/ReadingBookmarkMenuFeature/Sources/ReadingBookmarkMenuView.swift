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

    @ScaledMetric private var minimumWidth = 320.0
    @ScaledMetric private var verticalPadding = 12.0
    @ScaledMetric private var actionHorizontalPadding = 12.0
    @ScaledMetric private var actionVerticalPadding = 6.0

    var body: some View {
        PreferredContentSizeMatchesScrollView {
            ScrollView {
                VStack(spacing: 0) {
                    header

                    ForEach(items) { item in
                        row(item)
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Reading bookmarks")
                    .font(.headline.bold())
                    .foregroundStyle(Color.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                Button("Edit", action: {})
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
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

    private func row(_ item: ReadingBookmarkMenuViewModel.Item) -> some View {
        AsyncButton {
            await select(item.slot)
        } label: {
            HStack(spacing: 14) {
                ReadingBookmarkPin(style: .filled)
                    .foregroundColor(item.isEnabled ? item.slot.swiftUIColor : .tertiaryLabel)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.slot.displayName)
                        .fontWeight(.semibold)
                        .foregroundColor(item.isEnabled ? .label : .tertiaryLabel)
                    item.subtitle.view(ofSize: .footnote)
                        .foregroundColor(item.isEnabled ? .secondaryLabel : .tertiaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                actionLabel(item.action)
                    .opacity(item.isEnabled ? 1 : 0.4)
            }
            .padding(.horizontal)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(BackgroundHighlightingStyle())
        .disabled(!item.isEnabled)
    }

    private func actionLabel(_ action: ReadingBookmarkMenuViewModel.Item.Action) -> some View {
        Group {
            switch action {
            case .remove:
                Text(action.title)
                    .foregroundStyle(Color.systemRed)
            case .moveHere, .setHere:
                Text(action.title)
                    .foregroundStyle(action == .moveHere ? Color.white : Color.accentColor)
                    .padding(.horizontal, actionHorizontalPadding)
                    .padding(.vertical, actionVerticalPadding)
                    .background(
                        Color.accentColor.opacity(action == .moveHere ? 1 : 0.1),
                        in: Capsule()
                    )
            }
        }
        .font(.footnote.bold())
        .fixedSize()
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
