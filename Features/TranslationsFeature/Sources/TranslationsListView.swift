//
//  TranslationsListView.swift
//
//
//  Created by Mohamed Afifi on 2023-07-02.
//

import Localization
import NoorUI
import QuranText
import SwiftUI
import UIx
import Utilities

struct TranslationsListView: View {
    @StateObject var viewModel: TranslationsListViewModel

    var body: some View {
        let viewModel = viewModel

        TranslationsListViewUI(
            editMode: $viewModel.editMode,
            error: $viewModel.error,
            loading: viewModel.loading,
            selectedTranslations: viewModel.selectedTranslations,
            downloadedTranslations: viewModel.downloadedTranslations,
            availableTranslations: viewModel.availableTranslations,
            selectAction: { [weak viewModel] item in await viewModel?.selectTranslation(item) },
            deselectAction: { [weak viewModel] item in await viewModel?.deselectTranslation(item) },
            downloadAction: { [weak viewModel] item in await viewModel?.startDownloading(item) },
            cancelAction: { [weak viewModel] item in await viewModel?.cancelDownloading(item) },
            deleteAction: { [weak viewModel] item in viewModel?.deleteTranslation(item) },
            moveSelectedItemsAction: { [weak viewModel] in viewModel?.moveSelectedTranslations(at: $0, to: $1) },
            start: { [weak viewModel] in await viewModel?.start() },
            refresh: { [weak viewModel] in await viewModel?.refresh() }
        )
    }
}

private struct TranslationsListViewUI: View {
    @Binding var editMode: EditMode
    @Binding var error: Error?
    let loading: Bool

    let selectedTranslations: [TranslationItem]
    let downloadedTranslations: [TranslationItem]
    let availableTranslations: [TranslationItem]

    let selectAction: AsyncItemAction<TranslationItem>
    let deselectAction: AsyncItemAction<TranslationItem>

    let downloadAction: AsyncItemAction<TranslationItem>
    let cancelAction: AsyncItemAction<TranslationItem>

    let deleteAction: ItemDeletionAction<TranslationItem>
    let moveSelectedItemsAction: (IndexSet, Int) -> Void

    let start: @Sendable () async -> Void
    let refresh: @Sendable () async -> Void

    var body: some View {
        NoorList {
            if loading {
                LoadingView()
            }

            TranslationsListSection(
                title: l("translation.selectedTranslations"),
                items: selectedTranslations,
                listItem: { item in
                    listItem(item, downloaded: true, image: NoorSystemImage.checkmark_checked) {
                        await deselectAction(item)
                    }
                },
                onDelete: { item in deleteAction(item) },
                onMove: moveSelectedItemsAction
            )

            TranslationsListSection(
                title: lAndroid("downloaded_translations"),
                items: downloadedTranslations,
                listItem: { item in
                    listItem(item, downloaded: true, image: NoorSystemImage.checkmark_unchecked) {
                        await selectAction(item)
                    }
                },
                onDelete: { item in deleteAction(item) },
                onMove: nil
            )

            ForEach(availableTranslationsByLanguage, id: \.languageCode) { languageCode, translations in
                TranslationsListSection(
                    title: Locale.localizedLanguage(forCode: languageCode),
                    items: translations,
                    listItem: { item in
                        listItem(item, downloaded: false)
                    },
                    onDelete: nil,
                    onMove: nil
                )
            }
        }
        .refreshable { await refresh() }
        .task { await start() }
        .errorAlert(error: $error)
        .environment(\.editMode, $editMode)
    }

    var availableTranslationsByLanguage: [(languageCode: String, translations: [TranslationItem])] {
        let currentLanguageCode = Locale.current.languageCode
        let englishCode = "en"
        let arabicCode = "ar"

        let comparer = MultiPredicateComparer<String>(increasingOrderPredicates: [
            { lhs, _ in lhs == currentLanguageCode },
            { lhs, _ in lhs == arabicCode },
            { lhs, _ in lhs == englishCode },
            { lhs, rhs in lhs < rhs },
        ])

        let languageCodes = Set(availableTranslations.map(\.languageCode))
            .sorted { comparer.areInIncreasingOrder(lhs: $0, rhs: $1) }

        return languageCodes.map { languageCode in
            let translations = availableTranslations
                .filter { $0.info.languageCode == languageCode }
                .sorted { $0.info < $1.info }
            return (languageCode, translations)
        }
    }

    func accessory(_ item: TranslationItem, downloaded: Bool) -> NoorListItem.Accessory? {
        if editMode == .active {
            return nil
        }

        switch item.progress {
        case .notDownloading:
            if downloaded {
                return nil
            } else {
                return .download(.download) { await downloadAction(item) }
            }
        case .downloading(let progress):
            let type = progress < 0.001 ? DownloadType.pending : .downloading(progress: progress)
            return .download(type) { await cancelAction(item) }
        case .needsUpgrade:
            return .download(.download) { await downloadAction(item) }
        }
    }

