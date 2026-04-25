#if QURAN_SYNC
    import NoorUI
    import UIKit
    import UIx

    final class SyncedAyahMenuViewController: UIViewController {
        // MARK: Lifecycle

        init(viewModel: SyncedAyahMenuViewModel) {
            self.viewModel = viewModel
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: Public

        override public func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
            super.preferredContentSizeDidChange(forChildContentContainer: container)
            preferredContentSize = container.preferredContentSize
        }

        // MARK: Internal

        override func viewDidLoad() {
            super.viewDidLoad()

            let deleteHighlightAction: AsyncAction? = if viewModel.canDeleteHighlight {
                { [weak self] in
                    guard let self else { return }
                    await viewModel.deleteHighlight()
                }
            } else {
                nil
            }

            let deleteNoteAction: AsyncAction? = if viewModel.canDeleteNote {
                { [weak self] in
                    guard let self else { return }
                    await viewModel.deleteNote()
                }
            } else {
                nil
            }

            let actions = SyncedAyahMenuUI.Actions(
                play: { [weak self] in self?.viewModel.play() },
                repeatVerses: { [weak self] in self?.viewModel.repeatVerses() },
                highlight: { [weak self] color in await self?.viewModel.updateHighlight(color: color) },
                addNote: { [weak self] in await self?.viewModel.editNote() },
                deleteHighlight: deleteHighlightAction,
                deleteNote: deleteNoteAction,
                showTranslation: { [weak self] in self?.viewModel.showTranslation() },
                copy: { [weak self] in self?.viewModel.copy() },
                share: { [weak self] in self?.viewModel.share() }
            )
            let dataObject = SyncedAyahMenuUI.DataObject(
                highlightingColor: viewModel.highlightingColor,
                hasHighlight: viewModel.hasHighlight,
                hasNoteText: viewModel.hasNoteText,
                playSubtitle: viewModel.playSubtitle,
                repeatSubtitle: viewModel.repeatSubtitle,
                actions: actions,
                isTranslationView: viewModel.isTranslationView
            )
            showAyahMenu(dataObject)
        }

        // MARK: Private

        private let viewModel: SyncedAyahMenuViewModel

        private func showAyahMenu(_ dataObject: SyncedAyahMenuUI.DataObject) {
            let view = SyncedAyahMenuView(dataObject: dataObject)
            let hostingController = AutoUpdatingPreferredContentSizeHostingController(rootView: view)
            addFullScreenChild(hostingController)
        }
    }
#endif
