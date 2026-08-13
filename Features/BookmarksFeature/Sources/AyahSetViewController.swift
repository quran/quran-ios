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

        updateNavigationItem(editMode: viewModel.editMode, content: viewModel.content)
        Publishers.CombineLatest(viewModel.$editMode, viewModel.$content)
            .sink { [weak self] editMode, content in
                self?.updateNavigationItem(editMode: editMode, content: content)
            }
            .store(in: &cancellables)
    }

    private weak var viewController: UIViewController?
    private let viewModel: AyahSetViewModel
    private var cancellables: Set<AnyCancellable> = []

    private func updateNavigationItem(editMode: EditMode, content: AyahSetContent) {
        guard let viewController else {
            return
        }

        updateTitle(for: content, in: viewController)
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
