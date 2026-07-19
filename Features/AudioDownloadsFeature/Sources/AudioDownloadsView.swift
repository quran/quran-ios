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
        AudioDownloadsViewUI(
            editMode: $viewModel.editMode,
            error: $viewModel.error,
            items: viewModel.items.sorted(),
            start: { await viewModel.start() },
            downloadAction: { await viewModel.startDownloading($0.reciter) },
            cancelAction: { await viewModel.cancelDownloading($0.reciter) },
            deleteAction: { @Sendable item in await viewModel.deleteReciterFiles(item.reciter) }
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
    let deleteAction: AsyncItemAction<AudioDownloadItem>

    var body: some View {
        NoorList {
            AudioDownloadsSection(
                title: l("reciters.downloaded"),
                items: items.filter(\.canDelete),
                listItem: { item in
                    NoorListItem(
                        title: .text(item.reciter.localizedName),
                        subtitle: .init(text: item.size.formattedString(), location: .bottom),
                        accessory: accessory(item)
                    )
                },
                onDelete: { @Sendable in await deleteAction($0) }
            )

            AudioDownloadsSection(
                title: l("reciters.all"),
                items: items.filter { !$0.canDelete },
                listItem: { item in
                    NoorListItem(
                        title: .text(item.reciter.localizedName),
                        accessory: accessory(item)
                    )
                },
                onDelete: nil
            )
        }
        .task { await start() }
        .errorAlert(error: $error)
        .environment(\.editMode, $editMode)
    }

    func accessory(_ item: AudioDownloadItem) -> NoorListItem.Accessory? {
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

private struct AudioDownloadsSection<ListItem: View>: View {
    let title: String
    let items: [AudioDownloadItem]
    let listItem: (AudioDownloadItem) -> ListItem
    let onDelete: AsyncItemAction<AudioDownloadItem>?

    var body: some View {
        NoorSection(title: title, items) { item in
            listItem(item)
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
                Button {
                    withAnimation {
                        if editMode == .inactive {
                            editMode = .active
                        } else {
                            editMode = .inactive
                        }
                    }
                } label: {
                    Text(editMode == .inactive ? "Edit" : "Done")
                }

                AudioDownloadsViewUI(
                    editMode: $editMode,
                    error: $error,
                    items: items,
                    start: { },
                    downloadAction: { _ in },
                    cancelAction: { _ in },
                    deleteAction: { _ in }
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
