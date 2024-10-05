//
//  AdvancedAudioOptionsBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import ReciterListFeature
import SwiftUI

@MainActor
public struct AdvancedAudioOptionsBuilder {
    public init() {
    }

    public func build(withListener listener: AdvancedAudioOptionsListener, options: AdvancedAudioOptions) -> UIViewController {
        let viewModel = AdvancedAudioOptionsViewModel(
            options: options,
            reciterListBuilder: ReciterListBuilder()
        )
        viewModel.listener = listener

        let view = AdvancedAudioOptionsView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        return viewController
    }
}
