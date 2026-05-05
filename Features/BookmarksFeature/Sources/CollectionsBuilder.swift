//
//  CollectionsBuilder.swift
//
//  Created by Ahmed Nabil on 2026-05-05.
//

#if QURAN_SYNC
    import AppDependencies
    import FeaturesSupport
    import MobileSync
    import UIKit

    @MainActor
    public struct CollectionsBuilder {
        public init(container: AppDependencies) {
            self.container = container
        }

        public func build(withListener listener: QuranNavigator) -> UIViewController {
            guard let syncService = container.syncService else {
                fatalError("Expected sync service when QURAN_SYNC is enabled")
            }
            let viewModel = CollectionsViewModel(syncService: syncService) { [weak listener] page in
                listener?.navigateTo(page: page, lastPage: nil, highlightingSearchAyah: nil)
            }
            return CollectionsViewController(viewModel: viewModel)
        }

        let container: AppDependencies
    }
#endif
