//
//  AudioBannerView.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/27/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

protocol AudioBannerViewDelegate: class {

    func onPlay()
    func onPause()
    func onStop()
    func onForward()
    func onBackward()
    func onRepeat(`repeat`: AudioRepeat)
}

class AudioBannerView: UIView {

    func setQariName(name: String) {
        unimplemented()
    }

    func setPlaying() {
        unimplemented()
    }

    func setDownloadingWithProgress(progress: NSProgress) {
        unimplemented()
    }
}
