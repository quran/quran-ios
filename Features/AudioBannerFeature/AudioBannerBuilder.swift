//
//  AudioBannerBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AdvancedAudioOptionsFeature
import AppDependencies
import QuranAudioKit
import ReciterListFeature
import ReciterService
import UIKit

@MainActor
public struct AudioBannerBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(withListener listener: AudioBannerListener) -> (UIViewController, AudioBannerViewModel) {
        let viewModel = AudioBannerViewModel(
            analytics: container.analytics,
            reciterRetreiver: ReciterDataRetriever(),
            recentRecitersService: RecentRecitersService(),
            audioPlayer: QuranAudioPlayer(),
            downloader: QuranAudioDownloader(
                baseURL: container.filesAppHost,
                downloader: container.downloadManager
            ),
            remoteCommandsHandler: RemoteCommandsHandler(center: .shared())
        )
        let viewController = AudioBannerViewController(
            viewModel: viewModel,
            reciterListBuilder: ReciterListBuilder(),
            advancedAudioOptionsBuilder: AdvancedAudioOptionsBuilder()
        )
        viewModel.listener = listener
        return (viewController, viewModel)
    }

    // MARK: Internal

    let container: AppDependencies
}
