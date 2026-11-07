#if QURAN_SYNC
import Combine
import Localization
import NoorUI
import SwiftUI
import UIKit

final class AyahSetViewController: UIHostingController<AyahSetView> {
    init(viewModel: AyahSetViewModel) {
        super.init(rootView: AyahSetView(viewModel: viewModel))
        navigationItem.largeTitleDisplayMode = .always
        menuController = AyahSetMenuController(
            viewController: self,
            viewModel: viewModel
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.navigationBar.sizeToFit()
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var menuController: AyahSetMenuController?
}

@MainActor
private final class AyahSetMenuController {
    init(viewController: UIViewController, viewModel: AyahSetViewModel) {
        self.viewController = viewController
        self.viewModel = viewModel

        updateNavigationItem(
            editMode: viewModel.editMode,
            content: viewModel.content,
            isRemovingAllAyahs: viewModel.isRemovingAllAyahs
        )
        Publishers.CombineLatest3(viewModel.$editMode, viewModel.$content, viewModel.$isRemovingAllAyahs)
            .sink { [weak self] editMode, content, isRemovingAllAyahs in
                self?.updateNavigationItem(editMode: editMode, content: content, isRemovingAllAyahs: isRemovingAllAyahs)
            }
            .store(in: &cancellables)
    }

    private weak var viewController: UIViewController?
    private let viewModel: AyahSetViewModel
    private var cancellables: Set<AnyCancellable> = []
    private weak var removeAllConfirmation: UIAlertController?

    private lazy var removeAllButton = NavigationBarButton.deleteAll { [weak self] in
        self?.confirmRemoveAll(sourceBarButtonItem: $0)
    }

    private func updateNavigationItem(editMode: EditMode, content: AyahSetContent, isRemovingAllAyahs: Bool) {
        guard let viewController else {
            return
        }

        updateTitle(for: content, in: viewController)
        // Delete All replaces Back, which iOS 26 otherwise shows beside a leading item.
        if editMode.isEditing, !content.ayahs.isEmpty, !isRemovingAllAyahs {
            viewController.navigationItem.leftBarButtonItem = removeAllButton
            viewController.navigationItem.hidesBackButton = true
        } else {
            viewController.navigationItem.leftBarButtonItem = nil
            viewController.navigationItem.hidesBackButton = false
            dismissRemoveAllConfirmation()
        }
        if editMode.isEditing {
            viewController.navigationItem.rightBarButtonItems = [
                NavigationBarButton.done { [weak self] in
                    self?.viewModel.editMode = .inactive
                },
            ]
        } else {
            let editButton = NavigationBarButton.edit { [weak self] in
                self?.viewModel.editMode = .active
            }
            let actions = secondaryActions(for: content)
            if actions.isEmpty {
                viewController.navigationItem.rightBarButtonItems = [editButton]
            } else {
                let menuButton = NavigationBarButton.overflow(menu: UIMenu(children: actions))
                viewController.navigationItem.rightBarButtonItems = [editButton, menuButton]
            }
        }
    }

    private func confirmRemoveAll(sourceBarButtonItem: UIBarButtonItem) {
        let alert = DeleteAllConfirmation.make(
            message: removeAllConfirmationMessage(for: viewModel.content),
            sourceBarButtonItem: sourceBarButtonItem
        ) { [weak self] in
            guard let self, viewModel.editMode.isEditing else {
                return
            }
            Task { await self.viewModel.removeAllAyahs() }
        }
        removeAllConfirmation = alert
        viewController?.present(alert, animated: true)
    }

    /// Done, or a sync that empties the page, takes Delete All away, so its confirmation goes too.
    private func dismissRemoveAllConfirmation() {
        guard let removeAllConfirmation, removeAllConfirmation.presentingViewController != nil,
              !removeAllConfirmation.isBeingDismissed
        else {
            return
        }
        removeAllConfirmation.dismiss(animated: true)
    }

    private func removeAllConfirmationMessage(for content: AyahSetContent) -> String {
        guard let highlightColor = content.highlightColor else {
            return DeleteAllConfirmation.message(collectionName: content.title)
        }
        return DeleteAllConfirmation.message(highlightColor: highlightColor)
    }

    private func updateTitle(for content: AyahSetContent, in viewController: UIViewController) {
        let subtitle = lFormat("bookmarks.collections.ayahs.count", content.ayahs.count)

        if #available(iOS 26.0, *) {
            viewController.title = content.title
            viewController.navigationItem.subtitle = subtitle
            viewController.navigationItem.largeTitle = content.title
            viewController.navigationItem.largeSubtitle = subtitle
        } else {
            viewController.title = "\(content.title) (\(subtitle))"
        }
    }

    private func secondaryActions(for content: AyahSetContent) -> [UIAction] {
        var actions: [UIAction] = []
        if content.canRename {
            actions.append(
                UIAction(
                    title: l("bookmarks.collections.rename"),
                    image: UIImage(systemName: "pencil.line")
                ) { [weak self] _ in
                    self?.viewModel.presentRename()
                }
            )
        }

        if content.canDelete {
            actions.append(
                UIAction(
                    title: l("button.delete"),
                    image: UIImage(systemName: "xmark"),
                    attributes: .destructive
                ) { [weak self] _ in
                    guard let self else {
                        return
                    }
                    Task { await self.viewModel.requestDelete() }
                }
            )
        }

        return actions
    }
}
#endif
