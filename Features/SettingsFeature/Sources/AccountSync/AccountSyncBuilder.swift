#if QURAN_SYNC
//
//  AccountSyncBuilder.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import AppDependencies
import Localization
import MobileSync
import SwiftUI
import UIKit

@MainActor
struct AccountSyncBuilder {
    let container: AppDependencies

    func build(
        user: MobileSyncUser?,
        signOut: @escaping @MainActor () async throws -> Void,
        navigationController: UINavigationController?
    ) -> UIViewController {
        let syncActivityBuilder = SyncActivityBuilder(container: container)
        let viewModel = AccountSyncViewModel(
            user: user,
            authenticationClient: container.authenticationClient,
            quranDataService: container.quranDataService,
            quranProfileURL: container.quranProfileURL,
            syncActivityBuilder: syncActivityBuilder,
            editor: syncActivityBuilder.heldItemEditor(navigationController: navigationController),
            signOut: signOut,
            navigationController: navigationController
        )
        let viewController = UIHostingController(rootView: AccountSyncView(viewModel: viewModel))
        viewController.title = l("sync.account.title")
        viewController.navigationItem.largeTitleDisplayMode = .never
        return viewController
    }
}
#endif
