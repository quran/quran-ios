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

final class QuranAudioBannerInteractor: PresentableInteractor<QuranAudioBannerPresentable>,
                                QuranAudioBannerInteractable, QuranAudioBannerPresentableListener,
                                AudioPlayerInteractorDelegate, QProgressListener {

    weak var router: QuranAudioBannerRouting?
    weak var listener: QuranAudioBannerListener?

    private let qariRetreiver: QariDataRetrieverType
    private let persistence: SimplePersistence
    private let gaplessAudioPlayer: AudioPlayerInteractor
    private let gappedAudioPlayer: AudioPlayerInteractor

    private var audioPlayer: AudioPlayerInteractor {
        switch selectedQari.audioType {
        case .gapless:
            return gaplessAudioPlayer
        case .gapped:
            return gappedAudioPlayer
        }
    }

    private var verseRuns: Runs = .one {
        didSet { audioPlayer.setVerseRuns(verseRuns) }
    }
    private var listRuns: Runs = .one {
        didSet { audioPlayer.setListRuns(listRuns) }
    }
    private var audioRange: VerseRange?

    private var playing: Bool = false {
        didSet {
            if playing {
                presenter.setPlaying()
            } else {
                presenter.setPaused()
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

    private let playFromAyahStream: Observable<AyahNumber>

    init(presenter: QuranAudioBannerPresentable,
         persistence: SimplePersistence,
         qariRetreiver: QariDataRetrieverType,
         gaplessAudioPlayer: AudioPlayerInteractor,
         gappedAudioPlayer: AudioPlayerInteractor,
         playFromAyahStream: Observable<AyahNumber>) {
        self.persistence = persistence
        self.qariRetreiver = qariRetreiver
        self.gaplessAudioPlayer = gaplessAudioPlayer
        self.gappedAudioPlayer = gappedAudioPlayer
        self.playFromAyahStream = playFromAyahStream
        super.init(presenter: presenter)
        presenter.listener = self
        gaplessAudioPlayer.delegate = self
        gappedAudioPlayer.delegate = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()

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
                    self.showQariView()
                }
            }

        playFromAyahStream.subscribe(onNext: { (ayah) in
            self.play(from: ayah)
        }).disposeOnDeactivate(interactor: self)
    }

    private func play(from ayah: AyahNumber) {
        guard let page = listener?.getCurrentQuranPage() else {
            return
        }
        self.listRuns = .one
        self.verseRuns = .one
        self.play(from: ayah, to: nil, page: page)
    }

    // MARK: - Advanced Options

    func updateAudioOptions(to newOptions: AdvancedAudioOptions) {
        guard let page = listener?.getCurrentQuranPage() else {
            return
        }
        verseRuns = newOptions.verseRuns
        listRuns = newOptions.listRuns
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
        showQariView()
    }

    func dismissQariList() {
        router?.dismissPresentedRouter()
    }

    private func reloadSelectedQariId() {
        selectedQariId = self.persistence.valueForKey(.lastSelectedQariId)
    }

    // MARK: - Presenter Listener

    func onPlayTapped() {
        guard let currentPage = listener?.getCurrentQuranPage() else { return }
        verseRuns = .one
        listRuns = .one

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

    func onPauseResumeTapped() {
        playing = !playing
        if playing {
            audioPlayer.resumeAudio()
        } else {
            audioPlayer.pauseAudio()
        }
    }

    func onStopTapped() {
        audioRange = nil
        audioPlayer.stopAudio()
    }

    func onForwardTapped() {
        audioPlayer.goForward()
    }

    func onBackwardTapped() {
        audioPlayer.goBackward()
    }

    func onMoreTapped() {
        let options = AdvancedAudioOptions(range: unwrap(audioRange),
                                           verseRuns: verseRuns,
                                           listRuns: listRuns)
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

    // MARK: - Audio Interactor Delegate

    func willStartDownloading() {
        Crash.setValue(true, forKey: .DownloadingQuran)
        DispatchQueue.main.async { self.presenter.setDownloading(0) }
    }

    func didStartDownloadingAudioFiles(progress: QProgress) {
        self.progress = progress
        onProgressUpdated(to: progress.progress)
    }

    func onProgressUpdated(to progress: Double) {
        DispatchQueue.main.async {
            self.presenter.setDownloading(Float(progress))
        }
    }

    func onPlayingStarted() {
        self.progress = nil
        Crash.setValue(false, forKey: .DownloadingQuran)
        DispatchQueue.main.async { self.playing = true }
    }

    func onPlaybackPaused() {
        self.progress = nil
        DispatchQueue.main.async { self.playing = false }
    }

    func onPlaybackResumed() {
        self.progress = nil
        DispatchQueue.main.async { self.playing = true }
    }

    func highlight(_ ayah: AyahNumber) {
        Crash.setValue(ayah, forKey: .PlayingAyah)
        DispatchQueue.main.async { self.listener?.highlightAyah(ayah) }
    }

    func onFailedDownloadingWithError(_ error: Error) {
        self.progress = nil
        DispatchQueue.main.async {
            self.presenter.showErrorAlert(error: error)
        }
    }

    func onPlaybackOrDownloadingCompleted() {
        self.progress = nil

        Crash.setValue(nil, forKey: .PlayingAyah)
        Crash.setValue(false, forKey: .DownloadingQuran)
        DispatchQueue.main.async {
            self.showQariView()
            self.listener?.removeHighlighting()
        }
    }

    private func showQariView() {
        Crash.setValue(selectedQari.id, forKey: .QariId)
        presenter.setQari(name: selectedQari.name, imageName: selectedQari.imageName)
    }
}
