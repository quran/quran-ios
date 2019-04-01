//
//  DefaultAudioBannerViewPresenter.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
import QueuePlayer
import UIKit

class DefaultAudioBannerViewPresenter: NSObject, AudioBannerViewPresenter, AudioPlayerInteractorDelegate, QProgressListener {

    let qariRetreiver: AnyGetInteractor<[Qari]>
    let persistence: SimplePersistence
    let gaplessAudioPlayer: AudioPlayerInteractor
    let gappedAudioPlayer: AudioPlayerInteractor
    var audioRange: VerseRange?

    var audioPlayer: AudioPlayerInteractor {
        switch selectedQari.audioType {
        case .gapless:
            return gaplessAudioPlayer
        case .gapped:
            return gappedAudioPlayer
        }
    }

    weak var view: AudioBannerView?

    weak var delegate: AudioBannerViewPresenterDelegate?

    var selectedQariIndex: Int = 0 {
        didSet {
            persistence.setValue(selectedQari.id, forKey: .lastSelectedQariId)
        }
    }
    var qaris: [Qari] = []

    var selectedQari: Qari {
        return qaris[selectedQariIndex]
    }

    var verseRuns: Runs = .one {
        didSet { audioPlayer.setVerseRuns(verseRuns) }
    }

    var listRuns: Runs = .one {
        didSet { audioPlayer.setListRuns(listRuns) }
    }

    fileprivate var playing: Bool = false {
        didSet {
            if playing {
                view?.setPlaying()
            } else {
                view?.setPaused()
            }
        }
    }

    init(persistence: SimplePersistence,
         qariRetreiver: AnyGetInteractor<[Qari]>,
         gaplessAudioPlayer: AudioPlayerInteractor,
         gappedAudioPlayer: AudioPlayerInteractor) {
        self.persistence = persistence
        self.qariRetreiver = qariRetreiver
        self.gaplessAudioPlayer = gaplessAudioPlayer
        self.gappedAudioPlayer = gappedAudioPlayer
        super.init()

        self.gaplessAudioPlayer.delegate = self
        self.gappedAudioPlayer.delegate = self
    }

    func onViewDidLoad() {
        view?.hideAllControls()

        qariRetreiver.get()
            .done(on: .main) { (qaris) -> Void in
                self.qaris = qaris

                // get last selected qari id
                let lastSelectedQariId = self.persistence.valueForKey(.lastSelectedQariId)
                let index = qaris.index { $0.id == lastSelectedQariId }
                if let selectedIndex = index {
                    self.selectedQariIndex = selectedIndex
                }
            }
            .then { self.audioPlayer.isAudioDownloading() }
            .done(on: .main) { downloading -> Void in
                if !downloading {
                    self.showQariView()
                }
            }.suppress()
    }

    fileprivate func showQariView() {
        Crash.setValue(selectedQari.id, forKey: .QariId)
        view?.setQari(name: selectedQari.name, image: UIImage(named: selectedQari.imageName))
    }

    func setQariIndex(_ index: Int) {
        selectedQariIndex = index
        showQariView()
    }

    func play(from: AyahNumber, to: AyahNumber?, page: QuranPage) {
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

    // MARK: - AudioBannerViewDelegate
    func onPlayTapped() {
        guard let currentPage = delegate?.currentPage() else { return }
        verseRuns = .one
        listRuns = .one

        // start downloading & playing
        Analytics.shared.playFrom(menu: false)
        play(from: Quran.startAyahForPage(currentPage.pageNumber), to: nil, page: currentPage)
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

    func onQariTapped() {
        delegate?.showQariListSelectionWithQari(qaris, selectedIndex: selectedQariIndex)
    }

    func onMoreTapped() {
        guard let audioRange = audioRange else {
            return
        }
        delegate?.onAdvancedAudioOptionsButtonTapped()
    }

    func onCancelDownloadTapped() {
        audioPlayer.cancelDownload()
    }

    // MARK: - ProgressListener

    func onProgressUpdated(to progress: Double) {
        DispatchQueue.main.async {
            self.view?.setDownloading(Float(progress))
        }
    }

    // MARK: - AudioPlayerInteractorDelegate

    var progress: QProgress? {
        didSet {
            oldValue?.progressListeners.remove(self)
            progress?.progressListeners.insert(self)
        }
    }

    func willStartDownloading() {
        Crash.setValue(true, forKey: .DownloadingQuran)
        DispatchQueue.main.async { self.view?.setDownloading(0) }
    }

    func didStartDownloadingAudioFiles(progress: QProgress) {
        self.progress = progress
        onProgressUpdated(to: progress.progress)
    }

    func onPlayingStarted() {
        self.progress = nil
        Crash.setValue(false, forKey: .DownloadingQuran)
        DispatchQueue.main.async { self.playing = true }
    }

    func onPlaybackResumed() {
        self.progress = nil
        DispatchQueue.main.async { self.playing = true }
    }

    func onPlaybackPaused() {
        self.progress = nil
        DispatchQueue.main.async { self.playing = false }
    }

    func highlight(_ ayah: AyahNumber) {
        Crash.setValue(ayah, forKey: .PlayingAyah)
        DispatchQueue.main.async { self.delegate?.highlightAyah(ayah) }
    }

    func onFailedDownloadingWithError(_ error: Error) {
        self.progress = nil
        DispatchQueue.main.async {
            self.delegate?.onErrorOccurred(error: error)
        }
    }

    func onPlaybackOrDownloadingCompleted() {
        self.progress = nil

        Crash.setValue(nil, forKey: .PlayingAyah)
        Crash.setValue(false, forKey: .DownloadingQuran)
        DispatchQueue.main.async {
            self.showQariView()
            self.delegate?.removeHighlighting()
        }
    }
}
