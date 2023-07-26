//
//  ReciterListViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-07-25.
//

import Combine
import QuranAudio
import ReciterService
import Utilities
import VLogging

@MainActor
public protocol ReciterListListener: AnyObject {
    func onSelectedReciterChanged(to reciter: Reciter)
    func dismissReciterList()
}

@MainActor
final class ReciterListViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
    }

    // MARK: Internal

    weak var listener: ReciterListListener?

    @Published var recentReciters: [Reciter] = []
    @Published var downloadedReciters: [Reciter] = []
    @Published var englishReciters: [Reciter] = []
    @Published var arabicReciters: [Reciter] = []

    @Published var reciters: [[Reciter]] = []
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
        logger.info("Reciters: reciter selected \(reciter.id)")
        listener?.onSelectedReciterChanged(to: reciter)
        listener?.dismissReciterList()
    }

    func dismissRecitersList() {
        logger.info("Reciters: dismiss reciters list tapped")
        listener?.dismissReciterList()
    }

    // MARK: Private

    private let reciterRetreiver = ReciterDataRetriever()
    private let recentRecitersService = RecentRecitersService()
    private let downloadedRecitersService = DownloadedRecitersService()
    private let preferences = ReciterPreferences.shared
}
