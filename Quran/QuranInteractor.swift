//
//  QuranInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//
import QueuePlayer
import RIBs
import RxSwift

protocol QuranRouting: ViewableRouting {
    func presentAdvancedAudioOptions(with options: AdvancedAudioOptions)
    func dismissAdvancedAudioOptions()

    func presentTranslationTextTypeSelection()
    func dismissTranslationTextTypeSelection()
}

protocol QuranPresentable: Presentable {
    var listener: QuranPresentableListener? { get set }

    var verseRuns: Runs { get }
    var listRuns: Runs { get }
    var audioRange: VerseRange? { get }

    func updateAudioOptions(to newOptions: AdvancedAudioOptions)
}

protocol QuranListener: class {
}

final class QuranInteractor: PresentableInteractor<QuranPresentable>, QuranInteractable, QuranPresentableListener {

    weak var router: QuranRouting?
    weak var listener: QuranListener?

    override init(presenter: QuranPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    // MARK: - AudioOptions

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

    // MARK: - Word Translation Type Selection

    func onWordPointerTapped() {
        router?.presentTranslationTextTypeSelection()
    }

    func dismissTranslationTextTypeSelection() {
        router?.dismissTranslationTextTypeSelection()
    }
}
