//
//  AudioServiceFactory.swift
//
//
//  Created by Mohamed Afifi on 2021-11-29.
//

import BatchDownloader
import Foundation
import QueuePlayer
import QuranKit

public struct AudioServiceFactory {
    private let baseURL: URL
    private let userDefaults: UserDefaults
    private let downloadManager: DownloadManager

    public init(baseURL: URL,
                userDefaults: UserDefaults,
                downloadManager: DownloadManager)
    {
        self.baseURL = baseURL
        self.userDefaults = userDefaults
        self.downloadManager = downloadManager
    }

    public func audioUpdater() -> AudioUpdater {
        let networkManager = BatchDownloader.NetworkManager(session: .shared, baseURL: baseURL)
        let networkService = DefaultAudioUpdatesNetworkManager(networkManager: networkManager)
        return DefaultAudioUpdater(networkService: networkService,
                                   preferences: DefaultAudioUpdatePreferences(userDefaults: userDefaults),
                                   recitersRetriever: reciterDataRetriever())
    }

    public func reciterDataRetriever() -> ReciterDataRetriever {
        DefaultReciterDataRetriever()
    }

    public func reciterAudioDeleter() -> ReciterAudioDeleter {
        DefaultReciterAudioDeleter()
    }

    public func reciterListToReciterAudioDownloadRetriever() -> ReciterListToReciterAudioDownloadRetriever {
        DefaultReciterListToReciterAudioDownloadRetriever(fileListFactory: createReciterAudioFileListRetrievalFactory(),
                                                          quran: Quran.madani)
    }

    public func quranAudioPlayer() -> QuranAudioPlayer {
        let gaplessBuilder = GaplessAudioRequestBuilder(timingRetriever: createReciterTimingRetriever())
        let gappedBuilder = GappedAudioRequestBuilder()
        return DefaultQuranAudioPlayer(downloader: createAudioDownloader(),
                                       player: QueuePlayer(),
                                       unzipper: AudioUnzipper(),
                                       gappedAudioRequestBuilder: gappedBuilder,
                                       gaplessAudioRequestBuilder: gaplessBuilder,
                                       nowPlaying: NowPlayingUpdater(center: .default()))
    }

    public func ayahsAudioDownloader() -> AyahsAudioDownloader {
        DefaultAyahsAudioDownloader(downloader: downloadManager, fileListFactory: createReciterAudioFileListRetrievalFactory())
    }

    private func createReciterTimingRetriever() -> ReciterTimingRetriever {
        SQLiteReciterTimingRetriever(persistenceFactory: DefaultAyahTimingPersistenceFactory())
    }

    private func createAudioDownloader() -> AudioFilesDownloader {
        AudioFilesDownloader(gapplessAudioFileList: GaplessReciterAudioFileListRetrieval(baseURL: baseURL),
                             gappedAudioFileList: GappedReciterAudioFileListRetrieval(quran: Quran.madani),
                             downloader: downloadManager,
                             ayahDownloader: ayahsAudioDownloader())
    }

    private func createReciterAudioFileListRetrievalFactory() -> ReciterAudioFileListRetrievalFactory {
        DefaultReciterAudioFileListRetrievalFactory(quran: Quran.madani, baseURL: baseURL)
    }
}
