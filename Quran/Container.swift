//
//  Container.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/20/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import UIKit
import Moya
import SwiftyJSON

class Container {

    fileprivate static let DownloadsBackgroundIdentifier = "com.quran.ios.downloading.audio"

    fileprivate let imagesCache: Cache<Int, UIImage> = {
        let cache = Cache<Int, UIImage>()
        cache.countLimit = 5
        return cache
    }()

    fileprivate var downloadManager: DownloadManager! = nil

    init() {
        let configuration = URLSessionConfiguration.background(withIdentifier: "DownloadsBackgroundIdentifier")
        downloadManager = URLSessionDownloadManager(configuration: configuration, persistence: createDownloadsPersistence())
    }

    func createRootViewController() -> UIViewController {
        let controller = MainTabBarController()
        controller.viewControllers = [createSurasNavigationController(),
                                      createJuzsNavigationController(),
                                      createTranslationsNavigationController(),
                                      createBookmarksController()]
        return controller
    }

    func createTranslationsNavigationController() -> UIViewController {
        return TranslationsNavigationController(rootViewController: createTranslationsViewController())
    }

    func createSurasNavigationController() -> UIViewController {
        return SurasNavigationController(rootViewController: createSurasViewController())
    }

    func createJuzsNavigationController() -> UIViewController {
        return JuzsNavigationController(rootViewController: createJuzsViewController())
    }

    func createTranslationsSelectionViewController() -> UIViewController {
        return TranslationsSelectionNavigationController(
            rootViewController: TranslationsSelectionViewController(
                interactor: createTranslationsRetrievalInteractor(),
                localTranslationsInteractor: createLocalTranslationsRetrievalInteractor(),
                dataSource: createTranslationsSelectionDataSource()))
    }

    func createTranslationsViewController() -> UIViewController {
        return TranslationsViewController(
            interactor: createTranslationsRetrievalInteractor(),
            localTranslationsInteractor: createLocalTranslationsRetrievalInteractor(),
            dataSource: createTranslationsDataSource())
    }

    func createSurasViewController() -> UIViewController {
        return SurasViewController(dataRetriever: createSurasRetriever(), quranControllerCreator: createCreator(createQuranController))
    }

    func createJuzsViewController() -> UIViewController {
        return JuzsViewController(dataRetriever: createQuartersRetriever(), quranControllerCreator: createCreator(createQuranController))
    }

    func createSearchController() -> UIViewController {
        return SearchNavigationController(rootViewController: SearchViewController())
    }

    func createSettingsController() -> UIViewController {
        return SettingsNavigationController(rootViewController: SettingsViewController())
    }

    func createBookmarksController() -> UIViewController {
        return BookmarksNavigationController(rootViewController: createBookmarksViewController())
    }

    func createBookmarksViewController() -> UIViewController {
        return BookmarksTableViewController(quranControllerCreator: createCreator(createQuranController),
                                            simplePersistence: createSimplePersistence(),
                                            lastPagesPersistence: createLastPagesPersistence(),
                                            bookmarksPersistence: createBookmarksPersistence(),
                                            ayahPersistence: createArabicTextPersistence())
    }

    func createQariTableViewController(qaris: [Qari], selectedQariIndex: Int) -> QariTableViewController {
        return QariTableViewController(style: .plain, qaris: qaris, selectedQariIndex: selectedQariIndex)
    }

    func createQariTableViewControllerCreator() -> AnyCreator<QariTableViewController, ([Qari], Int, UIView?)> {
        return QariTableViewControllerCreator(qarisControllerCreator: createCreator(createQariTableViewController)).asAnyCreator()
    }

    func createTranslationsDataSource() -> TranslationsDataSource {
        let pendingDS = TranslationsBasicDataSource()
        let downloadedDS = TranslationsBasicDataSource()
        let dataSource = TranslationsDataSource(
            downloader: createDownloadManager(),
            deletionInteractor: createTranslationDeletionInteractor(),
            versionUpdater: createTranslationsVersionUpdaterInteractor(),
            pendingDataSource: pendingDS.asBasicDataSourceRepresentable(),
            downloadedDataSource: downloadedDS.asBasicDataSourceRepresentable())
        pendingDS.delegate = dataSource
        downloadedDS.delegate = dataSource
        return dataSource
    }

    func createTranslationsSelectionDataSource() -> TranslationsDataSource {
        let pendingDS = TranslationsBasicDataSource()
        let downloadedDS = TranslationsSelectionBasicDataSource(
            simplePersistence: createSimplePersistence())
        let dataSource = TranslationsSelectionDataSource(
            downloader: createDownloadManager(),
            deletionInteractor: createTranslationDeletionInteractor(),
            versionUpdater: createTranslationsVersionUpdaterInteractor(),
            pendingDataSource: pendingDS.asBasicDataSourceRepresentable(),
            downloadedDataSource: downloadedDS.asBasicDataSourceRepresentable())
        pendingDS.delegate = dataSource
        downloadedDS.delegate = dataSource
        return dataSource
    }

