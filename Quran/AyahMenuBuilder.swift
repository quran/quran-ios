//
//  AyahMenuBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/11/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

struct AyahMenuInput {
    let cell: AyahMenuCell & UIView
    let pointInCell: CGPoint
    let ayah: AyahNumber
    let translationPage: TranslationPage?
    let playFromAyahStream: MutablePlayFromAyahStream
}

protocol AyahMenuBuildable: Buildable {
    func build(withListener listener: AyahMenuListener, input: AyahMenuInput) -> AyahMenuRouting
}

final class AyahMenuBuilder: Builder, AyahMenuBuildable {

    func build(withListener listener: AyahMenuListener, input: AyahMenuInput) -> AyahMenuRouting {
        let viewController = AyahMenuViewController(cell: input.cell, pointInCell: input.pointInCell)
        let interactor = AyahMenuInteractor(presenter: viewController, deps: AyahMenuInteractor.Deps(
            ayah: input.ayah,
            translationPage: input.translationPage,
            playFromAyahStream: input.playFromAyahStream,
            bookmarksPersistence: container.createBookmarksPersistence(),
            bookmarksQueue: DispatchQueue(label: "ayah-menu.bookmarks"),
            verseTextRetriever: createCompositeVerseTextRetriever()))
        interactor.listener = listener
        return AyahMenuRouter(interactor: interactor, viewController: viewController)
    }

    private func createCompositeVerseTextRetriever() -> VerseTextRetriever {
        return CompositeVerseTextRetriever(
            arabicText: ArabicVerseTextRetriever(arabicAyahPersistence: container.createArabicTextPersistence()),
            translation: TranslationVerseTextRetriever())
    }
}
