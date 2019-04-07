//
//  AudioDownloadsBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol AudioDownloadsBuildable: Buildable {
    func build(withListener listener: AudioDownloadsListener) -> AudioDownloadsRouting
}

final class AudioDownloadsBuilder: Builder, AudioDownloadsBuildable {

    func build(withListener listener: AudioDownloadsListener) -> AudioDownloadsRouting {
        let viewController = AudioDownloadsViewController(
            retriever: createDownloadableQariAudioRetriever(),
            downloader: container.createDownloadManager(),
            ayahsDownloader: container.createAyahsAudioDownloader(),
            qariAudioDownloadRetriever: createQariListToQariAudioDownloadRetriever(),
            deletionInteractor: QariAudioDeleteInteractor().asAnyInteractor())
        let interactor = AudioDownloadsInteractor(presenter: viewController)
        interactor.listener = listener
        return AudioDownloadsRouter(interactor: interactor, viewController: viewController)
    }

    func createDownloadableQariAudioRetriever() -> DownloadableQariAudioRetrieverType {
        return DownloadableQariAudioRetriever(
            downloader: container.createDownloadManager(),
            qarisRetriever: container.createQarisDataRetriever(),
            downloadsInfoRetriever: createQariListToQariAudioDownloadRetriever())
    }

    func createQariListToQariAudioDownloadRetriever() -> QariListToQariAudioDownloadRetrieverType {
        return QariListToQariAudioDownloadRetriever(fileListCreator: container.createQariAudioFileListRetrievalCreator())
    }
}