    func createSurasRetriever() -> AnyDataRetriever<[(Juz, [Sura])]> {
        return SurasDataRetriever().erasedType()
    }

    func createQuartersRetriever() -> AnyDataRetriever<[(Juz, [Quarter])]> {
        return QuartersDataRetriever().erasedType()
    }

    func createQuranPagesRetriever() -> AnyDataRetriever<[QuranPage]> {
        return QuranPagesDataRetriever().erasedType()
    }

    func createQarisDataRetriever() -> AnyDataRetriever<[Qari]> {
        return QariDataRetriever().erasedType()
    }

    func createAyahInfoPersistence() -> AyahInfoPersistence {
        return SQLiteAyahInfoPersistence()
    }

    func createArabicTextPersistence() -> AyahTextPersistence {
        return SQLiteArabicTextPersistence()
    }

    func createTranslationTextPersistence(filePath: String) -> SQLiteTranslationTextPersistence {
        return SQLiteTranslationTextPersistence(filePath: filePath)
    }

    func createAyahInfoRetriever() -> AyahInfoRetriever {
        return DefaultAyahInfoRetriever(persistence: createAyahInfoPersistence())
    }

    func createQuranController(page: Int, lastPage: LastPage?) -> QuranViewController {
        return QuranViewController(
            imageService                           : createQuranImageService(),
            pageService                            : createQuranTranslationService(),
            dataRetriever                          : createQuranPagesRetriever(),
            ayahInfoRetriever                      : createAyahInfoRetriever(),
            audioViewPresenter                     : createAudioBannerViewPresenter(),
            qarisControllerCreator                 : createQariTableViewControllerCreator(),
            translationsSelectionControllerCreator : createCreator(createTranslationsSelectionViewController),
            bookmarksPersistence                   : createBookmarksPersistence(),
            lastPagesPersistence                   : createLastPagesPersistence(),
            simplePersistence                      : createSimplePersistence(),
            verseTextRetrieval                     : createCompositeVerseTextRetrieval(),
            page                                   : page,
            lastPage                               : lastPage
        )
    }

    func createCreator<CreatedObject, Parameters>(
        _ creationClosure: @escaping (Parameters) -> CreatedObject) -> AnyCreator<CreatedObject, Parameters> {
        return AnyCreator(createClosure: creationClosure)
    }

    func createQuranImageService() -> AnyCacheableService<Int, UIImage> {
        return PagesCacheableService(
            cache              : createImagesCache(),
            previousPagesCount : 1,
            nextPagesCount     : 2,
            pageRange          : Quran.QuranPagesRange,
            operationCreator   : createCreator(createImagePreloadingOperation)).asCacheableService()
    }

    func createQuranTranslationService() -> AnyCacheableService<Int, TranslationPage> {
        let d = PagesCacheableService(
            cache              : createTranslationPageCache(),
            previousPagesCount : 1,
            nextPagesCount     : 2,
            pageRange          : Quran.QuranPagesRange,
            operationCreator   : createCreator(createTranslationPreloadingOperation))
        return d.asCacheableService()
    }

    func createTranslationPageCache() -> Cache<Int, TranslationPage> {
        let cache = Cache<Int, TranslationPage>()
        cache.countLimit = 5
        return cache
    }

    func createImagesCache() -> Cache<Int, UIImage> {
        return imagesCache
    }

    func createAudioBannerViewPresenter() -> AudioBannerViewPresenter {
        return DefaultAudioBannerViewPresenter(persistence: createSimplePersistence(),
                                               qariRetreiver: createQarisDataRetriever(),
                                               gaplessAudioPlayer: createGaplessAudioPlayerInteractor(),
                                               gappedAudioPlayer: createGappedAudioPlayerInteractor())
    }

    func createUserDefaults() -> UserDefaults {
        return UserDefaults.standard
    }

    func createSimplePersistence() -> SimplePersistence {
        return UserDefaultsSimplePersistence(userDefaults: createUserDefaults())
    }

    func createSuraLastAyahFinder() -> LastAyahFinder {
        return SuraBasedLastAyahFinder()
    }

    func createPageLastAyahFinder() -> LastAyahFinder {
        return PageBasedLastAyahFinder()
    }

    func createJuzLastAyahFinder() -> LastAyahFinder {
        return JuzBasedLastAyahFinder()
    }

    func createDownloadManager() -> DownloadManager {
        return downloadManager
    }

    func createGappedAudioDownloader() -> AudioFilesDownloader {
        return GappedAudioFilesDownloader(downloader: createDownloadManager())
    }

    func createGaplessAudioDownloader() -> AudioFilesDownloader {
        return GaplessAudioFilesDownloader(downloader: createDownloadManager())
    }

    func createGappedAudioPlayer() -> AudioPlayer {
        return GappedAudioPlayer()
    }

