//
//  ReciterListViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-07-25.
//

import Combine
import QuranAudio
import ReciterService
import VLogging

@MainActor
public protocol ReciterListListener: AnyObject {
    func onSelectedReciterChanged(to reciter: Reciter)
}

@MainActor
final class ReciterListViewModel: ObservableObject {
    // MARK: Lifecycle

    init(standalone: Bool) {
        self.standalone = standalone
    }

    // MARK: Internal

    let standalone: Bool
    weak var listener: ReciterListListener?

    @Published var recentReciters: [Reciter] = []
    @Published var downloadedReciters: [Reciter] = []
    @Published var englishReciters: [Reciter] = []
    @Published var arabicReciters: [Reciter] = []

    @Published var selectedReciter: Reciter?

    func start() async {
        logger.info("Reciters: loading reciters")

        let allReciters = await reciterRetreiver.getReciters()
        logger.info("Reciters: reciters loaded")

        recentReciters = recentRecitersService.recentReciters(allReciters)
        downloadedReciters = downloadedRecitersService.downloadedReciters(allReciters)

        englishReciters = allReciters.filter { $0.category != .arabic }
        arabicReciters = allReciters.filter { $0.category == .arabic }

        let selectedReciterId = preferences.lastSelectedReciterId
        selectedReciter = allReciters.first { $0.id == selectedReciterId }
    }

    func selectReciter(_ reciter: Reciter) {
        listener?.onSelectedReciterChanged(to: reciter)
    }

    // MARK: Private

    private let reciterRetreiver = ReciterDataRetriever()
    private let recentRecitersService = RecentRecitersService()
    private let downloadedRecitersService = DownloadedRecitersService()
    private let preferences = ReciterPreferences.shared
}
