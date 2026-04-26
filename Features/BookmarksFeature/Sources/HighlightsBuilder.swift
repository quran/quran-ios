import AppDependencies
import FeaturesSupport
import UIKit

@MainActor
struct HighlightsBuilder {
    init(container: AppDependencies, listener: QuranNavigator) {
        self.container = container
        self.listener = listener
    }

    func build() -> UIViewController {
        #if QURAN_SYNC
            guard let syncService = container.syncService,
                  let bookmarkCollectionService = container.bookmarkCollectionService
            else {
                preconditionFailure("Highlights require sync services")
            }

            let highlightCollectionsUpdates = {
                HighlightCollection.updates(from: syncService)
            }

            let viewModel = HighlightsViewModel(
                highlightCollectionsUpdates: highlightCollectionsUpdates,
                makeColorController: { [container, weak listener] collection in
                    let detailViewModel = HighlightsColorViewModel(
                        collection: collection,
                        highlightCollectionsUpdates: highlightCollectionsUpdates,
                        noteService: container.noteService(),
                        removeHighlight: { ayah in
                            try await HighlightCollection.removeHighlights(
                                verses: [ayah],
                                syncService: syncService,
                                bookmarkCollectionService: bookmarkCollectionService
                            )
                        },
                        navigateTo: { [weak listener] verse in
                            listener?.navigateTo(page: verse.page, lastPage: nil, highlightingSearchAyah: nil)
                        }
                    )
                    return HighlightColorViewController(collection: collection, viewModel: detailViewModel)
                }
            )
            let viewController = HighlightsViewController(viewModel: viewModel)
            viewModel.presenter = viewController
            return viewController
        #else
            preconditionFailure("Highlights require QURAN_SYNC")
        #endif
    }

    private let container: AppDependencies
    private weak var listener: QuranNavigator?
}
