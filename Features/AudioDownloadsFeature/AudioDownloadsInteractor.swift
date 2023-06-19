//
//  AudioDownloadsInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Analytics
import BatchDownloader
import Combine
import Crashing
import Foundation
import NoorUI
import QuranAudio
import QuranAudioKit
import QuranKit
import ReadingService
import ReciterService
import Utilities
import VLogging

@MainActor
protocol AudioDownloadsPresentable: AnyObject {
    func showErrorAlert(error: Error)
    func showActivityIndicator()
    func hideActivityIndicator()

    var downloads: [Reciter: AudioDownloadItem] { get set }
}

@MainActor
final class AudioDownloadsInteractor {
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
    }

    // MARK: Internal

    weak var presenter: AudioDownloadsPresentable?

    // MARK: - Start

    func start() async {
        let responses = await ayahsDownloader.runningAudioDownloads()
        await observe(Set(responses))

        cancellable = readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reading in
                Task {
                    await self?.update(with: reading.quran)
                }
            }
    }

    // Actions

    func deleteReciterFiles(_ reciter: Reciter) async {
        logger.info("Downloads: deleting reciter \(reciter.id)")
        analytics.deletingQuran(reciter: reciter)
        await cancelDownloading(reciter)
        do {
            try await deleter.deleteAudioFiles(for: reciter)
            recitersSizeInfo[reciter] = ReciterAudioDownload(
                reciter: reciter,
                downloadedSizeInBytes: 0,
                downloadedSuraCount: 0,
                surasCount: quran.suras.count
            )
        } catch {
            showError(error)
        }
    }

    func startDownloading(_ reciter: Reciter) async {
        logger.info("Downloads: start downloading reciter \(reciter.id)")
        analytics.downloadingQuran(reciter: reciter)
        do {
            // download the audio
            let response = try await ayahsDownloader.download(from: quran.firstVerse, to: quran.lastVerse, reciter: reciter)
            await observe([response])
        } catch {
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

    private var cancellable: AnyCancellable?

    private var quran: Quran
    private let analytics: AnalyticsLibrary
    private let readingPreferences = ReadingPreferences.shared
    private let deleter: ReciterAudioDeleter
    private let ayahsDownloader: QuranAudioDownloader
    private let sizeInfoRetriever: ReciterSizeInfoRetriever
    private let recitersRetriever: ReciterDataRetriever

    private var cancellableTasks = Set<CancellableTask>()

    private var names: [Reciter: String] = [:]

    private var reciters: [Reciter] = [] {
        didSet {
            Task {
                await self.dataChanged()
            }
        }
    }

    private var recitersSizeInfo: [Reciter: ReciterAudioDownload] = [:] {
        didSet {
            Task {
                await self.dataChanged()
            }
        }
    }

    private var runningDownloads: Set<DownloadBatchResponse> = [] {
        didSet {
            Task {
                await self.dataChanged()
            }
        }
    }

    private func update(with quran: Quran) async {
        self.quran = quran

        recitersSizeInfo.removeAll()

        // get new data
        presenter?.showActivityIndicator()
        reciters = await recitersRetriever.getReciters()
        await loadSizeInfo()
        presenter?.hideActivityIndicator()
    }

    private func loadSizeInfo() async {
        let audioSizes = await sizeInfoRetriever.getReciterAudioDownloads(for: reciters, quran: quran)
        recitersSizeInfo = audioSizes
    }

    // MARK: - Updates

    private func downloadingProgress(_ response: DownloadBatchResponse?) async -> AudioDownloadItem.DownloadingProgress {
        if let response {
            let progress = await Float(response.currentProgress.progress)
            return .downloading(progress)
        } else {
            return .notDownloading
        }
    }

    private func downloadItem(for reciter: Reciter) async -> AudioDownloadItem {
        let sizeInfo = recitersSizeInfo[reciter]
        let downloadingProgress = await downloadingProgress(runningDownload(of: reciter))
        let name = names[reciter] ?? reciter.localizedName
        if names[reciter] == nil {
            names[reciter] = name
        }

        let size = sizeInfo.map {
            AudioDownloadItem.Size(
                downloadedSizeInBytes: $0.downloadedSizeInBytes,
                downloadedSuraCount: $0.downloadedSuraCount,
                surasCount: $0.surasCount
            )
        }

        return AudioDownloadItem(
            reciter: reciter,
            name: name,
            size: size,
            downloading: downloadingProgress
        )
    }

    private func dataChanged() async {
        let downloads = await reciters.asyncMap { await downloadItem(for: $0) }

        var recitersDownloads: [Reciter: AudioDownloadItem] = [:]
        for download in downloads {
            recitersDownloads[download.reciter] = download
        }
        presenter?.downloads = recitersDownloads
    }

    private func progressUpdated(of batch: DownloadBatchResponse) async {
        guard let item = await reciter(of: batch) else {
            logger.debug("Cannot find reciter for download \(batch)")
            return
        }

        // Update progress bar.
        await dataChanged()

        // Reload size info if enough progress passed.
        let oldDownloadItem = presenter?.downloads[item]
        let newDownloadItem = await downloadItem(for: item)
        if enoughProgressPassedForReloadSizeInfo(oldItem: oldDownloadItem, newItem: newDownloadItem) {
            await reloadSizeData(for: item)
        }
    }

    private func enoughProgressPassedForReloadSizeInfo(oldItem: AudioDownloadItem?, newItem: AudioDownloadItem) -> Bool {
        if case let .downloading(newProgress) = newItem.downloading {
            if case let .downloading(oldProgress) = oldItem?.downloading {
                let scale: Float = 2000
                let oldValue = floor(oldProgress * scale)
                let newValue = floor(newProgress * scale)
                return newValue - oldValue > 0.9
            }
        }
        return false
    }

    private func reloadSizeData(for reciter: Reciter) async {
        let audio = await sizeInfoRetriever.getReciterAudioDownload(for: reciter, quran: quran)
        recitersSizeInfo[reciter] = audio
    }

    private func showError(_ error: Error) {
        presenter?.showErrorAlert(error: error)
    }

    // MARK: - Download observers

    private func observe(_ downloads: Set<DownloadBatchResponse>) async {
        runningDownloads.formUnion(downloads)

        for download in downloads {
            cancellableTasks.insert(
                Task { [weak self] in
                    for await _ in await download.progress {
                        await self?.progressUpdated(of: download)
                    }
                }.asCancellableTask()
            )
            cancellableTasks.insert(
                Task { [weak self] in
                    do {
                        try await download.completion()
                    } catch {
                        self?.showError(error)
                    }
                    self?.runningDownloads.remove(download)
                    if let reciter = await self?.reciter(of: download) {
                        await self?.reloadSizeData(for: reciter)
                    }
                }.asCancellableTask()
            )
        }
    }

    private func runningDownload(of reciter: Reciter) async -> DownloadBatchResponse? {
        await runningDownloads.firstMatches(reciter)
    }

    private func reciter(of batch: DownloadBatchResponse) async -> Reciter? {
        await reciters.firstMatches(batch)
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
