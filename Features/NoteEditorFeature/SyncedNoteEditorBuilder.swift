#if QURAN_SYNC
    import AppDependencies
    import FeaturesSupport
    import UIKit

    @MainActor
    public struct SyncedNoteEditorBuilder {
        public init(container: AppDependencies) {
            self.container = container
        }

        public func build(withListener listener: NoteEditorListener, note: SyncedNoteReference) -> UIViewController {
            let displayTextRetriever = DisplayVerseTextRetriever(
                databasesURL: container.databasesURL,
                quranFileURL: container.quranUthmaniV2Database
            )
            let viewModel = SyncedNoteEditorInteractor(
                notesSyncService: container.notesSyncService,
                textRetriever: displayTextRetriever,
                note: note
            )
            let viewController = SyncedNoteEditorViewController(viewModel: viewModel)
            viewModel.listener = listener
            return viewController
        }

        let container: AppDependencies
    }
#endif
