#if QURAN_SYNC
//
//  SyncActivityBuilder.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import AppDependencies
import Localization
import SwiftUI
import UIKit

@MainActor
struct SyncActivityBuilder {
    let container: AppDependencies

    func build() -> UIViewController {
        let viewModel = SyncActivityViewModel(quranDataService: container.quranDataService)
        let viewController = UIHostingController(rootView: SyncActivityView(viewModel: viewModel))
        viewController.title = l("sync.activity.title")
        return viewController
    }
}
#endif
