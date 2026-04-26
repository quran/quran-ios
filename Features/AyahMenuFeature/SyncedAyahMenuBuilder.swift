#if QURAN_SYNC
    import AppDependencies
    import FeaturesSupport
    import MobileSync
    import MobileSyncSupport
    import QuranAnnotations
    import QuranKit
    import QuranTextKit
    import UIKit

    public struct SyncedAyahMenuInput {
        // MARK: Lifecycle

        public init(
            sourceView: UIView,
            pointInView: CGPoint,
            verses: [AyahNumber],
            notes: [QuranAnnotations.Note],
            syncHighlightColor: HighlightColor?,
            hasSyncHighlight: Bool
        ) {
            self.sourceView = sourceView
            self.pointInView = pointInView
            self.verses = verses
            self.notes = notes
            self.syncHighlightColor = syncHighlightColor
            self.hasSyncHighlight = hasSyncHighlight
        }

        // MARK: Internal

        let sourceView: UIView
        let pointInView: CGPoint
        let verses: [AyahNumber]
        let notes: [QuranAnnotations.Note]
        let syncHighlightColor: HighlightColor?
        let hasSyncHighlight: Bool
    }

    @MainActor
    public struct SyncedAyahMenuBuilder {
        // MARK: Lifecycle

        public init(container: AppDependencies) {
            self.container = container
        }

        // MARK: Public

        public func build(withListener listener: SyncedAyahMenuListener, input: SyncedAyahMenuInput) -> UIViewController {
            let textRetriever = ShareableVerseTextRetriever(
                databasesURL: container.databasesURL,
                quranFileURL: container.quranUthmaniV2Database
            )
            let deps = SyncedAyahMenuViewModel.Deps(
                sourceView: input.sourceView,
                pointInView: input.pointInView,
                verses: input.verses,
                notes: input.notes,
                syncHighlightColor: input.syncHighlightColor,
                hasSyncHighlight: input.hasSyncHighlight,
                syncService: container.syncService,
                bookmarkCollectionService: container.bookmarkCollectionService,
                textRetriever: textRetriever
            )
            let viewModel = SyncedAyahMenuViewModel(deps: deps)
            viewModel.listener = listener
            return SyncedAyahMenuViewController(viewModel: viewModel)
        }

        // MARK: Private

        private let container: AppDependencies
    }
#endif
