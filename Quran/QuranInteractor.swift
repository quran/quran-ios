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
    func dismissPresentedRouter()

    func presentAdvancedAudioOptions(with options: AdvancedAudioOptions)
    func presentTranslationTextTypeSelection()
    func presentMoreMenu(withModel model: MoreMenuModel)
    func presentTranslationsSelection()
    func presentQariList()
}

protocol QuranPresentable: Presentable {
    var listener: QuranPresentableListener? { get set }

    var verseRuns: Runs { get }
    var listRuns: Runs { get }
    var audioRange: VerseRange? { get }

    var isWordPointerActive: Bool { get }

    func updateAudioOptions(to newOptions: AdvancedAudioOptions)
    func setQuranMode(_ quranMode: QuranMode)
    func showWordPointer()
    func hideWordPointer()
    func reloadView()

    func updateSelectedQari()
}

protocol QuranListener: class {
}

final class QuranInteractor: PresentableInteractor<QuranPresentable>, QuranInteractable, QuranPresentableListener {

    struct Deps {
        var simplePersistence: SimplePersistence
    }

    weak var router: QuranRouting?
    weak var listener: QuranListener?

    private var deps: Deps

    init(presenter: QuranPresentable, deps: Deps) {
        self.deps = deps
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        presenter.setQuranMode(quranMode)
    }

    // MARK: - SimplePersistence

    private var quranMode: QuranMode {
        set { deps.simplePersistence.setValue(newValue == .translation, forKey: .showQuranTranslationView) }
        get { return deps.simplePersistence.valueForKey(.showQuranTranslationView) ? .translation : .arabic }
    }

    // MARK: - Popover

    func didDismissPopover() {
        router?.dismissPresentedRouter()
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
        router?.dismissPresentedRouter()
    }

    // MARK: - Word Translation Type Selection

    func onWordPointerTapped() {
        router?.presentTranslationTextTypeSelection()
    }

    func dismissTranslationTextTypeSelection() {
        router?.dismissPresentedRouter()
    }

    // MARK: - Qari List

    func onQariListButtonTapped() {
        router?.presentQariList()
    }

    func dismissQariList() {
        router?.dismissPresentedRouter()
    }

    func onSelectedQariChanged() {
        presenter.updateSelectedQari()
    }

    // MARK: - More Menu

    func onMoreBarButtonTapped() {
        router?.presentMoreMenu(withModel: MoreMenuModel(
            mode: quranMode,
            isWordPointerActive: presenter.isWordPointerActive,
            fontSize: deps.simplePersistence.fontSize,
            theme: deps.simplePersistence.theme
        ))
    }

    func onQuranModeUpdated(to mode: QuranMode) {
        self.quranMode = mode
        presenter.setQuranMode(mode)

        let noTranslationsSelected = deps.simplePersistence.valueForKey(.selectedTranslations).isEmpty
        if mode == .translation && noTranslationsSelected {
            router?.dismissPresentedRouter()
            router?.presentTranslationsSelection()
        }
    }

    func onTranslationsSelectionsTapped() {
        router?.dismissPresentedRouter()
        router?.presentTranslationsSelection()
    }

    func onIsWordPointerActiveUpdated(to isWordPointerActive: Bool) {
        if isWordPointerActive {
            presenter.showWordPointer()
        } else {
            presenter.hideWordPointer()
        }
    }

    func onFontSizedUpdated(to fontSize: FontSize) {
        deps.simplePersistence.fontSize = fontSize
        presenter.reloadView()
    }

    func onThemeSelectedUpdated(to theme: Theme) {
        deps.simplePersistence.theme = theme
        presenter.reloadView()
    }
}
