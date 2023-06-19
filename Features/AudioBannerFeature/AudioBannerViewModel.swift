//
//  AudioBannerViewModel.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AdvancedAudioOptionsFeature
import Analytics
import BatchDownloader
import Crashing
import Foundation
import NoorUI
import QueuePlayer
import QuranAudio
import QuranAudioKit
import QuranKit
import ReciterService
import UIKit
import Utilities
import VLogging

@MainActor
public protocol AudioBannerListener: AnyObject {
    var visiblePages: [Page] { get }
    func highlightReadingAyah(_ ayah: AyahNumber?)
}

enum PlaybackState {
    case playing
    case paused
    case stopped
    case downloading(progress: Float)
}

struct AudioBannerViewModelInternalActions {
    let showError: (Error) -> Void
    let playingStarted: () -> Void
    let willStartDownloading: () -> Void
}

@MainActor
public final class AudioBannerViewModel: RemoteCommandsHandlerDelegate {
    typealias AudioRange = (start: AyahNumber, end: AyahNumber)

    // MARK: Lifecycle

    init(
        analytics: AnalyticsLibrary,
        reciterRetreiver: ReciterDataRetriever,
        recentRecitersService: RecentRecitersService,
        audioPlayer: QuranAudioPlayer,
        downloader: QuranAudioDownloader,
        remoteCommandsHandler: RemoteCommandsHandler
    ) {
        self.analytics = analytics
        self.reciterRetreiver = reciterRetreiver
        self.recentRecitersService = recentRecitersService
        self.audioPlayer = audioPlayer
        self.downloader = downloader
        self.remoteCommandsHandler = remoteCommandsHandler

        let actions = QuranAudioPlayerActions(
            playbackEnded: { [weak self] in self?.playbackEnded() },
            playbackPaused: { [weak self] in self?.playbackPaused() },
            playbackResumed: { [weak self] in self?.playbackResumed() },
            playing: { [weak self] in self?.playing(ayah: $0) }
        )
        audioPlayer.setActions(actions)

        remoteCommandsHandler.delegate = self
    }

