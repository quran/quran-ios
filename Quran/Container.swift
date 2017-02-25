//
//  Container.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
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

    func createTranslationsViewController() -> UIViewController {
        return TranslationsViewController()
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
                                            ayahPersistence: createAyahTextStorage())
    }

    func createQariTableViewController() -> QariTableViewController {
        return QariTableViewController(style: .plain)
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

    func createAyahTextStorage() -> AyahTextPersistence {
        return SQLiteArabicTextPersistence()
    }

    func createAyahInfoRetriever() -> AyahInfoRetriever {
        return DefaultAyahInfoRetriever(persistence: createAyahInfoPersistence())
    }

    func createQuranController(page: Int, lastPage: LastPage?) -> QuranViewController {
        return QuranViewController(
            imageService            : createQuranImageService(),
            dataRetriever           : createQuranPagesRetriever(),
            ayahInfoRetriever       : createAyahInfoRetriever(),
            audioViewPresenter      : createAudioBannerViewPresenter(),
            qarisControllerCreator  : createCreator(createQariTableViewController),
            bookmarksPersistence    : createBookmarksPersistence(),
            lastPagesPersistence    : createLastPagesPersistence(),
            page                    : page,
            lastPage                : lastPage
        )
    }

    func createCreator<CreatedObject, Parameters>(
        _ creationClosure: @escaping (Parameters) -> CreatedObject) -> AnyCreator<CreatedObject, Parameters> {
        return AnyCreator(createClosure: creationClosure).erasedType()
    }

    func createQuranImageService() -> QuranImageService {
        return DefaultQuranImageService(imagesCache: createImagesCache())
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
        return SQLiteQariTimingRetriever(persistence: createQariAyahTimingPersistence())
    }

    func createQariAyahTimingPersistence() -> QariAyahTimingPersistence {
        return SQLiteAyahTimingPersistence()
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
}
