//
//  AudioBannerBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AdvancedAudioOptionsFeature
import AppDependencies
import NoorUI
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

    /// `bottomBarsHeight` keeps the banner's toasts above the reader's bottom bars, the banner included.
    public func build(
        withListener listener: AudioBannerListener,
        bottomBarsHeight: @escaping @MainActor () -> CGFloat
    ) -> (UIViewController, AudioBannerViewModel) {
        let viewModel = AudioBannerViewModel(
            analytics: container.analytics,
            reciterRetreiver: ReciterDataRetriever(),
            recentRecitersService: RecentRecitersService(),
            audioPlayer: QuranAudioPlayer(),
            downloader: QuranAudioDownloader(
                baseURL: container.filesAppHost,
                downloader: container.downloadManager
            ),
            reciterListBuilder: ReciterListBuilder(),
            advancedAudioOptionsBuilder: AdvancedAudioOptionsBuilder()
        )
        let view = AudioBannerView(viewModel: viewModel)
            .enableToastPresenter(bottomBarsHeight: bottomBarsHeight)
        let viewController = UIHostingController(rootView: view)
        viewController.view.backgroundColor = nil
        if #available(iOS 16.4, *) {
            // Stay at the bottom of the reader. A keyboard, even one shown by a presented
            // editor like the reading bookmark menu, would otherwise lift the banner above it.
            viewController.safeAreaRegions = .container
        }
        viewModel.listener = listener
        return (viewController, viewModel)
    }

    // MARK: Internal

    let container: AppDependencies
}