    deinit {
        remoteCommandsHandler.stopListening()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Public

    public func play(from: AyahNumber, to: AyahNumber?, repeatVerses: Bool) {
        logger.info("AudioBanner: playing from \(from) to \(String(describing: to))")
        analytics.playFrom(menu: true)
        play(from: from, to: to, verseRuns: .one, listRuns: repeatVerses ? .indefinite : .one)
    }

    // MARK: Internal

    weak var listener: AudioBannerListener?
    var internalActions: AudioBannerViewModelInternalActions?

    var audioRange: AudioRange?

    @Published var playingState: PlaybackState = .stopped

    var advancedAudioOptions: AdvancedAudioOptions? {
        guard let audioRange, let selectedReciter else {
            return nil
        }
        return AdvancedAudioOptions(
            reciter: selectedReciter,
            start: audioRange.start,
            end: audioRange.end,
            verseRuns: verseRuns,
            listRuns: listRuns
        )
    }

    var selectedReciter: Reciter? {
        reciters.first { $0.id == preferences.lastSelectedReciterId }
    }

    func start() async {
        remoteCommandsHandler.startListeningToPlayCommand()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        reciters = await reciterRetreiver.getReciters()
        logger.info("AudioBanner: reciters loaded")

        let runningDownloads = await downloader.runningAudioDownloads()
        logger.info("AudioBanner: loaded runningAudioDownloads count: \(runningDownloads.count)")

        if runningDownloads.isEmpty {
            playingState = .stopped
        } else {
            await observeProgress(runningDownloads)
            await observeCompletion(runningDownloads)
        }
    }

    // MARK: - Advanced Options

    func updateAudioOptions(to newOptions: AdvancedAudioOptions) {
        logger.info("AudioBanner: playing advanced audio options \(newOptions)")
        selectReciter(newOptions.reciter)
        play(from: newOptions.start, to: newOptions.end, verseRuns: newOptions.verseRuns, listRuns: newOptions.listRuns)
    }

    func onSelectedReciterChanged(to reciter: Reciter) {
        logger.info("AudioBanner: select reciter")
        selectReciter(reciter)
        playingState = .stopped
    }

    // MARK: - Remote Commands

    func onPlayCommandFired() {
        logger.info("AudioBanner: play command fired. State: \(playingState)")
        switch playingState {
        case .stopped: playStartingCurrentPage()
        case .paused, .playing: resume()
        case .downloading: break
        }
    }

    func onPauseCommandFired() {
        logger.info("AudioBanner: pause command fired. State: \(playingState)")
        pause()
    }

    func onTogglePlayPauseCommandFired() {
        logger.info("AudioBanner: toggle play/pause command fired. State: \(playingState)")
        togglePlayPause()
    }

    func onStepForwardCommandFired() {
        logger.info("AudioBanner: step forward command fired. State: \(playingState)")
        stepForward()
    }

    func onStepBackwardCommandFire() {
        logger.info("AudioBanner: step backward command fired. State: \(playingState)")
        stepBackward()
    }

    // MARK: - Presenter Listener

    func onPlayTapped() {
        logger.info("AudioBanner: play button tapped. State: \(playingState)")
        playStartingCurrentPage()
    }

    func onPauseResumeTapped() {
        logger.info("AudioBanner: pause/resume button tapped. State: \(playingState)")
        togglePlayPause()
    }

    func onStopTapped() {
        logger.info("AudioBanner: stop button tapped. State: \(playingState)")
        stop()
    }

    func onForwardTapped() {
        logger.info("AudioBanner: step forward button tapped. State: \(playingState)")
        stepForward()
    }

    func onBackwardTapped() {
        logger.info("AudioBanner: step backward button tapped. State: \(playingState)")
        stepBackward()
    }

    func cancelDownload() async {
        logger.info("AudioBanner: cancel download tapped. State: \(playingState)")
        await downloader.cancelAllAudioDownloads()
        playbackEnded()
    }

    func showReciterView() {
        logger.info("AudioBanner: show reciter view")
        if let selectedReciter {
            crasher.setValue(selectedReciter.id, forKey: .reciterId)
        }
        listener?.highlightReadingAyah(nil)

        remoteCommandsHandler.stopListening()
        remoteCommandsHandler.startListeningToPlayCommand()
    }

    // MARK: Private

    private let analytics: AnalyticsLibrary
    private let reciterRetreiver: ReciterDataRetriever
    private let recentRecitersService: RecentRecitersService
    private let preferences = ReciterPreferences.shared
    private let lastAyahFinder: LastAyahFinder = PreferencesLastAyahFinder.shared
    private let audioPlayer: QuranAudioPlayer
    private let downloader: QuranAudioDownloader
    private let remoteCommandsHandler: RemoteCommandsHandler

    private var verseRuns: Runs = .one
    private var listRuns: Runs = .one
    private var reciters: [Reciter] = []
    private var cancellableTasks: Set<CancellableTask> = []

    @objc
    private func applicationDidBecomeActive() {
        // re-assign playingState to update UI
        let tempPlayingState = playingState
        playingState = tempPlayingState
    }

    // MARK: - Reciter

    private func selectReciter(_ reciter: Reciter) {
        preferences.lastSelectedReciterId = reciter.id
    }

    // MARK: - Playback Controls

    private func playStartingCurrentPage() {
        guard let currentPage = listener?.visiblePages.min() else { return }
        logger.info("AudioBanner: Play starting page \(currentPage)")

        // start downloading & playing
        analytics.playFrom(menu: false)
        play(from: currentPage.firstVerse, to: nil, verseRuns: .one, listRuns: .one)
    }

    private func play(from: AyahNumber, to: AyahNumber?, verseRuns: Runs, listRuns: Runs) {
        guard let selectedReciter else {
            return
        }
        audioPlayer.stopAudio()
        let end = to ?? lastAyahFinder.findLastAyah(startAyah: from)
        audioRange = (start: from, end: end)
        self.verseRuns = verseRuns
        self.listRuns = listRuns

        recentRecitersService.updateRecentRecitersList(selectedReciter)

        Task {
            do {
                if await !downloader.downloaded(reciter: selectedReciter, from: from, to: end) {
                    startDownloading()
                    let download = try await downloader.download(from: from, to: end, reciter: selectedReciter)
                    await observeProgress([download])

                    try await download.completion()
                }

                try await audioPlayer.play(reciter: selectedReciter, from: from, to: end, verseRuns: verseRuns, listRuns: listRuns)
                playingStarted()
            } catch {
                playbackFailed(error)
            }
        }
    }

    private func togglePlayPause() {
        switch playingState {
        case .playing: pause()
        case .paused: resume()
        default:
            logger.error("Invalid playingState \(playingState) found while trying to pause/resume playback")
        }
    }

    private func pause() {
        playingState = .paused
        audioPlayer.pauseAudio()
    }

    private func resume() {
        playingState = .playing
        audioPlayer.resumeAudio()
    }

    private func stepForward() {
        audioPlayer.stepForward()
    }

    private func stepBackward() {
        audioPlayer.stepBackward()
    }

    private func stop() {
        audioRange = nil
        audioPlayer.stopAudio()
    }

    // MARK: - Downloading

    private func observeProgress(_ downloads: [DownloadBatchResponse]) async {
        for response in downloads {
            cancellableTasks.insert(
                Task { [weak self] in
                    for await _ in await response.progress {
                        await self?.updateDownloadProgress()
                    }
                }.asCancellableTask()
            )
        }
        await updateDownloadProgress()
    }

    private func observeCompletion(_ downloads: [DownloadBatchResponse]) async {
        cancellableTasks.insert(
            Task { [weak self] in
                await withTaskGroup(of: Void.self) { group in
                    for download in downloads {
                        group.addTask {
                            try? await download.completion()
                        }
                    }
                }
                self?.playbackEnded()
            }.asCancellableTask()
        )
    }

    // MARK: - Audio Interactor Delegate

    private func playbackPaused() {
        logger.info("AudioBanner: playback paused")
        updatePlayingState(to: .paused)
    }

    private func playbackResumed() {
        logger.info("AudioBanner: playback resumed")
        playingState = .playing
    }

    private func playing(ayah: AyahNumber) {
        logger.info("AudioBanner: playing verse \(ayah)")
        crasher.setValue(ayah, forKey: .playingAyah)
        listener?.highlightReadingAyah(ayah)
    }

    // MARK: - State changes

    private func updatePlayingState(to playingState: PlaybackState) {
        self.playingState = playingState
    }

    private func playbackEnded() {
        logger.info("AudioBanner: onPlaybackOrDownloadingCompleted")

        crasher.setValue(nil, forKey: .playingAyah)
        crasher.setValue(false, forKey: .downloadingQuran)
        playingState = .stopped
    }

    private func startDownloading() {
        logger.info("AudioBanner: will start downloading")
        crasher.setValue(true, forKey: .downloadingQuran)
        playingState = .downloading(progress: 0)
        internalActions?.willStartDownloading()
    }

    private func updateDownloadProgress() async {
        let downloads = await downloader.runningAudioDownloads()
        let progress = await downloads.asyncMap { await $0.currentProgress.progress }.reduce(0, +)
        playingState = .downloading(progress: Float(progress) / Float(downloads.count))
    }

    private func playingStarted() {
        logger.info("AudioBanner: playing started")
        cancellableTasks = []
        crasher.setValue(false, forKey: .downloadingQuran)
        remoteCommandsHandler.startListening()
        playingState = .playing
        internalActions?.playingStarted()
    }

    private func playbackFailed(_ error: Error) {
        logger.info("AudioBanner: failed to playing audio. \(error)")
        internalActions?.showError(error)
        playbackEnded()
    }
}

private extension AnalyticsLibrary {
    func playFrom(menu: Bool) {
        logEvent("PlayAudioFrom", value: menu ? "Menu" : "AudioBar")
    }
}

private extension CrasherKeyBase {
    static let reciterId = CrasherKey<Int>(key: "ReciterId")
    static let downloadingQuran = CrasherKey<Bool>(key: "DownloadingQuran")
    static let playingAyah = CrasherKey<AyahNumber>(key: "PlayingAyah")
}
