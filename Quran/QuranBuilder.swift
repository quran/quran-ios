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
            audioViewPresenter                     : createAudioBannerViewPresenter(),
            bookmarksPersistence                   : container.createBookmarksPersistence(),
            lastPagesPersistence                   : container.createLastPagesPersistence(),
            simplePersistence                      : container.createSimplePersistence(),
            verseTextRetrieval                     : createCompositeVerseTextRetrieval(),
            wordByWordPersistence                  : SQLiteArabicTextPersistence(),
            page                                   : page,
            lastPage                               : lastPage,
            highlightedSearchAyah                  : highlightAyah
        )
        let interactor = QuranInteractor(presenter: viewController, deps: QuranInteractor.Deps(
            simplePersistence: container.createSimplePersistence()
        ))
        interactor.listener = listener
        return QuranRouter(
            interactor: interactor,
            viewController: viewController,
            deps: QuranRouter.Deps(
                advancedAudioOptionsBuilder: AdvancedAudioOptionsBuilder(container: container),
                translationTextTypeSelectionBuilder: TranslationTextTypeSelectionBuilder(container: container),
                moreMenuBuilder: MoreMenuBuilder(container: container),
                qariListBuilder: QariListBuilder(container: container),
                translationsSelectionBuilder: TranslationsSelectionBuilder(container: container)
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
                                              arabicPersistence: container.createArabicTextPersistence(),
                                              translationPersistenceCreator: container.createCreator(container.createTranslationTextPersistence),
                                              simplePersistence: container.createSimplePersistence()).asPreloadingOperationRepresentable()
    }

    private func createAudioBannerViewPresenter() -> AudioBannerViewPresenter {
        return DefaultAudioBannerViewPresenter(persistence: container.createSimplePersistence(),
                                               qariRetreiver: container.createQarisDataRetriever(),
                                               gaplessAudioPlayer: createGaplessAudioPlayerInteractor(),
                                               gappedAudioPlayer: createGappedAudioPlayerInteractor())
    }

    private func createGappedAudioDownloader() -> AudioFilesDownloader {
        return AudioFilesDownloader(audioFileList: GappedQariAudioFileListRetrieval(),
                                    downloader: container.createDownloadManager(),
                                    ayahDownloader: container.createAyahsAudioDownloader())
    }

    private func createGaplessAudioDownloader() -> AudioFilesDownloader {
        return AudioFilesDownloader(audioFileList: GaplessQariAudioFileListRetrieval(),
                                    downloader: container.createDownloadManager(),
                                    ayahDownloader: container.createAyahsAudioDownloader())
    }

    private func createGaplessAudioPlayer() -> AudioPlayer {
        return GaplessAudioPlayer(timingRetriever: createQariTimingRetriever())
    }

    private func createGaplessAudioPlayerInteractor() -> AudioPlayerInteractor {
        return GaplessAudioPlayerInteractor(downloader: createGaplessAudioDownloader(),
                                            lastAyahFinder: createJuzLastAyahFinder(),
                                            player: createGaplessAudioPlayer())
    }

    private func createGappedAudioPlayerInteractor() -> AudioPlayerInteractor {
        return GappedAudioPlayerInteractor(downloader: createGappedAudioDownloader(),
                                           lastAyahFinder: createJuzLastAyahFinder(),
                                           player: GappedAudioPlayer())
    }

    private func createJuzLastAyahFinder() -> LastAyahFinder {
        return JuzBasedLastAyahFinder()
    }

    private func createQariTimingRetriever() -> QariTimingRetriever {
        return SQLiteQariTimingRetriever(persistenceCreator: container.createCreator(createQariAyahTimingPersistence))
    }

    private func createQariAyahTimingPersistence(filePath: URL) -> QariAyahTimingPersistence {
        return SQLiteAyahTimingPersistence(filePath: filePath)
    }

    private func createCompositeVerseTextRetrieval() -> AnyInteractor<QuranShareData, [String]> {
        return CompositeVerseTextRetrieval(
            image: ImageVerseTextRetrieval(arabicAyahPersistence: container.createArabicTextPersistence()).asAnyInteractor(),
            translation: TranslationVerseTextRetrieval().asAnyInteractor()).asAnyInteractor()
    }
}
