#if QURAN_SYNC
    import AppDependencies
    import FeaturesSupport
    import QuranKit
    import QuranTextKit
    import UIKit

    @MainActor
    public struct SyncedNotesBuilder {
        public init(container: AppDependencies) {
            self.container = container
        }

        public func build(withListener listener: QuranNavigator) -> UIViewController {
            let textRetriever = ShareableVerseTextRetriever(
                databasesURL: container.databasesURL,
                quranFileURL: container.quranUthmaniV2Database
            )

            let viewModel = SyncedNotesViewModel(
                notesSyncService: container.notesSyncService,
                syncService: container.syncService,
                textRetriever: textRetriever,
                navigateTo: { [weak listener] verse in
                    listener?.navigateTo(page: verse.page, lastPage: nil, highlightingSearchAyah: nil)
                }
            )
            return SyncedNotesViewController(viewModel: viewModel)
        }

        let container: AppDependencies
    }
#endif
