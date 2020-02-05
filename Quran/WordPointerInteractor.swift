//
//  WordPointerInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/13/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift

protocol WordPointerRouting: ViewableRouting {
    func presentTranslationTextTypeSelection()
    func dismissPresentedRouter()
}

protocol WordPointerPresentable: Presentable {
    var listener: WordPointerPresentableListener? { get set }

    func animateIn()
    func animateOut(completion: @escaping () -> Void)

    func showWordPopover(text: String, at point: CGPoint)
    func showWordPopover(text: String, at point: CGPoint, word: AyahWord, position: AyahWord.Position)
    func hideWordPopover()
}

protocol WordPointerListener: class {
    func onWordPointerPanBegan()
    func getWordPosition(at point: CGPoint, in view: UIView) -> AyahWord.Position?
    func highlightWordPosition(_ position: AyahWord.Position?)
    func dismissWordPointer()
}

final class WordPointerInteractor: PresentableInteractor<WordPointerPresentable>, WordPointerInteractable, WordPointerPresentableListener {

    struct Deps {
        var simplePersistence: SimplePersistence
        let wordByWordPersistence: WordByWordTranslationPersistence
        let hideWordPointerStream: HideWordPointerStream
        let showWordPointerStream: ShowWordPointerStream
    }

    weak var router: WordPointerRouting?
    weak var listener: WordPointerListener?
    private let deps: Deps

    private var selectedWord: AyahWord?

    init(presenter: WordPointerPresentable, deps: Deps) {
        self.deps = deps
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()

        deps.hideWordPointerStream.command.subscribe(onNext: {
            self.hideWordPointer()
        }).disposeOnDeactivate(interactor: self)

        deps.showWordPointerStream.command.subscribe(onNext: {
            self.presenter.animateIn()
        }).disposeOnDeactivate(interactor: self)
    }

    func hideWordPointer() {
        presenter.animateOut { [weak self] in
            self?.listener?.dismissWordPointer()
        }
    }

    func onViewTapped() {
        router?.presentTranslationTextTypeSelection()
    }

    func onViewPanBegan() {
        listener?.onWordPointerPanBegan()
    }

    func onViewPanChanged(to point: CGPoint, in view: UIView) {
        guard let position = listener?.getWordPosition(at: point, in: view) else {
            hideWordPopover()
            return
        }
        listener?.highlightWordPosition(position)

        var word: AyahWord?
        if selectedWord?.position == position {
            word = selectedWord
        } else {
            let textType = deps.simplePersistence.valueForKey(.wordTranslationType)
            suppress {
                word = try deps.wordByWordPersistence.getWord(for: position, type: AyahWord.TextType(rawValue: textType) ?? .translation)
            }
        }
        if let word = word, let text = word.text {
            showWordPopover(text: text, at: point, word: word, position: position)
        } else {
            presenter.hideWordPopover()
        }
    }

    func onViewPanEnded() {
        hideWordPopover()
    }

    private func showWordPopover(text: String, at point: CGPoint, word: AyahWord, position: AyahWord.Position) {
        presenter.showWordPopover(text: text, at: point, word: word, position: position)
        selectedWord = word
    }

    private func hideWordPopover() {
        listener?.highlightWordPosition(nil)
        presenter.hideWordPopover()
        selectedWord = nil
    }

    // MARK: - Translation Selection

    func dismissTranslationTextTypeSelection() {
        router?.dismissPresentedRouter()
    }

    func didDismissPopover() {
        router?.dismissPresentedRouter()
    }
}
