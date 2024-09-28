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
import SwiftUI
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
            remoteCommandsHandler: RemoteCommandsHandler(center: .shared()),
            reciterListBuilder: ReciterListBuilder(),
            advancedAudioOptionsBuilder: AdvancedAudioOptionsBuilder()
        )
        let view = AudioBannerView(viewModel: viewModel)
            .enableToastPresenter()
            .enableUIKitNavigator()
        let viewController = UIHostingController(rootView: view)
        viewController.view.backgroundColor = nil
        viewModel.listener = listener
        return (viewController, viewModel)
    }

    // MARK: Internal

    let container: AppDependencies
}
