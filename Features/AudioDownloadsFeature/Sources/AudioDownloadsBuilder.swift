//
//  AudioDownloadsBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AppDependencies
import QuranAudioKit
import ReciterService
import UIKit

@MainActor
public struct AudioDownloadsBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build() -> UIViewController {
        let downloader = QuranAudioDownloader(
            baseURL: container.filesAppHost,
            downloader: container.downloadManager
        )
        let sizeInfoRetriever = ReciterSizeInfoRetriever(baseURL: container.filesAppHost)
        let viewModel = AudioDownloadsViewModel(
            analytics: container.analytics,
            deleter: ReciterAudioDeleter(),
            ayahsDownloader: downloader,
            sizeInfoRetriever: sizeInfoRetriever,
            recitersRetriever: ReciterDataRetriever()
        )
        let viewController = AudioDownloadsViewController(viewModel: viewModel)
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
}
