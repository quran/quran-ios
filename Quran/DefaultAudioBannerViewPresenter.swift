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
        case .Gapless:
            return gaplessAudioPlayer
        case .Gapped:
            return gappedAudioPlayer
        }
    }

    var currentPage: QuranPage = Quran.firstPage()

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

    private var repeatCount: AudioRepeat = .None {
        didSet {
            view?.setRepeatCount(repeatCount)
        }
    }

    private var playing: Bool = false {
        didSet {
            if playing {
                view?.setPaused()
            } else {
                view?.setPlaying()
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
            let index = qaris.indexOf { $0.id == lastSelectedQariId }
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

    private func showQariView() {
        view?.setQari(name: selectedQari.name, image: selectedQari.imageName.flatMap { UIImage(named: $0) })
    }

    func setQariIndex(index: Int) {
        selectedQariIndex = index
        showQariView()
    }

    // MARK:- AudioBannerViewDelegate
    func onPlayTapped() {
        repeatCount = .None
        // start downloading & playing
        audioPlayer.playAudioForQari(selectedQari, atPage: currentPage)
    }

    func onPauseResumeTapped() {
        playing = !playing
    }

    func onStopTapped() {
        audioPlayer.stopAudio()
        showQariView()
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
        showQariView()
    }

    // MARK:- AudioPlayerInteractorDelegate
    let progressKeyPath = "fractionCompleted"
    var progress: NSProgress? {
        didSet {
            if let oldValue = oldValue {
                unobserve(oldValue, keyPath: progressKeyPath)
            }
            if let newValue = progress {
                observe(retainedObservable: newValue,
                        keyPath: progressKeyPath,
                        options: [.Initial, .New]) { [weak self] (observable, change: ChangeData<Double>) in
                            if let newValue = change.newValue {
                                Queue.main.async { self?.view?.setDownloading(Float(newValue)) }
                            }
                }
            }
        }
    }

    func willStartDownloadingAudioFiles(progress progress: NSProgress) {
        self.progress = progress
    }

    func onPlayingAyah(ayah: AyahNumber) {
        self.progress = nil
        Queue.main.async { self.playing = true }
    }

    func onFailedDownloadingWithError(error: ErrorType) {
        Queue.main.async {
            self.showQariView()
            let message = (error as? CustomStringConvertible)?.description ?? "Error downloading files"
            UIAlertView(title: "Error", message: message, delegate: nil, cancelButtonTitle: "Ok").show()
        }
    }
}
