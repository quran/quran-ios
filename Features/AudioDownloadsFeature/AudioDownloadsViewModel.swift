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
        recitersRetriever: ReciterDataRetriever,
        showError: @MainActor @escaping (Error) -> Void
    ) {
        quran = readingPreferences.reading.quran
        self.analytics = analytics
        self.deleter = deleter
        self.ayahsDownloader = ayahsDownloader
        self.sizeInfoRetriever = sizeInfoRetriever
        self.recitersRetriever = recitersRetriever
        self.showError = showError

        Task {
            await start()
        }
    }

    // MARK: Internal

    @Published var editMode: EditMode = .inactive

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
            showError(error)
        }
    }

    func startDownloading(_ reciter: Reciter) async {
        logger.info("Downloads: start downloading reciter \(reciter.id)")
        analytics.downloadingQuran(reciter: reciter)
        do {
            progress[reciter] = 0
            // download the audio
            let response = try await ayahsDownloader.download(from: quran.firstVerse, to: quran.lastVerse, reciter: reciter)
            await observe([response])
        } catch {
            progress.removeValue(forKey: reciter)
            crasher.recordError(error, reason: "Failed to start the reciter download")
            showError(error)
        }
    }

    func cancelDownloading(_ reciter: Reciter) async {
        logger.info("Downloads: cancel downloading reciter \(reciter.id)")
        let download = await runningDownload(of: reciter)
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
    private let showError: @MainActor (Error) -> Void

    private var cancellableTasks = Set<CancellableTask>()
    private var runningDownloads: Set<DownloadBatchResponse> = []

    @Published private var reciters: [Reciter] = []
    @Published private var sizes: [Reciter: AudioDownloadedSize] = [:]
    @Published private var progress: [Reciter: Double] = [:]

    private func start() async {
        let responses = await ayahsDownloader.runningAudioDownloads()
        await observe(Set(responses))

        cancellableTask {
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

    // MARK: - Progress

    private func downloadingProgress(_ response: DownloadBatchResponse?) async -> Double? {
        await response?.currentProgress.progress
    }

    private func progressUpdated(of batch: DownloadBatchResponse) async {
        // Ignore if it's not running (e.g. cancelled).
        guard runningDownloads.contains(batch) else {
            return
        }

        guard let reciter = await reciter(of: batch) else {
            logger.debug("Cannot find reciter for download \(batch)")
            return
        }

        let oldProgress = progress[reciter]
        let newProgress = await downloadingProgress(batch)
        progress[reciter] = newProgress

        // Reload size info if enough progress passed.
        if enoughProgressPassedForReloadSizeInfo(oldProgress: oldProgress, newProgress: newProgress) {
            await reloadDownloadedSize(of: reciter)
        }
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

    private func observe(_ downloads: Set<DownloadBatchResponse>) async {
        runningDownloads.formUnion(downloads)

        // Update progress initially
        for download in downloads {
            await progressUpdated(of: download)
        }

        for download in downloads {
            cancellableTask { [weak self] in
                for await _ in await download.progress {
                    await self?.progressUpdated(of: download)
                }
            }
            cancellableTask { [weak self] in
                do {
                    try await download.completion()
                } catch {
                    self?.showError(error)
                }
                guard let self else { return }
                runningDownloads.remove(download)
                if let reciter = await reciter(of: download) {
                    progress.removeValue(forKey: reciter)
                    await reloadDownloadedSize(of: reciter)
                }
            }
        }
    }

    private func runningDownload(of reciter: Reciter) async -> DownloadBatchResponse? {
        await runningDownloads.firstMatches(reciter)
    }

    private func reciter(of batch: DownloadBatchResponse) async -> Reciter? {
        await reciters.firstMatches(batch)
    }

    private func cancellableTask(_ operation: @escaping @MainActor @Sendable () async -> Void) {
        cancellableTasks.insert(
            Task {
                await operation()
            }.asCancellableTask()
        )
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
