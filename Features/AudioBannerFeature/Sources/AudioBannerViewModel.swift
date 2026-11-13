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
import Combine
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

private extension QuranPlaybackState {
    var crashContextValue: String {
        switch self {
        case .playing: "playing"
        case .paused: "paused"
        case .stopped: "stopped"
        case .downloading: "downloading"
        }
    }
}

@MainActor
public final class AudioBannerViewModel: ObservableObject {
    typealias AudioRange = (start: AyahNumber, end: AyahNumber)

    // MARK: Lifecycle

    init(
        analytics: AnalyticsLibrary,
        playback: QuranPlaybackService,
        reciterListBuilder: ReciterListBuilder,
        advancedAudioOptionsBuilder: AdvancedAudioOptionsBuilder
    ) {
        self.analytics = analytics
        self.playback = playback
        self.reciterListBuilder = reciterListBuilder
        self.advancedAudioOptionsBuilder = advancedAudioOptionsBuilder
        playbackRate = AudioPreferences.shared.playbackRate
        crashContext.setAudioState(playingState.crashContextValue)
        crashContext.setAudioReciter(id: nil)
        crashContext.clearPlayingAyah()
        crashContext.setAdvancedAudioOptionsPhase("idle")

        playback.$state.sink { [weak self] state in
            self?.receivePlaybackState(state)
        }.store(in: &subscriptions)
        playback.$currentAyah.sink { [weak self] ayah in
            self?.listener?.highlightReadingAyah(ayah)
            if let ayah {
                crashContext.setPlayingAyah(sura: ayah.sura.suraNumber, ayah: ayah.ayah)
            } else {
                crashContext.clearPlayingAyah()
            }
        }.store(in: &subscriptions)
        playback.$error.sink { [weak self] in self?.error = $0 }.store(in: &subscriptions)
        playback.$reciters.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
        playback.$activeReciter.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)

