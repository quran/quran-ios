//
//  QuranInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift
import QueuePlayer

protocol QuranRouting: ViewableRouting {
    func presentAdvancedAudioOptions(with options: AdvancedAudioOptions)
    func dismissAdvancedAudioOptions()
}

protocol QuranPresentable: Presentable {
    var listener: QuranPresentableListener? { get set }

    var verseRuns: Runs { get }
    var listRuns: Runs { get }
    var audioRange: VerseRange? { get }

    func updateAudioOptions(to newOptions: AdvancedAudioOptions)
}

protocol QuranListener: class {
    // TODO: Declare methods the interactor can invoke to communicate with other RIBs.
}

final class QuranInteractor: PresentableInteractor<QuranPresentable>, QuranInteractable, QuranPresentableListener {

    weak var router: QuranRouting?
    weak var listener: QuranListener?

    // TODO: Add additional dependencies to constructor. Do not perform any logic
    // in constructor.
    override init(presenter: QuranPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    // MARK:- AudioOptions

    func onAdvancedAudioOptionsButtonTapped() {
        let options = AdvancedAudioOptions(range: unwrap(presenter.audioRange),
                                           verseRuns: presenter.verseRuns,
                                           listRuns: presenter.listRuns)
        router?.presentAdvancedAudioOptions(with: options)
    }

    func updateAudioOptions(to newOptions: AdvancedAudioOptions) {
        presenter.updateAudioOptions(to: newOptions)
    }

    func dismissAudioOptions() {
        router?.dismissAdvancedAudioOptions()
    }
}
