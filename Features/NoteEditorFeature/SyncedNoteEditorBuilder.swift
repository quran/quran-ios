#if QURAN_SYNC
    import AppDependencies
    import FeaturesSupport
    import QuranTextKit
    import UIKit

    @MainActor
    public struct SyncedNoteEditorBuilder {
        public init(container: AppDependencies) {
            self.container = container
        }

        public func build(withListener listener: NoteEditorListener, note: SyncedNoteReference) -> UIViewController {
            let textRetriever = ShareableVerseTextRetriever(
                databasesURL: container.databasesURL,
                quranFileURL: container.quranUthmaniV2Database
            )
            let guardService = container.notesSyncService
            let viewModel = SyncedNoteEditorInteractor(
                notesSyncService: guardService,
                textRetriever: textRetriever,
                note: note
            )
            let viewController = SyncedNoteEditorViewController(viewModel: viewModel)
            viewModel.listener = listener
            return viewController
        }

        let container: AppDependencies
    }
#endif
