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

struct ReciterListView: View {
    @StateObject var viewModel: ReciterListViewModel

    var body: some View {
        ReciterListViewUI(
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

    let recentReciters: [Reciter]
    let downloadedReciters: [Reciter]
    let englishReciters: [Reciter]
    let arabicReciters: [Reciter]

    let selectedReciter: Reciter?

    let start: AsyncAction
    let selectAction: ItemAction<Reciter>

    var body: some View {
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
    }

    // MARK: Private

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
            selectAction(reciter)
        }
    }
}

struct ReciterListView_Previews: PreviewProvider {
    struct Preview: View {
        @State var selectedReciter: Reciter?

        var body: some View {
            NavigationView {
                ReciterListViewUI(
                    recentReciters: [reciter(id: 1), reciter(id: 2)],
                    downloadedReciters: [reciter(id: 1), reciter(id: 3), reciter(id: 10), reciter(id: 12)],
                    englishReciters: (1 ... 9).map { reciter(id: $0) },
                    arabicReciters: (10 ... 20).map { reciter(id: $0) },
                    selectedReciter: selectedReciter,
                    start: {},
                    selectAction: { selectedReciter = $0 }
                )
                .navigationTitle("Reciters")
                .toolbar {
                    Button("Clear selection") {
                        selectedReciter = nil
                    }
                }
            }
        }

        func reciter(id: Int) -> Reciter {
            let name = "reciter" + String(id)
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
        VStack {
            Preview()
        }
    }
}
