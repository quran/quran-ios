//
//  ReciterListViewModel.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/6/19.
//  Copyright © 2019 Quran.com. All rights reserved.
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
final class ReciterListViewModel {
    // MARK: Lifecycle

    init() {
    }

    // MARK: Internal

    weak var listener: ReciterListListener?

    @Published var reciters: [[Reciter]] = []
    @Published var selectedReciterId: Int?

    func start() async {
        logger.info("Reciters: loading reciters")

        let allReciters = await reciterRetreiver.getReciters()
        logger.info("Reciters: reciters loaded")
        let recentReciters = recentRecitersService.recentReciters(allReciters)
        let allDownloadedReciters = downloadedRecitersService.downloadedReciters(allReciters)
        let downloadedReciters = allDownloadedReciters.filter { !recentReciters.contains($0) }
        let englishReciters = allReciters.filter { $0.category != .arabic }
        let arabicReciters = allReciters.filter { $0.category == .arabic }
        reciters = [recentReciters, downloadedReciters, englishReciters, arabicReciters]
        selectedReciterId = preferences.lastSelectedReciterId
    }

    func onReciterItemTapped(_ reciter: Reciter) {
        logger.info("Reciters: reciter selected \(reciter.id)")
        listener?.onSelectedReciterChanged(to: reciter)
        listener?.dismissReciterList()
    }

    func onCancelButtonTapped() {
        logger.info("Reciters: dismiss reciters list tapped")
        listener?.dismissReciterList()
    }

    // MARK: Private

    private let reciterRetreiver = ReciterDataRetriever()
    private let recentRecitersService = RecentRecitersService()
    private let downloadedRecitersService = DownloadedRecitersService()
    private let preferences = ReciterPreferences.shared
}
