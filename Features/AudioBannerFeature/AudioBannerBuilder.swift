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
    public init(container: AppDependencies) {
        self.container = container
    }
    public func build(withListener listener: AudioBannerListener) -> (UIViewController, AudioBannerViewModel) {
        AudioPlaybackControllerStore.setUpIfNeeded(container: container)
        let playbackController = AudioPlaybackControllerStore.shared!

        let reciterRetriever = ReciterDataRetriever()
        let recentRecitersService = RecentRecitersService()

        let viewModel = AudioBannerViewModel(
            analytics: container.analytics,
            reciterRetreiver: reciterRetriever,
            recentRecitersService: recentRecitersService,
            downloader: playbackController.audioDownloader,
            playbackController: playbackController,
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
    let container: AppDependencies
}
