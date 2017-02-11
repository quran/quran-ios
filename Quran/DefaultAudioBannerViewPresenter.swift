//
//  DefaultAudioBannerViewPresenter.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import KVOController_Swift

class DefaultAudioBannerViewPresenter: NSObject, AudioBannerViewPresenter, AudioPlayerInteractorDelegate {

    let qariRetreiver: AnyDataRetriever<[Qari]>
    let persistence: SimplePersistence
    let gaplessAudioPlayer: AudioPlayerInteractor
    let gappedAudioPlayer: AudioPlayerInteractor

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
            persistence.setValue(selectedQari.id, forKey: .LastSelectedQariId)
        }
    }
    var qaris: [Qari] = []

    var selectedQari: Qari {
        return qaris[selectedQariIndex]
    }

    fileprivate var repeatCount: AudioRepeat = .none {
        didSet {
            view?.setRepeatCount(repeatCount)
        }
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
         qariRetreiver: AnyDataRetriever<[Qari]>,
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

        qariRetreiver.retrieve { [weak self] (qaris) in
            guard let `self` = self else {
                return
            }
            self.qaris = qaris

            // get last selected qari id
            let lastSelectedQariId = self.persistence.valueForKey(.LastSelectedQariId)
            let index = qaris.index { $0.id == lastSelectedQariId }
            if let selectedIndex = index {
                self.selectedQariIndex = selectedIndex
            }

            self.audioPlayer.checkIfDownloading { [weak self] (downloading) in
                if !downloading {
                    Queue.main.async { self?.showQariView() }
                }
            }
        }
    }

    fileprivate func showQariView() {
        Crash.setValue(selectedQariIndex, forKey: .QariId)
        view?.setQari(name: selectedQari.name, image: selectedQari.imageName.flatMap { UIImage(named: $0) })
    }

    func setQariIndex(_ index: Int) {
        selectedQariIndex = index
        showQariView()
    }

    // MARK: - AudioBannerViewDelegate
    func onPlayTapped() {
        guard let currentPage = delegate?.currentPage() else { return }
        repeatCount = .none
        // start downloading & playing
        audioPlayer.playAudioForQari(selectedQari, atPage: currentPage)
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
        audioPlayer.stopAudio()
    }

    func onForwardTapped() {
        audioPlayer.goForward()
    }

    func onBackwardTapped() {
        audioPlayer.goBackward()
    }

    func onRepeatTapped() {
        repeatCount = repeatCount.next()
    }

    func onQariTapped() {
        delegate?.showQariListSelectionWithQari(qaris, selectedIndex: selectedQariIndex)
    }

    func onCancelDownloadTapped() {
        audioPlayer.cancelDownload()
    }

    // MARK: - AudioPlayerInteractorDelegate
    let progressKeyPath = "fractionCompleted"
    var progress: Foundation.Progress? {
        didSet {
            if let oldValue = oldValue {
                unobserve(oldValue, keyPath: progressKeyPath)
            }
            if let newValue = progress {
                observe(retainedObservable: newValue,
                        keyPath: progressKeyPath,
                        options: [.initial, .new]) { [weak self] (_, change: ChangeData<Double>) in
                            if let newValue = change.newValue {
                                Queue.main.async { self?.view?.setDownloading(Float(newValue)) }
                            }
                }
            }
        }
    }

    func willStartDownloading() {
        Crash.setValue(true, forKey: .DownloadingQuran)
        Queue.main.async { self.view?.setDownloading(0)  }
    }

    func didStartDownloadingAudioFiles(progress: Foundation.Progress) {
        self.progress = progress
    }

    func onPlayingStarted() {
        Crash.setValue(false, forKey: .DownloadingQuran)
        self.progress = nil
        Queue.main.async { self.playing = true }
    }

    func onPlaybackResumed() {
        Queue.main.async { self.playing = true }
    }

    func onPlaybackPaused() {
        Queue.main.async { self.playing = false }
    }

    func highlight(_ ayah: AyahNumber) {
        Crash.setValue(ayah, forKey: .PlayingAyah)
        Queue.main.async { self.delegate?.highlightAyah(ayah) }
    }

    func onFailedDownloadingWithError(_ error: Error) {
        Queue.main.async {
            let message = (error as? CustomStringConvertible)?.description ?? "Error downloading files"
            UIAlertView(title: "Error", message: message, delegate: nil, cancelButtonTitle: "Ok").show()
        }
    }

    func onPlaybackOrDownloadingCompleted() {
        Crash.setValue(nil, forKey: .PlayingAyah)
        Crash.setValue(false, forKey: .DownloadingQuran)
        Queue.main.async {
            self.showQariView()
            self.delegate?.removeHighlighting()
        }
    }
}
