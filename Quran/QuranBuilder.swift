//
//  QuranBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

// MARK: - Builder

protocol QuranBuildable: Buildable {
    func build(withListener listener: QuranListener,
               page: Int,
               lastPage: LastPage?,
               highlightAyah: AyahNumber?) -> QuranRouting
}

final class QuranBuilder: Builder, QuranBuildable {

    func build(withListener listener: QuranListener,
               page: Int,
               lastPage: LastPage?,
               highlightAyah: AyahNumber?) -> QuranRouting {
        let viewController = QuranViewController(
            imageService                           : createQuranImageService(),
            pageService                            : createQuranTranslationService(),
            pagesRetriever                         : QuranPagesDataRetriever(),
            ayahInfoRetriever                      : DefaultAyahInfoRetriever(persistence: SQLiteAyahInfoPersistence()),
            bookmarksPersistence                   : container.createBookmarksPersistence(),
            lastPagesPersistence                   : container.createLastPagesPersistence(),
            simplePersistence                      : container.createSimplePersistence(),
            page                                   : page,
            lastPage                               : lastPage,
            highlightedSearchAyah                  : highlightAyah
        )
        let interactor = QuranInteractor(presenter: viewController, deps: QuranInteractor.Deps(
            simplePersistence: container.createSimplePersistence(),
            playFromAyahStream: PlayFromAyahStreamImpl(),
            hideWordPointerStream: HideWordPointerStreamImpl(),
            showWordPointerStream: ShowWordPointerStreamImpl()
        ))
        interactor.listener = listener
        return QuranRouter(
            interactor: interactor,
            viewController: viewController,
            deps: QuranRouter.Deps(
                moreMenuBuilder: MoreMenuBuilder(container: container),
                translationsSelectionBuilder: TranslationsSelectionBuilder(container: container),
                audioBannerBuilder: QuranAudioBannerBuilder(container: container),
                ayahMenuBuilder: AyahMenuBuilder(container: container),
                wordPointerBuilder: WordPointerBuilder(container: container)
        ))
    }

    private let imagesCache: Cache<Int, QuranUIImage> = {
        let cache = Cache<Int, QuranUIImage>()
        cache.countLimit = 5
        return cache
    }()

    private func createQuranImageService() -> AnyCacheableService<Int, QuranUIImage> {
        return PagesCacheableService(
            cache              : imagesCache,
            previousPagesCount : 1,
            nextPagesCount     : 2,
            pageRange          : Quran.QuranPagesRange,
            operationCreator   : container.createCreator(createImagePreloadingOperation)).asCacheableService()
    }

    private func createQuranTranslationService() -> AnyCacheableService<Int, TranslationPage> {
        let d = PagesCacheableService(
            cache              : createTranslationPageCache(),
            previousPagesCount : 1,
            nextPagesCount     : 2,
            pageRange          : Quran.QuranPagesRange,
            operationCreator   : container.createCreator(createTranslationPreloadingOperation))
        return d.asCacheableService()
    }

    private func createTranslationPageCache() -> Cache<Int, TranslationPage> {
        let cache = Cache<Int, TranslationPage>()
        cache.countLimit = 5
        return cache
    }

    private func createImagePreloadingOperation(page: Int) -> AnyPreloadingOperationRepresentable<QuranUIImage> {
        return ImagePreloadingOperation(page: page).asPreloadingOperationRepresentable()
    }

    private func createTranslationPreloadingOperation(page: Int) -> AnyPreloadingOperationRepresentable<TranslationPage> {
        return TranslationPreloadingOperation(page: page,
                                              localTranslationRetriever: container.createLocalTranslationsRetriever(),
                                              arabicPersistence: SQLiteQuranAyahTextPersistence(),
                                              translationsPersistenceBuilder: TranslationAyahTextPersistenceBuilder(),
                                              simplePersistence: container.createSimplePersistence()).asPreloadingOperationRepresentable()
    }
}
