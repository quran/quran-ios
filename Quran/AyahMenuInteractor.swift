//
//  AyahMenuInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/11/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift

struct AyahMenuData {
    let isBookmarked: Bool
    let ayah: AyahNumber
}

protocol AyahMenuRouting: ViewableRouting {
}

protocol AyahMenuPresentable: Presentable {
    var listener: AyahMenuPresentableListener? { get set }

    func showMenuController(with data: AyahMenuData)
    func cleanUp()
    @discardableResult func resignFirstResponder() -> Bool

    func addAyahBookmark(ayah: AyahNumber)
    func removeAyahBookmarke(ayah: AyahNumber)

    func copyText(_ lines: [String])
    func shareText(_ lines: [String])

    func showErrorAlert(error: Error)
}

protocol AyahMenuListener: class {
    func dismissAyahMenu()
}

final class AyahMenuInteractor: PresentableInteractor<AyahMenuPresentable>, AyahMenuInteractable, AyahMenuPresentableListener {

    struct Deps {
        let ayah: AyahNumber
        let translationPage: TranslationPage?
        let playFromAyahStream: MutablePlayFromAyahStream
        let bookmarksPersistence: BookmarksPersistence
        let bookmarksQueue: DispatchQueue
        let verseTextRetriever: VerseTextRetriever
    }

    weak var router: AyahMenuRouting?
    weak var listener: AyahMenuListener?

    private let deps: Deps

    private var shouldDismissWhenResigned = true

    init(presenter: AyahMenuPresentable, deps: Deps) {
        self.deps = deps
        super.init(presenter: presenter)
        presenter.listener = self
    }

    func viewDidAppear() {
        deps.bookmarksQueue.async(.promise) {
            try self.deps.bookmarksPersistence.isAyahBookmarked(self.deps.ayah)
        }.done(on: .main) { isBookmarked in
            let data = AyahMenuData(isBookmarked: isBookmarked, ayah: self.deps.ayah)
            self.presenter.showMenuController(with: data)
        }.cauterize(tag: "AyahMenuInteractor.isBookmarked")
    }

    func willResignFirstResponder() {
        presenter.cleanUp()
        if shouldDismissWhenResigned {
            // dismiss it next loop
            DispatchQueue.main.async {
                self.listener?.dismissAyahMenu()
            }
        }
    }

    func viewTapped() {
        presenter.resignFirstResponder()
    }

    func viewPanned() {
        presenter.resignFirstResponder()
    }

    func willHideMenu() {
        presenter.resignFirstResponder()
    }

    // MARK: - Actions

    func onPlayTapped() {
        deps.playFromAyahStream.playFrom(ayah: deps.ayah)
    }

    func onRemoveBookmarkTapped() {
        Analytics.shared.unbookmark(ayah: deps.ayah)
        deps.bookmarksQueue
            .async(.promise) { try self.deps.bookmarksPersistence.removeAyahBookmark(self.deps.ayah) }
            .done(on: .main) { self.presenter.removeAyahBookmarke(ayah: self.deps.ayah) }
            .cauterize(tag: "AyahMenuInteractor.removeAyahBookmark")
    }

    func onAddBookmarkTapped() {
        Analytics.shared.bookmark(ayah: deps.ayah)
        deps.bookmarksQueue
            .async(.promise) { try self.deps.bookmarksPersistence.insertAyahBookmark(self.deps.ayah) }
            .done(on: .main) { self.presenter.addAyahBookmark(ayah: self.deps.ayah) }
            .cauterize(tag: "AyahMenuInteractor.addAyahBookmark")
    }

    func onCopyTapped() {
        retrieveSelectedAyahText { lines in
            self.presenter.copyText(lines)
        }
    }

    func onShareTapped() {
        shouldDismissWhenResigned = false
        retrieveSelectedAyahText { lines in
            self.presenter.shareText(lines)
        }
    }

    func onShareDismissed() {
        listener?.dismissAyahMenu()
    }

    private func retrieveSelectedAyahText(completion: @escaping ([String]) -> Void) {
        let input = VerseTextRetrieverInput(ayah: deps.ayah, translationPage: deps.translationPage)
        deps.verseTextRetriever
            .getText(for: input)
            .map { $0 + [self.deps.ayah.localizedName] + l("shareMarketingSuffix").components(separatedBy: "\n") }
            .done(on: .main, completion)
            .catch(on: .main) { (error) in
                self.presenter.showErrorAlert(error: error)
            }
    }
}
