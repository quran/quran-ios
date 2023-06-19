//
//  AdvancedAudioOptionsBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import QuranKit
import ReciterListFeature
import UIKit

@MainActor
public struct AdvancedAudioOptionsBuilder {
    // MARK: Lifecycle

    public init() {
    }

    // MARK: Public

    public func build(withListener listener: AdvancedAudioOptionsListener, options: AdvancedAudioOptions) -> UIViewController {
        let viewModel = AdvancedAudioOptionsInteractor(options: options)
        viewModel.listener = listener
        let viewController = AdvancedAudioOptionsNavigationController(
            viewModel: viewModel,
            reciterListBuilder: ReciterListBuilder()
        )
        return viewController
    }
}