    func listItem(
        _ item: TranslationItem,
        downloaded: Bool,
        image: NoorSystemImage? = nil,
        action: AsyncAction? = nil
    ) -> NoorListItem {
        let image = editMode == .active ? nil : image
        let action = editMode == .active ? nil : action
        return NoorListItem(
            image: image.map { .init($0) },
            heading: downloaded ? item.localizedLanguage : nil,
            title: .text(item.displayName),
            subtitle: subtitle(of: item.info),
            accessory: accessory(item, downloaded: downloaded),
            action: action.map(NoorListItem.TapAction.async)
        )
    }

    func subtitle(of translation: Translation) -> NoorListItem.Subtitle? {
        if let translatorDisplayName = translation.translatorDisplayName, !translatorDisplayName.isEmpty {
            return .init(
                label: .text(l("translation.translator")),
                text: .text(translatorDisplayName),
                location: .bottom
            )
        } else {
            return nil
        }
    }
}

@MainActor
private struct TranslationsListSection<ListItem: View>: View {
    let title: String?
    let items: [TranslationItem]
    let listItemsByID: [TranslationItem.ID: ListItem]
    let onDelete: ItemDeletionAction<TranslationItem>?
    let onMove: ((IndexSet, Int) -> Void)?

    init(
        title: String?,
        items: [TranslationItem],
        listItem: (TranslationItem) -> ListItem,
        onDelete: ItemDeletionAction<TranslationItem>?,
        onMove: ((IndexSet, Int) -> Void)?
    ) {
        self.title = title
        self.items = items
        listItemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, listItem($0)) })
        self.onDelete = onDelete
        self.onMove = onMove
    }

    var body: some View {
        let listItemsByID = listItemsByID

        NoorSection(title: title, items) { item in
            listItemsByID[item.id]
        }
        .onDelete(action: onDelete)
        .onMove(action: onMove)
    }
}

struct TranslationsListView_Previews: PreviewProvider {
    struct Container: View {
        @State var editMode: EditMode = .inactive
        @State var error: Error? = nil
        @State var loading = true

        @State var selected = [
            item(1, language: "ar", progress: .needsUpgrade),
            item(2, language: "en", progress: .notDownloading),
        ]

        @State var downloaded = [
            item(3, language: "am", progress: .notDownloading),
            item(4, language: "fr", progress: .notDownloading),
        ]

        @State var available = [
            item(5, language: "tr", progress: .notDownloading),
            item(6, language: "ur", progress: .downloading(0.1)),
            item(7, language: "vi", progress: .downloading(0)),
        ]

        var body: some View {
            VStack {
                EditModeButton(editMode: $editMode)

                TranslationsListViewUI(
                    editMode: $editMode,
                    error: $error,
                    loading: loading,
                    selectedTranslations: selected,
                    downloadedTranslations: downloaded,
                    availableTranslations: available,
                    selectAction: { item in
                        withAnimation {
                            downloaded.remove(at: downloaded.firstIndex(of: item)!)
                            selected.append(item)
                        }
                    },
                    deselectAction: { item in
                        withAnimation {
                            selected.remove(at: selected.firstIndex(of: item)!)
                            downloaded.append(item)
                        }
                    },
                    downloadAction: { _ in },
                    cancelAction: { _ in },
                    deleteAction: { item in
                        selected = selected.filter { item != $0 }
                        downloaded = downloaded.filter { item != $0 }
                        return {}
                    },
                    moveSelectedItemsAction: { source, destination in
                        selected.move(fromOffsets: source, toOffset: destination)
                    },
                    start: { @MainActor in
                        try! await Task.sleep(nanoseconds: 3_000_000_000)
                        loading = false
                    },
                    refresh: { try! await Task.sleep(nanoseconds: 3_000_000_000) }
                )
            }
        }

        static func item(
            _ id: Int,
            language: String,
            progress: TranslationItem.DownloadingProgress
        ) -> TranslationItem {
            TranslationItem(
                info: Translation(
                    id: id,
                    displayName: "Name \(id)",
                    translator: "Translator \(id)",
                    translatorForeign: nil,
                    fileURL: URL(validURL: "quran.com"),
                    fileName: "\(id).db",
                    languageCode: language,
                    version: 1
                ),
                progress: progress
            )
        }
    }

    // MARK: Internal

    static var previews: some View {
        VStack {
            Container()
                .accentColor(Color.red)
        }
    }
}