        AudioPreferences.shared.$playbackRate.assign(to: &$playbackRate)
    }

    // MARK: Public

    public func play(from: AyahNumber, to: AyahNumber?, repeatVerses: Bool) {
        logger.info("AudioBanner: playing from \(from) to \(String(describing: to))")
        analytics.playFrom(menu: true)
        play(
            from: from,
            to: to,
            verseRuns: AudioPreferences.shared.verseRuns,
            listRuns: repeatVerses ? .indefinite : AudioPreferences.shared.listRuns,
            playbackRate: playbackRate,
            verseDelay: AudioPreferences.shared.verseDelay,
            repetitionDelay: AudioPreferences.shared.repetitionDelay
        )
    }

    // MARK: Internal

    weak var listener: AudioBannerListener?

    @Published var error: Error?
    @Published var toast: Toast?
    @Published var modalRequest: ModalPresentationRequest?
    @Published var playbackRate: Float

    var audioOptionsSummary: AudioOptionsSummary {
        if case .stopped = playingState {
            return AudioOptionsSummary(
                rate: playbackRate,
                verseRuns: AudioPreferences.shared.verseRuns,
                rangeRuns: AudioPreferences.shared.listRuns
            )
        }
        return AudioOptionsSummary(rate: playbackRate, verseRuns: verseRuns, rangeRuns: listRuns)
    }

    var audioBannerState: AudioBannerState {
        switch playingState {
        case .playing: .playing(paused: false, rate: playbackRate)
        case .paused: .playing(paused: true, rate: playbackRate)
        case .stopped: .readyToPlay(reciter: selectedReciter?.localizedName ?? "")
        case .downloading(let progress): .downloading(progress: progress)
        }
    }

    func start() async {
        playback.playWhenStopped = { [weak self] in self?.playStartingCurrentPage() }
        await playback.start()
        listener?.highlightReadingAyah(playback.currentAyah)
    }

    func updatePlaybackRate(to rate: Float) {
        playback.setRate(rate)
    }

    /// Dismisses the banner's toasts, showing or waiting to show, leaving other features' toasts alone.
    func dismissToasts() {
        for id in toastIDs {
            ToastPresenter.shared.dismissToast(withID: id)
        }
        toastIDs = []
    }

    // MARK: Private

    private var audioRange: AudioRange? {
        get { playingState == .stopped ? stoppedRange ?? playback.range : playback.range }
        set { stoppedRange = newValue }
    }

    private var stoppedRange: AudioRange?
    private var toastIDs: [UUID] = []

    private let analytics: AnalyticsLibrary
    private let playback: QuranPlaybackService
    private let lastAyahFinder: LastAyahFinder = PreferencesLastAyahFinder.shared
    private var subscriptions: Set<AnyCancellable> = []
    private let reciterListBuilder: ReciterListBuilder
    private let advancedAudioOptionsBuilder: AdvancedAudioOptionsBuilder

    @Published private var verseRuns: Runs = AudioPreferences.shared.verseRuns
    @Published private var listRuns: Runs = AudioPreferences.shared.listRuns
    private var verseDelay: VerseDelay = AudioPreferences.shared.verseDelay
    private var repetitionDelay: RepetitionDelay = AudioPreferences.shared.repetitionDelay
    @Published private var playingState: QuranPlaybackState = .stopped

    private var selectedReciter: Reciter? { playback.selectedReciter }

    private func selectReciter(_ reciter: Reciter) {
        playback.selectReciter(reciter)
    }

    private func receivePlaybackState(_ state: QuranPlaybackState) {
        let previous = playingState
        playingState = state
        crashContext.setAudioState(state.crashContextValue)
        crashContext.setAudioReciter(id: playback.selectedReciter?.id)
        if state != .stopped {
            verseRuns = playback.verseRuns
            listRuns = playback.listRuns
            verseDelay = playback.verseDelay
            repetitionDelay = playback.repetitionDelay
        }
        if state == .playing, previous != .playing, previous != .paused {
            playingStarted()
        }
        if case .downloading = state, case .stopped = previous {
            startDownloading()
        }
    }

    // MARK: - Playback Controls

    private func playStartingCurrentPage() {
        guard let currentPage = listener?.visiblePages.min() else { return }
        logger.info("AudioBanner: Play starting page \(currentPage)")

        // start downloading & playing
        analytics.playFrom(menu: false)
        play(
            from: currentPage.firstVerse,
            to: nil,
            verseRuns: AudioPreferences.shared.verseRuns,
            listRuns: AudioPreferences.shared.listRuns,
            playbackRate: playbackRate,
            verseDelay: AudioPreferences.shared.verseDelay,
            repetitionDelay: AudioPreferences.shared.repetitionDelay
        )
    }

    private func setAudioRangeForCurrentPage() {
        guard let currentPage = listener?.visiblePages.min() else { return }
        let from = currentPage.firstVerse
        let end = lastAyahFinder.findLastAyah(startAyah: from)
        audioRange = (start: from, end: end)
    }

    private func play(
        from: AyahNumber,
        to: AyahNumber?,
        verseRuns: Runs,
        listRuns: Runs,
        playbackRate: Float,
        verseDelay: VerseDelay,
        repetitionDelay: RepetitionDelay
    ) {
        let end = to ?? lastAyahFinder.findLastAyah(startAyah: from)
        Task { [playback] in
            do {
                try await playback.play(
                    from: from, to: end,
                    verseRuns: verseRuns, listRuns: listRuns,
                    rate: playbackRate, verseDelay: verseDelay,
                    repetitionDelay: repetitionDelay
                )
            } catch {
                // The shared service publishes failures to every attached banner.
            }
        }
    }

    private func pause() {
        playback.pause()
    }

    private func resume() {
        playback.resume()
    }

    private func stepForward() {
        playback.stepForward()
    }

    private func stepBackward() {
        playback.stepBackward()
    }

    private func stop() {
        playback.stop()
    }

    private func startDownloading() {
        guard let audioRange else { return }
        let message = Self.audioMessage("audio.downloading.toast", audioRange: audioRange)
        showToast(Toast(message, icon: Toast.Icon(.download)))
    }

    private func playingStarted() {
        guard let audioRange else { return }
        let message = Self.audioMessage("audio.playing.toast", audioRange: audioRange)
        let modify = ToastAction(title: l("audio.playing.action.modify")) { [weak self] in
            self?.showAdvancedAudioOptions()
        }
        showToast(Toast(message, icon: Toast.Icon(.play), action: modify))
    }

    private func showToast(_ toast: Toast) {
        toastIDs.append(toast.id)
        self.toast = toast
    }

    static func audioMessage(_ format: String, audioRange: AudioRange) -> MultipartText {
        MultipartText.localizedFormat(format, "\(ayahRange: audioRange.start ... max(audioRange.start, audioRange.end))")
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
        await playback.cancelDownload()
    }
}

