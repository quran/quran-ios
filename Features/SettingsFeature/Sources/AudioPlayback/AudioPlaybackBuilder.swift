//
//  AudioPlaybackBuilder.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

import Localization
import ReciterListFeature
import ReciterService
import SwiftUI
import UIKit

@MainActor
struct AudioPlaybackBuilder {
    // MARK: Internal

    func build(navigationController: UINavigationController?) -> UIViewController {
        let viewModel = AudioPlaybackViewModel(
            reciterRetriever: ReciterDataRetriever(),
            recentRecitersService: RecentRecitersService(),
            reciterListBuilder: ReciterListBuilder(),
            navigationController: navigationController
        )
        let view = AudioPlaybackView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.title = l("audio.playback.title")
        viewController.navigationItem.largeTitleDisplayMode = .never
        return viewController
    }
}
