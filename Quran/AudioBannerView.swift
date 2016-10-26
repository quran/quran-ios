//
//  AudioBannerView.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/27/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

protocol AudioBannerViewDelegate: class {

    func onPlayTapped()

    func onPauseResumeTapped()
    func onStopTapped()
    func onForwardTapped()
    func onBackwardTapped()
    func onRepeatTapped()

    func onQariTapped()

    func onCancelDownloadTapped()
}

protocol AudioBannerView: class {

    weak var delegate: AudioBannerViewDelegate? { get set }

    func hideAllControls()
    func setQari(name: String, image: UIImage?)
    func setDownloading(_ progress: Float)
    func setPlaying()
    func setPaused()
    func setRepeatCount(_ count: AudioRepeat)
}
