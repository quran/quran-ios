//
//  QuranAudioBannerBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import QueuePlayer
import RIBs
import RxSwift

protocol QuranAudioBannerBuildable: Buildable {
    func build(withListener listener: QuranAudioBannerListener, playFromAyahStream: PlayFromAyahStream) -> QuranAudioBannerRouting
}

final class QuranAudioBannerBuilder: Builder, QuranAudioBannerBuildable {

    func build(withListener listener: QuranAudioBannerListener, playFromAyahStream: PlayFromAyahStream) -> QuranAudioBannerRouting {
        let viewController = QuranAudioBannerViewController()
        let interactor = QuranAudioBannerInteractor(
            presenter: viewController,
            persistence: container.createSimplePersistence(),
            qariRetreiver: container.createQarisDataRetriever(),
            audioPlayer: createQuranAudioPlayer(),
            remoteCommandsHandler: RemoteCommandsHandler(center: .shared()),
            playFromAyahStream: playFromAyahStream
        )
        interactor.listener = listener
        return QuranAudioBannerRouter(interactor: interactor,
                                      viewController: viewController,
                                      deps: QuranAudioBannerRouter.Deps(
                                        advancedAudioOptionsBuilder: AdvancedAudioOptionsBuilder(container: container),
                                        qariListBuilder: QariListBuilder(container: container)
            )
        )
    }

    private func createQuranAudioPlayer() -> QuranAudioPlayer {
        return QuranAudioPlayer(downloader: createAudioDownloader(),
                                lastAyahFinder: createJuzLastAyahFinder(),
                                player: QueuePlayer(),
                                unzipper: AudioUnzipper(),
                                gappedAudioRequestBuilder: GappedAudioRequestBuilder(),
                                gaplessAudioRequestBuilder: GaplessAudioRequestBuilder(timingRetriever: createQariTimingRetriever()),
                                nowPlaying: NowPlayingUpdater(center: .default()))
    }

    private func createAudioDownloader() -> AudioFilesDownloader {
        return AudioFilesDownloader(gapplessAudioFileList: GaplessQariAudioFileListRetrieval(),
                                    gappedAudioFileList: GappedQariAudioFileListRetrieval(),
                                    downloader: container.createDownloadManager(),
                                    ayahDownloader: container.createAyahsAudioDownloader())
    }

    private func createQariTimingRetriever() -> QariTimingRetriever {
        return SQLiteQariTimingRetriever(persistenceCreator: container.createCreator(createQariAyahTimingPersistence))
    }

    private func createQariAyahTimingPersistence(filePath: URL) -> QariAyahTimingPersistence {
        return SQLiteAyahTimingPersistence(filePath: filePath)
    }

    private func createJuzLastAyahFinder() -> LastAyahFinder {
        return JuzBasedLastAyahFinder()
    }
}
