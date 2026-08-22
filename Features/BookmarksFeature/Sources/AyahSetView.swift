#if QURAN_SYNC
import Localization
import NoorUI
import QuranKit
import QuranLocalization
import SwiftUI
import UIx

@MainActor
struct AyahSetView: View {
    init(viewModel: AyahSetViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    @StateObject var viewModel: AyahSetViewModel

    var body: some View {
        AyahSetContentView(viewModel: viewModel)
            .task { await viewModel.start() }
            .renameAlert(viewModel: viewModel)
            .collectionDeleteConfirmation(
                isPresented: $viewModel.isPresentingDeleteConfirmation,
                delete: { await viewModel.deleteDataSource() }
            )
            .errorAlert(error: $viewModel.error)
            .environment(\.editMode, $viewModel.editMode)
    }
}

@MainActor
private struct AyahSetContentView: View {
    @ObservedObject var viewModel: AyahSetViewModel

    var body: some View {
        VStack {
            if viewModel.content.ayahs.isEmpty {
                emptyState
            } else {
                ayahList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.systemGroupedBackground)
    }

    private var ayahList: some View {
        NoorList {
            Section {
                NoorListRows(
                    viewModel.content.ayahs.map(SelfIdentifiable.init),
                    onDelete: { item in
                        { await viewModel.removeAyah(item.value) }
                    }
                ) { item in
                    ayahRow(item.value)
                }
            } footer: {
                Text(l("bookmarks.collections.ayahs.delete-hint"))
                    .font(.body)
                    .foregroundStyle(Color.tertiaryLabel)
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                    .textCase(nil)
            }
        }
    }

    private var emptyState: some View {
        NoorListEmptyState(
            title: lAndroid("bookmarks_list_empty"),
            text: emptyStateText,
            image: .bookmark,
            style: .prominent(
                imageColor: viewModel.content.highlightColor?.color ?? Color.appIdentity
            )
        )
    }

    private var emptyStateText: String {
        guard let highlightColor = viewModel.content.highlightColor else {
            return l("bookmarks.collections.ayahs.no-data.text")
        }
        return lFormat(
            "bookmarks.collections.ayahs.no-data.colored.text",
            highlightColor.localizedName.lowercased()
        )
    }

    private func ayahRow(_ ayah: AyahNumber) -> some View {
        NoorListItem(
            rightPretitle: quranText(ayah),
            title: "\(ayah: ayah) · \(ayah.page.localizedName)",
            titleColor: .secondaryLabel,
            action: .sync { viewModel.navigateTo(ayah) }
        )
        .accessibilityHint(l("bookmarks.collections.ayahs.open-hint"))
    }

    private func quranText(_ ayah: AyahNumber) -> MultipartText? {
        guard let text = viewModel.ayahTexts[ayah] else {
            return nil
        }
        return "\(quran: text, font: viewModel.reading.quranFont, lineLimit: 2)"
    }
}

private extension View {
    @MainActor
    func renameAlert(viewModel: AyahSetViewModel) -> some View {
        alert(
            l("bookmarks.collections.rename"),
            isPresented: Binding(
                get: { viewModel.isPresentingRename },
                set: { viewModel.isPresentingRename = $0 }
            )
        ) {
            TextField(
                l("bookmarks.collections.new.placeholder"),
                text: Binding(
                    get: { viewModel.pendingName },
                    set: { viewModel.pendingName = $0 }
                )
            )
            Button(lAndroid("cancel"), role: .cancel) {}
            Button(l("bookmarks.collections.rename")) {
                Task { await viewModel.renamePending() }
            }
        }
    }
}
#endif
