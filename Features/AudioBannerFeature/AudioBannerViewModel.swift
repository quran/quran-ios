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
import Localization
import NoorUI
import QueuePlayer
import QuranAudio
import QuranAudioKit
import QuranKit
import ReciterListFeature
import ReciterService
import SwiftUI
import UIKit
import UIx
import Utilities
import VLogging

@MainActor
public protocol AudioBannerListener: AnyObject {
    var visiblePages: [Page] { get }
    func highlightReadingAyah(_ ayah: AyahNumber?)
}

private enum PlaybackState {
    case playing
    case paused
    case stopped
    case downloading(progress: Double)
}

@MainActor
public final class AudioBannerViewModel: ObservableObject {
    typealias AudioRange = (start: AyahNumber, end: AyahNumber)

    // MARK: Lifecycle

    init(
        analytics: AnalyticsLibrary,
        reciterRetreiver: ReciterDataRetriever,
        recentRecitersService: RecentRecitersService,
        audioPlayer: QuranAudioPlayer,
        downloader: QuranAudioDownloader,
        reciterListBuilder: ReciterListBuilder,
        advancedAudioOptionsBuilder: AdvancedAudioOptionsBuilder
    ) {
        self.analytics = analytics
        self.reciterRetreiver = reciterRetreiver
        self.recentRecitersService = recentRecitersService
        self.audioPlayer = audioPlayer
        self.downloader = downloader
        self.reciterListBuilder = reciterListBuilder
        self.advancedAudioOptionsBuilder = advancedAudioOptionsBuilder

        setUpAudioPlayerActions()
        setUpRemoteCommandHandler()
    }

    // MARK: Public

    public func play(from: AyahNumber, to: AyahNumber?, repeatVerses: Bool) {
        logger.info("AudioBanner: playing from \(from) to \(String(describing: to))")
        analytics.playFrom(menu: true)
        play(from: from, to: to, verseRuns: .one, listRuns: repeatVerses ? .indefinite : .one)
    }

    // MARK: Internal

    weak var listener: AudioBannerListener?

    @Published var error: Error?
    @Published var toast: (message: String, action: ToastAction?)?
    @Published var viewControllerToPresent: UIViewController?
    @Published var dismissPresentedViewController = false

    var audioBannerState: AudioBannerState {
        switch playingState {
        case .playing: .playing(paused: false)
        case .paused: .playing(paused: true)
        case .stopped: .readyToPlay(reciter: selectedReciter?.localizedName ?? "")
        case .downloading(let progress): .downloading(progress: progress)
        }
    }

