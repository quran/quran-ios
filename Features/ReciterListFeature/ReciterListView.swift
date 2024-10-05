//
//  ReciterListView.swift
//
//
//  Created by Mohamed Afifi on 2023-07-25.
//

import Localization
import NoorUI
import QuranAudio
import SwiftUI
import UIx
import VLogging

struct ReciterListView: View {
    @StateObject var viewModel: ReciterListViewModel

    var body: some View {
        ReciterListViewUI(
            standalone: viewModel.standalone,
            recentReciters: viewModel.recentReciters,
            downloadedReciters: viewModel.downloadedReciters,
            englishReciters: viewModel.englishReciters,
            arabicReciters: viewModel.arabicReciters,
            selectedReciter: viewModel.selectedReciter,
            start: { await viewModel.start() },
            selectAction: { viewModel.selectReciter($0) }
        )
    }
}

private struct ReciterListViewUI: View {
    // MARK: Internal

    @Environment(\.dismiss) var dismiss

    let standalone: Bool
    let recentReciters: [Reciter]
    let downloadedReciters: [Reciter]
    let englishReciters: [Reciter]
    let arabicReciters: [Reciter]

    let selectedReciter: Reciter?

    let start: AsyncAction
    let selectAction: ItemAction<Reciter>

    var body: some View {
        Group {
            if standalone {
                CocoaNavigationView {
                    content
                        .background(Color.blue)
                }
                .background(Color.yellow)
            } else {
                content
                    .background(Color.green)
            }
        }
        .background(Color.red)
    }

    // MARK: Private

    private var content: some View {
        NoorList {
            NoorSection(
                title: l("reciters.recent"),
                recentReciters,
                listItem: {
                    listItem($0, recent: true)
                }
            )

            NoorSection(
                title: l("reciters.downloaded"),
                downloadedReciters,
                listItem: {
                    listItem($0, recent: false)
                }
            )

            NoorSection(
                title: allTitle(languageCode: "en"),
                englishReciters,
                listItem: {
                    listItem($0, recent: false)
                }
            )

            NoorSection(
                title: allTitle(languageCode: "ar"),
                arabicReciters,
                listItem: {
                    listItem($0, recent: false)
                }
            )
        }
        .task(start)
        .navigationTitle(l("reciters.title"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    logger.info("Reciters: dismiss reciters list tapped")
                    dismiss()
                } label: {
                    Text(l("button.done"))
                        .font(.headline)
                }
            }
        }
    }

    private func allTitle(languageCode: String) -> String {
        if let language = Locale.fixedCurrentLocaleNumbers.localizedString(forLanguageCode: languageCode) {
            return l("reciters.all") + " (" + language.capitalized + ")"
        }
        return l("reciters.all")
    }

    private func listItem(_ reciter: Reciter, recent: Bool = false) -> some View {
        NoorListItem(
            image: recent ? .init(NoorSystemImage.lastPage) : nil,
            title: .text(reciter.localizedName),
            accessory: reciter == selectedReciter ? .image(.checkmark, color: .appIdentity) : nil
        ) {
            logger.info("Reciters: reciter selected \(reciter.id)")
            selectAction(reciter)
            dismiss()
        }
    }
}

struct ReciterListView_Previews: PreviewProvider {
    struct Preview: View {
        @State var selectedReciter: Reciter?

        var body: some View {
            ReciterListViewUI(
                standalone: true,
                recentReciters: [reciter(id: 1), reciter(id: 2)],
                downloadedReciters: [reciter(id: 1), reciter(id: 3), reciter(id: 10), reciter(id: 12)],
                englishReciters: (1 ... 9).map { reciter(id: $0) },
                arabicReciters: (10 ... 20).map { reciter(id: $0) },
                selectedReciter: selectedReciter,
                start: {},
                selectAction: { selectedReciter = $0 }
            )
        }

        func reciter(id: Int) -> Reciter {
            let name = "Reciter " + String(id)
            return Reciter(
                id: id,
                nameKey: name,
                directory: String(id),
                audioURL: URL(validURL: "http://example.com"),
                audioType: .gapless(databaseName: name),
                hasGaplessAlternative: false,
                category: .arabic
            )
        }
    }

    // MARK: Internal

    static var previews: some View {
        VStack {}
            .sheet(isPresented: .constant(true)) {
                Preview()
            }
    }
}
