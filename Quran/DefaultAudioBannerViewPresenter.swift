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

    weak var view: AudioBannerView?

    weak var delegate: AudioBannerViewPresenterDelegate?

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

    init(qariRetreiver: AnyDataRetriever<[Qari]>) {
        self.qariRetreiver = qariRetreiver
    }

    func onViewDidLoad() {
        view?.setQari(name: "Mohamed", image: UIImage(named: "aAbdurrahman As-Sudais"))
    }

    func setQari(qari: Qari) {
        view?.setQari(name: qari.name, image: UIImage(named: qari.imageName))
    }

    // MARK:- AudioBannerViewDelegate
    func onPlayTapped() {
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
        // show qari list
    }

    func onCancelDownloadTapped() {

    }
}