extension AudioBannerViewModel: ReciterListListener {
    func presentReciterList() {
        logger.info("AudioBanner: reciters button tapped. State: \(playingState)")
        modalRequest = .present(
            reciterListBuilder.build(withListener: self, standalone: true),
            owner: "reciter_list",
            kind: "sheet"
        )
    }

    public func onSelectedReciterChanged(to reciter: Reciter) {
        logger.info("AudioBanner: onSelectedReciterChanged to \(reciter.id)")
        selectReciter(reciter)
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
            listRuns: listRuns,
            verseDelay: verseDelay,
            repetitionDelay: repetitionDelay
        )
    }

    func showAdvancedAudioOptions() {
        logger.info("AudioBanner: more button tapped. State: \(playingState)")
        if case .stopped = playingState {
            verseRuns = AudioPreferences.shared.verseRuns
            listRuns = AudioPreferences.shared.listRuns
            verseDelay = AudioPreferences.shared.verseDelay
            repetitionDelay = AudioPreferences.shared.repetitionDelay
            setAudioRangeForCurrentPage()
        }

        guard let options = advancedAudioOptions else {
            crashContext.setAdvancedAudioOptionsPhase("unavailable")
            logger.info("AudioBanner: showAdvancedAudioOptions couldn't construct advanced audio options")
            return
        }
        crashContext.setAdvancedAudioOptionsPhase("presentation_requested")
        modalRequest = .present(
            advancedAudioOptionsBuilder.build(withListener: self, options: options),
            owner: "advanced_audio_options",
            kind: "sheet"
        )
    }

    public func updateAudioOptions(to newOptions: AdvancedAudioOptions) {
        crashContext.setAdvancedAudioOptionsPhase("applying")
        logger.info("AudioBanner: playing advanced audio options \(newOptions)")
        selectReciter(newOptions.reciter)
        AudioPreferences.shared.verseDelay = newOptions.verseDelay
        AudioPreferences.shared.repetitionDelay = newOptions.repetitionDelay
        AudioPreferences.shared.verseRuns = newOptions.verseRuns
        AudioPreferences.shared.listRuns = newOptions.listRuns
        play(
            from: newOptions.start,
            to: newOptions.end,
            verseRuns: newOptions.verseRuns,
            listRuns: newOptions.listRuns,
            playbackRate: playbackRate,
            verseDelay: newOptions.verseDelay,
            repetitionDelay: newOptions.repetitionDelay
        )
        crashContext.setAdvancedAudioOptionsPhase("applied")
    }

    public func dismissAudioOptions() {
        logger.info("AudioBanner: dismiss advanced audio options")
        crashContext.setAdvancedAudioOptionsPhase("dismiss_requested")
        modalRequest = .dismiss(owner: "advanced_audio_options")
    }
}

private extension AnalyticsLibrary {
    func playFrom(menu: Bool) {
        logEvent("PlayAudioFrom", value: menu ? "Menu" : "AudioBar")
    }
}
