//
//  AudioDownloadsViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-06-30.
//

import Analytics
import BatchDownloader
import Combine
import Crashing
import Foundation
import QuranAudio
import QuranAudioKit
import QuranKit
import ReadingService
import ReciterService
import SwiftUI
import Utilities
import VLogging

@MainActor
final class AudioDownloadsViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        analytics: AnalyticsLibrary,
        deleter: ReciterAudioDeleter,
        ayahsDownloader: QuranAudioDownloader,
        sizeInfoRetriever: ReciterSizeInfoRetriever,
        recitersRetriever: ReciterDataRetriever
    ) {
        quran = readingPreferences.reading.quran
        self.analytics = analytics
        self.deleter = deleter
        self.ayahsDownloader = ayahsDownloader
        self.sizeInfoRetriever = sizeInfoRetriever
        self.recitersRetriever = recitersRetriever

        let downloadsObserver = DownloadsObserver(
            extractKey: { [weak self] in self?.reciters.firstMatches($0) },
            showError: { [weak self] error in self?.error = error }
        )
        self.downloadsObserver = downloadsObserver

        downloadsObserver.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.progress = $0 }
            .store(in: &cancellables)

        Task {
            await start()
        }
    }

    // MARK: Internal

    @Published var editMode: EditMode = .inactive
    @Published var error: Error?

    var items: [AudioDownloadItem] {
        reciters.map { reciter in
            AudioDownloadItem(
                reciter: reciter,
                size: sizes[reciter],
                progress: progress[reciter].map { .downloading($0) } ?? .notDownloading
            )
        }
    }

    func deleteReciterFiles(_ reciter: Reciter) async {
        logger.info("Downloads: deleting reciter \(reciter.id)")
        analytics.deletingQuran(reciter: reciter)
        await cancelDownloading(reciter)
        do {
            try await deleter.deleteAudioFiles(for: reciter)
            sizes[reciter] = .zero(quran: quran)
        } catch {
            self.error = error
        }
    }

    func startDownloading(_ reciter: Reciter) {
        logger.info("Downloads: start downloading reciter \(reciter.id)")
        analytics.downloadingQuran(reciter: reciter)
        progress[reciter] = 0

        Task {
            do {
                // download the audio
                let response = try await ayahsDownloader.download(from: quran.firstVerse, to: quran.lastVerse, reciter: reciter)
                await downloadsObserver?.observe([response])
            } catch {
                progress.removeValue(forKey: reciter)
                crasher.recordError(error, reason: "Failed to start the reciter download")
                self.error = error
            }
        }
    }

    func cancelDownloading(_ reciter: Reciter) async {
        logger.info("Downloads: cancel downloading reciter \(reciter.id)")
        let download = downloadsObserver?.runningDownloads.firstMatches(reciter)
        await download?.cancel()
    }

    // MARK: Private

    private var quran: Quran
    private let analytics: AnalyticsLibrary
    private let readingPreferences = ReadingPreferences.shared
    private let deleter: ReciterAudioDeleter
    private let ayahsDownloader: QuranAudioDownloader
    private let sizeInfoRetriever: ReciterSizeInfoRetriever
    private let recitersRetriever: ReciterDataRetriever
    private var downloadsObserver: DownloadsObserver<Reciter>?
    private var cancellableTasks = Set<CancellableTask>()
    private var cancellables = Set<AnyCancellable>()

    @Published private var reciters: [Reciter] = []
    @Published private var sizes: [Reciter: AudioDownloadedSize] = [:]

    @Published private var progress: [Reciter: Double] = [:] {
        didSet {
            Task {
                let newKeys = Set(progress.keys)
                let oldKeys = Set(oldValue.keys)
                let diff = oldKeys.subtracting(newKeys).union(newKeys.subtracting(oldKeys))
                let intersection = oldKeys.intersection(newKeys)

                for reciter in diff {
                    await reloadDownloadedSize(of: reciter)
                }

                for reciter in intersection {
                    let oldProgress = oldValue[reciter]
                    let newProgress = progress[reciter]

                    // Reload size info if enough progress passed.
                    if enoughProgressPassedForReloadSizeInfo(oldProgress: oldProgress, newProgress: newProgress) {
                        await reloadDownloadedSize(of: reciter)
                    }
                }
            }
        }
    }

    private func start() async {
        let responses = await ayahsDownloader.runningAudioDownloads()
        await downloadsObserver?.observe(Set(responses))

        cancellableTasks.task {
            await self.observeReadingChanges()
        }
    }

    private func update(with quran: Quran) async {
        self.quran = quran

        sizes.removeAll()

        // get new data
        reciters = await recitersRetriever.getReciters()
        sizes = await sizeInfoRetriever.getDownloadedSizes(for: reciters, quran: quran)
    }

    private func enoughProgressPassedForReloadSizeInfo(oldProgress: Double?, newProgress: Double?) -> Bool {
        if let newProgress, let oldProgress {
            let scale: Double = 2000
            let oldValue = floor(oldProgress * scale)
            let newValue = floor(newProgress * scale)
            return newValue - oldValue > 0.9
        }
        return false
    }

    private func reloadDownloadedSize(of reciter: Reciter) async {
        sizes[reciter] = await sizeInfoRetriever.getDownloadedSize(for: reciter, quran: quran)
    }

    // MARK: - Observers

    private func observeReadingChanges() async {
        for await reading in readingPreferences.$reading.prepend(readingPreferences.reading).values() {
            await update(with: reading.quran)
        }
    }
}

private extension AnalyticsLibrary {
    func deletingQuran(reciter: Reciter) {
        logEvent("AudioDeletionReciterId", value: reciter.id.description)
        logEvent("AudioDeletionReciterName", value: reciter.nameKey)
    }

    func downloadingQuran(reciter: Reciter) {
        logEvent("QuranDownloadingReciterId", value: reciter.id.description)
        logEvent("QuranDownloadingReciterName", value: reciter.nameKey)
    }
}
