//
//  QuranInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//
import QueuePlayer
import RIBs
import RxCocoa
import RxSwift

protocol QuranRouting: ViewableRouting {
    func dismissPresentedRouter(completion: (() -> Void)?)

    func presentTranslationTextTypeSelection()
    func presentMoreMenu(withModel model: MoreMenuModel)
    func presentTranslationsSelection()
    func presentAudioBanner(playFromAyahStream: PlayFromAyahStream)
    func presentAyahMenu(input: AyahMenuInput)
}

extension QuranRouting {
    func dismissPresentedRouter() {
        dismissPresentedRouter(completion: nil)
    }
}

protocol QuranPresentable: Presentable {
    var listener: QuranPresentableListener? { get set }

    var isWordPointerActive: Bool { get }

    func setQuranMode(_ quranMode: QuranMode)
    func showWordPointer()
    func hideWordPointer()
    func reloadView()

    func currentPage() -> QuranPage?
    func stopBarHiddenTimer()
    func highlightAyah(_ ayah: AyahNumber)
    func removeHighlighting()
}

protocol QuranListener: class {
}

final class QuranInteractor: PresentableInteractor<QuranPresentable>, QuranInteractable, QuranPresentableListener {

    struct Deps {
        var simplePersistence: SimplePersistence
        let playFromAyahStream: MutablePlayFromAyahStream
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
        router?.presentAudioBanner(playFromAyahStream: deps.playFromAyahStream)
    }

    // MARK: - SimplePersistence

    private var quranMode: QuranMode {
        set { deps.simplePersistence.setValue(newValue == .translation, forKey: .showQuranTranslationView) }
        get { return deps.simplePersistence.valueForKey(.showQuranTranslationView) ? .translation : .arabic }
    }

    // MARK: - TranslationsSelection

    func onTranslationsSelectionDoneTapped() {
        presenter.reloadView()
        router?.dismissPresentedRouter()
    }

    // MARK: - Popover

    func didDismissPopover() {
        router?.dismissPresentedRouter()
    }

    // MARK: - Word Translation Type Selection

    func onWordPointerTapped() {
        router?.presentTranslationTextTypeSelection()
    }

    func dismissTranslationTextTypeSelection() {
        router?.dismissPresentedRouter()
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
            presentTranslationsSelection()
        }
    }

    func onTranslationsSelectionsTapped() {
        presentTranslationsSelection()
    }

    private func presentTranslationsSelection() {
        router?.dismissPresentedRouter { [weak self] in
            self?.router?.presentTranslationsSelection()
        }
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

    // MARK: - Audio Banner

    func getCurrentQuranPage() -> QuranPage? {
        return presenter.currentPage()
    }

    func onAudioBannerTouchesBegan() {
        presenter.stopBarHiddenTimer()
    }

    func highlightAyah(_ ayah: AyahNumber) {
        presenter.highlightAyah(ayah)
    }

    func removeHighlighting() {
        presenter.removeHighlighting()
    }

    // MARK: Ayah Menu

    func onViewLongTapped(cell: QuranBasePageCollectionViewCell, point: CGPoint) {
        guard let wordPosition = cell.ayahWordPosition(at: point) else {
            return
        }
        router?.presentAyahMenu(input: AyahMenuInput(
            cell: cell,
            pointInCell: point,
            ayah: wordPosition.ayah,
            translationPage: (cell as? QuranTranslationCollectionPageCollectionViewCell)?.translationPage,
            playFromAyahStream: deps.playFromAyahStream
        ))
    }

    func dismissAyahMenu() {
        router?.dismissPresentedRouter()
    }
}
