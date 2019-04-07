//
//  AudioDownloadsInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift

protocol AudioDownloadsRouting: ViewableRouting {
}

protocol AudioDownloadsPresentable: Presentable {
    var listener: AudioDownloadsPresentableListener? { get set }
}

protocol AudioDownloadsListener: class {
}

final class AudioDownloadsInteractor: PresentableInteractor<AudioDownloadsPresentable>,
                            AudioDownloadsInteractable, AudioDownloadsPresentableListener {

    weak var router: AudioDownloadsRouting?
    weak var listener: AudioDownloadsListener?

    override init(presenter: AudioDownloadsPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }
}