    func createGaplessAudioPlayer() -> AudioPlayer {
        return GaplessAudioPlayer(timingRetriever: createQariTimingRetriever())
    }

    func createGaplessAudioPlayerInteractor() -> AudioPlayerInteractor {
        return GaplessAudioPlayerInteractor(downloader: createGaplessAudioDownloader(),
                                            lastAyahFinder: createJuzLastAyahFinder(),
                                            player: createGaplessAudioPlayer())
    }

    func createGappedAudioPlayerInteractor() -> AudioPlayerInteractor {
        return GappedAudioPlayerInteractor(downloader: createGappedAudioDownloader(),
                                           lastAyahFinder: createJuzLastAyahFinder(),
                                           player: createGappedAudioPlayer())
    }

    func createQariTimingRetriever() -> QariTimingRetriever {
        return SQLiteQariTimingRetriever(persistenceCreator: createCreator(createQariAyahTimingPersistence))
    }

    func createQariAyahTimingPersistence(filePath: URL) -> QariAyahTimingPersistence {
        return SQLiteAyahTimingPersistence(filePath: filePath)
    }

    func createBookmarksPersistence() -> BookmarksPersistence {
        return SQLiteBookmarksPersistence()
    }

    func createLastPagesPersistence() -> LastPagesPersistence {
        return SQLiteLastPagesPersistence(simplePersistence: createSimplePersistence())
    }

    func createDownloadsPersistence() -> DownloadsPersistence {
        return SqliteDownloadsPersistence()
    }

    func createMoyaProvider() -> MoyaProvider<BackendServices> {
        return MoyaProvider()
    }

    func createNetworkManager<To>(parser: AnyParser<JSON, To>) -> AnyNetworkManager<To> {
        return AnyNetworkManager(MoyaNetworkManager(provider: createMoyaProvider(), parser: parser))
    }

    func createTranslationsParser() -> AnyParser<JSON, [Translation]> {
        return AnyParser(TranslationsParser())
    }

    func createActiveTranslationsPersistence() -> ActiveTranslationsPersistence {
        return SQLiteActiveTranslationsPersistence()
    }

    func createTranslationsRetrievalInteractor() -> AnyInteractor<Void, [TranslationFull]> {
        return TranslationsRetrievalInteractor(
            networkManager: createNetworkManager(parser: createTranslationsParser()),
            persistence: createActiveTranslationsPersistence(),
            localInteractor: createLocalTranslationsRetrievalInteractor()).erasedType()
    }

    func createLocalTranslationsRetrievalInteractor() -> AnyInteractor<Void, [TranslationFull]> {
        return LocalTranslationsRetrievalInteractor(
            persistence: createActiveTranslationsPersistence(),
            versionUpdater: createTranslationsVersionUpdaterInteractor()).erasedType()
    }

    func createTranslationsVersionUpdaterInteractor() -> AnyInteractor<[Translation], [TranslationFull]> {
        return TranslationsVersionUpdaterInteractor(
            persistence: createActiveTranslationsPersistence(),
            downloader: createDownloadManager(),
            versionPersistenceCreator: createCreator(createSQLiteDatabaseVersionPersistence)).erasedType()
    }

    func createSQLiteDatabaseVersionPersistence(filePath: String) -> DatabaseVersionPersistence {
        return SQLiteDatabaseVersionPersistence(filePath: filePath)
    }

    func createTranslationDeletionInteractor() -> AnyInteractor<TranslationFull, TranslationFull> {
        return TranslationDeletionInteractor(
            persistence: createActiveTranslationsPersistence(),
            simplePersistence: createSimplePersistence()).erasedType()
    }

    func createImagePreloadingOperation(page: Int) -> AnyPreloadingOperationRepresentable<UIImage> {
        return ImagePreloadingOperation(page: page).asPreloadingOperationRepresentable()
    }

    func createTranslationPreloadingOperation(page: Int) -> AnyPreloadingOperationRepresentable<TranslationPage> {
        return TranslationPreloadingOperation(page: page,
                                              localTranslationInteractor: createLocalTranslationsRetrievalInteractor(),
                                              arabicPersistence: createArabicTextPersistence(),
                                              translationPersistenceCreator: createCreator(createTranslationTextPersistence),
                                              simplePersistence: createSimplePersistence()).asPreloadingOperationRepresentable()
    }

    func createImageVerseTextRetrieval() -> AnyInteractor<QuranShareData, String> {
        return ImageVerseTextRetrieval(arabicAyahPersistence: createArabicTextPersistence()).erasedType()
    }

    func createTranslationVerseTextRetrieval() -> AnyInteractor<QuranShareData, String> {
        return TranslationVerseTextRetrieval().erasedType()
    }

    func createCompositeVerseTextRetrieval() -> AnyInteractor<QuranShareData, String> {
        return CompositeVerseTextRetrieval(
            image: createImageVerseTextRetrieval(),
            translation: createTranslationVerseTextRetrieval()).erasedType()
    }
}
