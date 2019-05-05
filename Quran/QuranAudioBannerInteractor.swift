//
//  QuranAudioBannerInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import QueuePlayer
import RIBs
import RxSwift

protocol QuranAudioBannerRouting: ViewableRouting {
    func presentQariList()
    func presentAdvancedAudioOptions(with options: AdvancedAudioOptions)

    func dismissPresentedRouter()
}

protocol QuranAudioBannerPresentable: Presentable {
    var listener: QuranAudioBannerPresentableListener? { get set }

    func showErrorAlert(error: Error)

    func hideAllControls()
    func setPlaying()
    func setPaused()
    func setDownloading(_ progress: Float)
    func setQari(name: String, imageName: String)
}

protocol QuranAudioBannerListener: class {
    func getCurrentQuranPage() -> QuranPage?
    func onAudioBannerTouchesBegan()

    func highlightAyah(_ ayah: AyahNumber)
    func removeHighlighting()
}

private enum PlaybackState {
    case playing
    case paused
    case stopped
    case downloading(progress: Float)
}

final class QuranAudioBannerInteractor: PresentableInteractor<QuranAudioBannerPresentable>,
                                QuranAudioBannerInteractable, QuranAudioBannerPresentableListener,
                                QuranAudioPlayerDelegate, QProgressListener, RemoteCommandsHandlerDelegate {

    weak var router: QuranAudioBannerRouting?
    weak var listener: QuranAudioBannerListener?

    private let qariRetreiver: QariDataRetrieverType
    private let persistence: SimplePersistence
    private let audioPlayer: QuranAudioPlayer
    private let remoteCommandsHandler: RemoteCommandsHandler

    private var audioRange: VerseRange?

    private var playingState: PlaybackState = .stopped {
        didSet {
            switch playingState {
            case .playing: presenter.setPlaying()
            case .paused: presenter.setPaused()
            case .stopped: showQariView()
            case .downloading(let progress): presenter.setDownloading(progress)
            }
        }
    }

    private var selectedQariId: Int?
    private var qaris: [Qari] = []
    private var selectedQari: Qari {
        return qaris.first { $0.id == selectedQariId } ?? qaris[0]
    }

    private var progress: QProgress? {
        didSet {
            oldValue?.progressListeners.remove(self)
            progress?.progressListeners.insert(self)
        }
    }

    private let playFromAyahStream: PlayFromAyahStream

    init(presenter: QuranAudioBannerPresentable,
         persistence: SimplePersistence,
         qariRetreiver: QariDataRetrieverType,
         audioPlayer: QuranAudioPlayer,
         remoteCommandsHandler: RemoteCommandsHandler,
         playFromAyahStream: PlayFromAyahStream) {
        self.persistence = persistence
        self.qariRetreiver = qariRetreiver
        self.audioPlayer = audioPlayer
        self.remoteCommandsHandler = remoteCommandsHandler
        self.playFromAyahStream = playFromAyahStream
        super.init(presenter: presenter)
        presenter.listener = self
        audioPlayer.delegate = self
        remoteCommandsHandler.delegate = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        remoteCommandsHandler.startListeningToPlayCommand()

        presenter.hideAllControls()

        qariRetreiver.getQaris()
            .done(on: .main) { (qaris) -> Void in
                self.qaris = qaris

                // get last selected qari id
                self.reloadSelectedQariId()
            }
            .then { self.audioPlayer.isAudioDownloading() }
            .done(on: .main) { downloading -> Void in
                if !downloading {
                    self.playingState = .stopped
                }
            }

        playFromAyahStream.ayah.subscribe(onNext: { (ayah) in
            self.play(from: ayah)
        }).disposeOnDeactivate(interactor: self)
    }

    override func willResignActive() {
        super.willResignActive()
        remoteCommandsHandler.stopListening()
    }

    private func play(from ayah: AyahNumber) {
        guard let page = listener?.getCurrentQuranPage() else {
            return
        }
        audioPlayer.listRuns = .one
        audioPlayer.verseRuns = .one
        Analytics.shared.playFrom(menu: true)
        self.play(from: ayah, to: nil, page: page)
    }

    // MARK: - Advanced Options

    func updateAudioOptions(to newOptions: AdvancedAudioOptions) {
        guard let page = listener?.getCurrentQuranPage() else {
            return
        }
        audioPlayer.verseRuns = newOptions.verseRuns
        audioPlayer.listRuns = newOptions.listRuns
        play(from: newOptions.range.lowerBound, to: newOptions.range.upperBound, page: page)
    }

    func dismissAudioOptions() {
        router?.dismissPresentedRouter()
    }

    // MARK: - Qari

    func didDismissPopover() {
        router?.dismissPresentedRouter()
    }

    func onSelectedQariChanged() {
        reloadSelectedQariId()
        playingState = .stopped
    }

    func dismissQariList() {
        router?.dismissPresentedRouter()
    }

    private func reloadSelectedQariId() {
        selectedQariId = self.persistence.valueForKey(.lastSelectedQariId)
    }

    // MARK: - Remote Commands

    func onPlayCommandFired() {
        switch playingState {
        case .stopped: playStartingCurrentPage()
        case .paused, .playing: resume()
        case .downloading: break
        }
    }

    func onPauseCommandFired() {
        pause()
    }

    func onTogglePlayPauseCommandFired() {
        togglePlayPause()
    }

    func onStepForwardCommandFired() {
        stepForward()
    }

    func onStepBackwardCommandFire() {
        stepBackward()
    }

    // MARK: - Presenter Listener

    func onPlayTapped() {
        playStartingCurrentPage()
    }

    func onPauseResumeTapped() {
        togglePlayPause()
    }

    func onStopTapped() {
        stop()
    }

    func onForwardTapped() {
        stepForward()
    }

    func onBackwardTapped() {
        stepBackward()
    }

    func onMoreTapped() {
        let options = AdvancedAudioOptions(range: unwrap(audioRange),
                                           verseRuns: audioPlayer.verseRuns,
                                           listRuns: audioPlayer.listRuns)
        router?.presentAdvancedAudioOptions(with: options)
    }

    func onQariTapped() {
        router?.presentQariList()
    }

    func onCancelDownloadTapped() {
        audioPlayer.cancelDownload()
    }

    func onTouchesBegan() {
        listener?.onAudioBannerTouchesBegan()
    }

    // MARK: - Playback Controls

    private func playStartingCurrentPage() {
        guard let currentPage = listener?.getCurrentQuranPage() else { return }
        audioPlayer.verseRuns = .one
        audioPlayer.listRuns = .one

        // start downloading & playing
        Analytics.shared.playFrom(menu: false)
        play(from: Quran.startAyahForPage(currentPage.pageNumber), to: nil, page: currentPage)
    }

    private func play(from: AyahNumber, to: AyahNumber?, page: QuranPage) {
        audioPlayer.stopAudio()
        let range: VerseRange
        if let to = to {
            range = VerseRange(lowerBound: from, upperBound: to)
        } else {
            range = audioPlayer.getAyahRange(starting: from, page: page)
        }
        self.audioRange = range
        audioPlayer.playAudioForQari(selectedQari, range: range)
    }

    private func togglePlayPause() {
        switch playingState {
        case .playing: pause()
        case .paused: resume()
        default:
            CLog("Invalid playingState \(playingState) found while trying to pause/resume playback")
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

    // MARK: - Audio Interactor Delegate

    func willStartDownloading() {
        Crash.setValue(true, forKey: .DownloadingQuran)
        DispatchQueue.main.async { self.playingState = .downloading(progress: 0) }
    }

    func didStartDownloadingAudioFiles(progress: QProgress) {
        self.progress = progress
        onProgressUpdated(to: progress.progress)
    }

    func onProgressUpdated(to progress: Double) {
        DispatchQueue.main.async {
            self.playingState = .downloading(progress: Float(progress))
        }
    }

    func onPlayingStarted() {
        self.progress = nil
        Crash.setValue(false, forKey: .DownloadingQuran)
        DispatchQueue.main.async { self.playingState = .playing }
        remoteCommandsHandler.startListening()
    }

    func onPlaybackPaused() {
        self.progress = nil
        DispatchQueue.main.async { self.playingState = .paused }
    }

    func onPlaybackResumed() {
        self.progress = nil
        DispatchQueue.main.async { self.playingState = .playing }
    }

    func onPlaying(ayah: AyahNumber) {
        Crash.setValue(ayah, forKey: .PlayingAyah)
        DispatchQueue.main.async { self.listener?.highlightAyah(ayah) }
    }

    func onFailedDownloadingWithError(_ error: Error) {
        showError(error)
    }

    func onFailedPlaybackWithError(_ error: Error) {
        showError(error)
    }

    private func showError(_ error: Error) {
        progress = nil
        DispatchQueue.main.async {
            self.presenter.showErrorAlert(error: error)
        }
    }

    func onPlaybackOrDownloadingCompleted() {
        self.progress = nil

        Crash.setValue(nil, forKey: .PlayingAyah)
        Crash.setValue(false, forKey: .DownloadingQuran)
        DispatchQueue.main.async { self.playingState = .stopped }
    }

    private func showQariView() {
        Crash.setValue(selectedQari.id, forKey: .QariId)
        presenter.setQari(name: selectedQari.name, imageName: selectedQari.imageName)
        self.listener?.removeHighlighting()

        self.remoteCommandsHandler.stopListening()
        self.remoteCommandsHandler.startListeningToPlayCommand()
    }
}
