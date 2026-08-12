//
//  AudioDownloadsView.swift
//
//
//  Created by Mohamed Afifi on 2023-06-29.
//

import Localization
import NoorUI
import QuranAudio
import SwiftUI
import UIx

struct AudioDownloadsView: View {
    @StateObject var viewModel: AudioDownloadsViewModel

    var body: some View {
        let viewModel = viewModel

        AudioDownloadsViewUI(
            editMode: $viewModel.editMode,
            error: $viewModel.error,
            items: viewModel.items.sorted(),
            start: { [weak viewModel] in
                guard let viewModel else { return }
                await viewModel.start()
            },
            downloadAction: { [weak viewModel] item in
                guard let viewModel else { return }
                await viewModel.startDownloading(item.reciter)
            },
            cancelAction: { [weak viewModel] item in
                guard let viewModel else { return }
                await viewModel.cancelDownloading(item.reciter)
            },
            deleteAction: { @Sendable [weak viewModel] item in viewModel?.deleteReciterFiles(item.reciter) }
        )
    }
}

private struct AudioDownloadsViewUI: View {
    @Binding var editMode: EditMode
    @Binding var error: Error?
    let items: [AudioDownloadItem]
    let start: AsyncAction
    let downloadAction: AsyncItemAction<AudioDownloadItem>
    let cancelAction: AsyncItemAction<AudioDownloadItem>
    let deleteAction: ItemDeletionAction<AudioDownloadItem>

    var body: some View {
        let cancelAction = cancelAction
        let deleteAction = deleteAction
        let downloadAction = downloadAction
        let editMode = editMode

        NoorList {
            AudioDownloadsSection(
                title: l("reciters.downloaded"),
                items: items.filter(\.canDelete),
                listItem: { item in
                    NoorListItem(
                        title: .text(item.reciter.localizedName),
                        subtitle: .init(text: .text(item.size.formattedString()), location: .bottom),
                        accessory: Self.accessory(
                            item,
                            editMode: editMode,
                            downloadAction: downloadAction,
                            cancelAction: cancelAction
                        )
                    )
                },
                onDelete: { item in deleteAction(item) }
            )

            AudioDownloadsSection(
                title: l("reciters.all"),
                items: items.filter { !$0.canDelete },
                listItem: { item in
                    NoorListItem(
                        title: .text(item.reciter.localizedName),
                        accessory: Self.accessory(
                            item,
                            editMode: editMode,
                            downloadAction: downloadAction,
                            cancelAction: cancelAction
                        )
                    )
                },
                onDelete: nil
            )
        }
        .task { await start() }
        .errorAlert(error: $error)
        .environment(\.editMode, $editMode)
    }

    static func accessory(
        _ item: AudioDownloadItem,
        editMode: EditMode,
        downloadAction: @escaping AsyncItemAction<AudioDownloadItem>,
        cancelAction: @escaping AsyncItemAction<AudioDownloadItem>
    ) -> NoorListItem.Accessory? {
        if editMode == .active {
            return nil
        }

        switch item.progress {
        case .notDownloading:
            if item.isDownloaded {
                return nil
            } else {
                return .download(.download) { await downloadAction(item) }
            }
        case .downloading(let progress):
            let type = progress < 0.001 ? DownloadType.pending : .downloading(progress: progress)
            return .download(type) { await cancelAction(item) }
        }
    }
}

@MainActor
private struct AudioDownloadsSection<ListItem: View>: View {
    let title: String
    let items: [AudioDownloadItem]
    let listItemsByID: [AudioDownloadItem.ID: ListItem]
    let onDelete: ItemDeletionAction<AudioDownloadItem>?

    init(
        title: String,
        items: [AudioDownloadItem],
        listItem: (AudioDownloadItem) -> ListItem,
        onDelete: ItemDeletionAction<AudioDownloadItem>?
    ) {
        self.title = title
        self.items = items
        listItemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, listItem($0)) })
        self.onDelete = onDelete
    }

    var body: some View {
        let listItemsByID = listItemsByID

        NoorSection(title: title, items) { item in
            listItemsByID[item.id]
        }
        .onDelete(action: onDelete)
    }
}

struct AudioDownloadsView_Previews: PreviewProvider {
    struct Container: View {
        @State var editMode: EditMode = .inactive
        @State var error: Error? = nil

        @State var items: [AudioDownloadItem] = [
            AudioDownloadItem(
                reciter: reciter(1),
                size: nil,
                progress: .downloading(0.0001)
            ),
            AudioDownloadItem(
                reciter: reciter(2),
                size: .init(downloadedSizeInBytes: 1024, downloadedSuraCount: 10, surasCount: 114),
                progress: .notDownloading
            ),
            AudioDownloadItem(
                reciter: reciter(3),
                size: .init(downloadedSizeInBytes: 0, downloadedSuraCount: 10, surasCount: 114),
                progress: .notDownloading
            ),
            AudioDownloadItem(
                reciter: reciter(4),
                size: .init(downloadedSizeInBytes: 2000, downloadedSuraCount: 114, surasCount: 114),
                progress: .notDownloading
            ),
            AudioDownloadItem(
                reciter: reciter(5),
                size: .init(downloadedSizeInBytes: 1024, downloadedSuraCount: 114, surasCount: 114),
                progress: .downloading(0.5)
            ),
        ]

        var body: some View {
            VStack {
                EditModeButton(editMode: $editMode)

                AudioDownloadsViewUI(
                    editMode: $editMode,
                    error: $error,
                    items: items,
                    start: { },
                    downloadAction: { _ in },
                    cancelAction: { _ in },
                    deleteAction: { _ in nil }
                )
            }
        }

        static func reciter(_ id: Int) -> Reciter {
            Reciter(
                id: id,
                nameKey: "Reciter \(id)",
                directory: "",
                audioURL: URL(validURL: "quran.com"),
                audioType: .gapped,
                hasGaplessAlternative: false,
                category: .arabic
            )
        }
    }

    // MARK: Internal

    static var previews: some View {
        VStack {
            Container()
        }
    }
}
