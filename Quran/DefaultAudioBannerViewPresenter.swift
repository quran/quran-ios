//
//  DefaultAudioBannerViewPresenter.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class DefaultAudioBannerViewPresenter: AudioBannerViewPresenter {

    let qariRetreiver: AnyDataRetriever<[Qari]>
    let persistence: SimplePersistence

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

    init(persistence: SimplePersistence, qariRetreiver: AnyDataRetriever<[Qari]>) {
        self.persistence = persistence
        self.qariRetreiver = qariRetreiver
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

            self.setQariIndex(self.selectedQariIndex)
        }
    }

    func setQariIndex(index: Int) {
        selectedQariIndex = index
        view?.setQari(name: selectedQari.name, image: selectedQari.imageName.flatMap { UIImage(named: $0) })
    }

    // MARK:- AudioBannerViewDelegate
    func onPlayTapped() {
        // 1. Get required Audio and Database files to play.
        // 2. Download them if needed.
        // 3. Start audio

        if !playing {
            repeatCount = .None
        }

        view?.setPlaying()
    }

    func onPauseResumeTapped() {
        playing = !playing
    }

    func onStopTapped() {
        view?.setQari(name: "Afifi", image: nil)
    }

    func onForwardTapped() {

    }
    func onBackwardTapped() {

    }
    func onRepeatTapped() {
        repeatCount = repeatCount.next()
    }

    func onQariTapped() {
        delegate?.showQariListSelectionWithQari(qaris, selectedIndex: selectedQariIndex)
    }

    func onCancelDownloadTapped() {

    }
}
