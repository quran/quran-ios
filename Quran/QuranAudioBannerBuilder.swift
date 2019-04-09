//
//  QuranAudioBannerBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift

protocol QuranAudioBannerBuildable: Buildable {
    func build(withListener listener: QuranAudioBannerListener, playFromAyahStream: Observable<AyahNumber>) -> QuranAudioBannerRouting
}

final class QuranAudioBannerBuilder: Builder, QuranAudioBannerBuildable {

    func build(withListener listener: QuranAudioBannerListener, playFromAyahStream: Observable<AyahNumber>) -> QuranAudioBannerRouting {
        let viewController = QuranAudioBannerViewController()
        let interactor = QuranAudioBannerInteractor(
            presenter: viewController,
            persistence: container.createSimplePersistence(),
            qariRetreiver: container.createQarisDataRetriever(),
            gaplessAudioPlayer: createGaplessAudioPlayerInteractor(),
            gappedAudioPlayer: createGappedAudioPlayerInteractor(),
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

    private func createGaplessAudioDownloader() -> AudioFilesDownloader {
        return AudioFilesDownloader(audioFileList: GaplessQariAudioFileListRetrieval(),
                                    downloader: container.createDownloadManager(),
                                    ayahDownloader: container.createAyahsAudioDownloader())
    }

    private func createGappedAudioDownloader() -> AudioFilesDownloader {
        return AudioFilesDownloader(audioFileList: GappedQariAudioFileListRetrieval(),
                                    downloader: container.createDownloadManager(),
                                    ayahDownloader: container.createAyahsAudioDownloader())
    }

    private func createGaplessAudioPlayer() -> AudioPlayer {
        return GaplessAudioPlayer(timingRetriever: createQariTimingRetriever())
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