    func start() async {
        remoteCommandsHandler?.startListeningToPlayCommand()
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
            cancellableTasks.insert(
                Task {
                    await observe(runningDownloads)
                }.asCancellableTask()
            )
        }
    }

    // MARK: Private

    private var audioRange: AudioRange?

    private let analytics: AnalyticsLibrary
    private let reciterRetreiver: ReciterDataRetriever
    private let recentRecitersService: RecentRecitersService
    private let preferences = ReciterPreferences.shared
    private let lastAyahFinder: LastAyahFinder = PreferencesLastAyahFinder.shared
    private let audioPlayer: QuranAudioPlayer
    private let downloader: QuranAudioDownloader
    private var remoteCommandsHandler: RemoteCommandsHandler?
    private let reciterListBuilder: ReciterListBuilder
    private let advancedAudioOptionsBuilder: AdvancedAudioOptionsBuilder

    private var verseRuns: Runs = .one
    private var listRuns: Runs = .one
    private var reciters: [Reciter] = []
    private var cancellableTasks: Set<CancellableTask> = []

    @Published private var playingState: PlaybackState = .stopped {
        didSet {
            logger.info("AudioBanner: playingState updated to \(playingState) - reciter: \(String(describing: selectedReciter?.id))")
            if case .stopped = playingState {
                onPlayingStateStopped()
            }
        }
    }

    private var selectedReciter: Reciter? {
        let storedSelectedReciterId = preferences.lastSelectedReciterId
        let selectedReciter = reciters.first { $0.id == storedSelectedReciterId }
        if selectedReciter == nil {
            let firstReciter = reciters.first
            logger.error("AudioBanner: couldn't find reciter \(storedSelectedReciterId) using \(String(describing: firstReciter?.id)) instead")
            return firstReciter
        }
        return selectedReciter
    }

    private func onPlayingStateStopped() {
        if let selectedReciter {
            crasher.setValue(selectedReciter.id, forKey: .reciterId)
        }
        listener?.highlightReadingAyah(nil)

        remoteCommandsHandler?.stopListening()
        remoteCommandsHandler?.startListeningToPlayCommand()
    }

    @objc
    private func applicationDidBecomeActive() {
        // re-assign playingState to update UI
        let tempPlayingState = playingState
        playingState = tempPlayingState
    }

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

    private func setAudioRangeForCurrentPage() {
        guard let currentPage = listener?.visiblePages.min() else { return }
        let from = currentPage.firstVerse
        let end = lastAyahFinder.findLastAyah(startAyah: from)
        audioRange = (start: from, end: end)
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

        cancellableTasks.task { [weak self] in
            do {
                let downloaded = await self?.downloader.downloaded(reciter: selectedReciter, from: from, to: end) ?? true
                logger.info("AudioBanner: reciter downloaded? \(downloaded)")
                if !downloaded {
                    self?.startDownloading()
                    let download = try await self?.downloader.download(from: from, to: end, reciter: selectedReciter)
                    guard let download else {
                        logger.info("AudioBanner: couldn't create a download request")
                        return
                    }

                    await self?.observe([download])

                    for try await _ in download.progress { }

                    logger.info("AudioBanner: download completed")
                }

                try await self?.audioPlayer.play(
                    reciter: selectedReciter,
                    from: from, to: end,
                    verseRuns: verseRuns, listRuns: listRuns
                )
                self?.playingStarted()
            } catch {
                self?.playbackFailed(error)
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

    private func observe(_ downloads: [DownloadBatchResponse]) async {
        await updateDownloadProgress()
        await withTaskGroup(of: Void.self) { group in
            for download in downloads {
                group.addTask { [weak self] in
                    do {
                        for try await _ in download.progress {
                            if let self {
                                await updateDownloadProgress()
                            }
                        }
                    } catch {
                        // Ignore errors
                    }
                }
            }
        }
        playbackEnded()
    }

    // MARK: - Audio Interactor Delegate

    private func setUpAudioPlayerActions() {
        let actions = QuranAudioPlayerActions(
            playbackEnded: { [weak self] in self?.playbackEnded() },
            playbackPaused: { [weak self] in self?.playbackPaused() },
            playbackResumed: { [weak self] in self?.playbackResumed() },
            playing: { [weak self] in self?.playing(ayah: $0) }
        )
        audioPlayer.setActions(actions)
    }

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

        guard let audioRange else {
            return
        }
        let message = audioMessage("audio.downloading.message", audioRange: audioRange)
        toast = (message, action: nil)
    }

    private func updateDownloadProgress() async {
        let downloads = await downloader.runningAudioDownloads()
        let progress = downloads.map(\.currentProgress.progress).reduce(0, +)
        playingState = .downloading(progress: progress / Double(downloads.count))
    }

    private func playingStarted() {
        logger.info("AudioBanner: playing started")
        cancellableTasks = []
        crasher.setValue(false, forKey: .downloadingQuran)
        remoteCommandsHandler?.startListening()
        playingState = .playing

        guard let audioRange else {
            return
        }

        let message = audioMessage("audio.playing.message", audioRange: audioRange)
        toast = (message, action: ToastAction(title: l("audio.playing.action.modify")) { [weak self] in
            self?.showAdvancedAudioOptions()
        })
    }

    private func playbackFailed(_ error: Error) {
        logger.info("AudioBanner: failed to playing audio. \(error)")
        self.error = error
        playbackEnded()
    }

    private func audioMessage(_ format: String, audioRange: AudioRange) -> String {
        lFormat(format, audioRange.start.localizedName, audioRange.end.localizedName)
    }
}

extension AudioBannerViewModel {
    func playFromBanner() {
        logger.info("AudioBanner: play button tapped. State: \(playingState)")
        playStartingCurrentPage()
    }

    func pauseFromBanner() {
        logger.info("AudioBanner: pause button tapped. State: \(playingState)")
        pause()
    }

    func resumeFromBanner() {
        logger.info("AudioBanner: resume button tapped. State: \(playingState)")
        resume()
    }

    func stopFromBanner() {
        logger.info("AudioBanner: stop button tapped. State: \(playingState)")
        stop()
    }

    func forwardFromBanner() {
        logger.info("AudioBanner: step forward button tapped. State: \(playingState)")
        stepForward()
    }

    func backwardFromBanner() {
        logger.info("AudioBanner: step backward button tapped. State: \(playingState)")
        stepBackward()
    }

    func cancelDownload() async {
        logger.info("AudioBanner: cancel download tapped. State: \(playingState)")
        await downloader.cancelAllAudioDownloads()
        playbackEnded()
    }
}

extension AudioBannerViewModel {
    private func setUpRemoteCommandHandler() {
        let remoteActions = RemoteCommandActions(
            play: { [weak self] in self?.handlePlayCommand() },
            pause: { [weak self] in self?.handlePauseCommand() },
            togglePlayPause: { [weak self] in self?.handleTogglePlayPauseCommand() },
            nextTrack: { [weak self] in self?.handleNextTrackCommand() },
            previousTrack: { [weak self] in self?.handlePreviousTrackCommand() }
        )
        remoteCommandsHandler = RemoteCommandsHandler(center: .shared(), actions: remoteActions)
    }

    private func handlePlayCommand() {
        logger.info("AudioBanner: play command fired. State: \(playingState)")
        switch playingState {
        case .stopped: playStartingCurrentPage()
        case .paused, .playing: resume()
        case .downloading: break
        }
    }

    private func handlePauseCommand() {
        logger.info("AudioBanner: pause command fired. State: \(playingState)")
        pause()
    }

    private func handleTogglePlayPauseCommand() {
        logger.info("AudioBanner: toggle play/pause command fired. State: \(playingState)")
        togglePlayPause()
    }

    private func handleNextTrackCommand() {
        logger.info("AudioBanner: step forward command fired. State: \(playingState)")
        stepForward()
    }

    private func handlePreviousTrackCommand() {
        logger.info("AudioBanner: step backward command fired. State: \(playingState)")
        stepBackward()
    }
}

extension AudioBannerViewModel: ReciterListListener {
    func presentReciterList() {
        logger.info("AudioBanner: reciters button tapped. State: \(playingState)")
        viewControllerToPresent = reciterListBuilder.build(withListener: self, standalone: true)
    }

    public func onSelectedReciterChanged(to reciter: Reciter) {
        logger.info("AudioBanner: onSelectedReciterChanged to \(reciter.id)")
        selectReciter(reciter)
        playingState = .stopped
    }
}

extension AudioBannerViewModel: AdvancedAudioOptionsListener {
    private var advancedAudioOptions: AdvancedAudioOptions? {
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

    func showAdvancedAudioOptions() {
        logger.info("AudioBanner: more button tapped. State: \(playingState)")
        if case .stopped = playingState {
            setAudioRangeForCurrentPage()
        }

        guard let options = advancedAudioOptions else {
            logger.info("AudioBanner: showAdvancedAudioOptions couldn't construct advanced audio options")
            return
        }
        viewControllerToPresent = advancedAudioOptionsBuilder.build(withListener: self, options: options)
    }

    public func updateAudioOptions(to newOptions: AdvancedAudioOptions) {
        logger.info("AudioBanner: playing advanced audio options \(newOptions)")
        selectReciter(newOptions.reciter)
        play(from: newOptions.start, to: newOptions.end, verseRuns: newOptions.verseRuns, listRuns: newOptions.listRuns)
    }

    public func dismissAudioOptions() {
        logger.info("AudioBanner: dismiss advanced audio options")
        dismissPresentedViewController = true
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
