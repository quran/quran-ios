//
//  TranslationVerseViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-10-09.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import Combine
import MoreMenuFeature
import NoorUI
import SwiftUI
import TranslationService
import TranslationsFeature
import UIx
import VLogging

class TranslationVerseViewController: UIHostingController<TranslationVerseView> {
    // MARK: Lifecycle

    init(
        viewModel: TranslationVerseViewModel,
        moreMenuBuilder: MoreMenuBuilder,
        translationsSelectionBuilder: TranslationsListBuilder
    ) {
        self.viewModel = viewModel
        self.moreMenuBuilder = moreMenuBuilder
        self.translationsSelectionBuilder = translationsSelectionBuilder

        let viewModel = self.viewModel
        let view = TranslationVerseView(viewModel: viewModel)
        super.init(rootView: view)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()

        viewModel.$currentVerse
            .receive(on: DispatchQueue.main)
            .sink { [weak self] verse in
                self?.nextButton?.isEnabled = verse.next != nil
                self?.previousButton?.isEnabled = verse.previous != nil
                self?.updateTitle()
            }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let noTranslationsSelected = selectedTranslationsPreferences.selectedTranslationIds.isEmpty
        if firstTime && noTranslationsSelected {
            presentTranslationsSelection()
        }
        firstTime = false
    }

    // MARK: Private

    private let viewModel: TranslationVerseViewModel
    private var cancellables: Set<AnyCancellable> = []

    private var nextButton: UIBarButtonItem?
    private var previousButton: UIBarButtonItem?

    private let moreMenuBuilder: MoreMenuBuilder
    private let translationsSelectionBuilder: TranslationsListBuilder

    private let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared

    private var firstTime = true

    private func configureNavigationBar() {
        navigationItem.rightBarButtonItems?.append(
            UIBarButtonItem(
                image: UIImage(systemName: "ellipsis.circle"),
                style: .plain,
                target: self,
                action: #selector(settingsTapped)
            )
        )

        let next = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(nextTapped)
        )
        let previous = UIBarButtonItem(
            image: UIImage(systemName: "chevron.right"),
            style: .plain,
            target: self,
            action: #selector(previousTapped)
        )

        switch view.effectiveUserInterfaceLayoutDirection {
        case .leftToRight:
            navigationItem.leftBarButtonItems = [next, previous]
        case .rightToLeft:
            navigationItem.leftBarButtonItems = [previous, next]
        @unknown default:
            fatalError("Unhandled case")
        }

        nextButton = next
        previousButton = previous
    }

    @objc
    private func settingsTapped(_ item: UIBarButtonItem) {
        logger.info("Verse Translation: Settings button tapped")
        var state = MoreMenuControlsState()
        state.mode = .alwaysOff
        state.translationsSelection = .alwaysOn
        state.wordPointer = .alwaysOff
        state.orientation = .alwaysOff
        state.fontSize = .alwaysOn
        state.twoPages = .alwaysOff
        state.verticalScrolling = .alwaysOff
        let viewController = moreMenuBuilder.build(withListener: self, model: MoreMenuModel(isWordPointerActive: false, state: state))
        presentPopover(viewController, pointingTo: item, permittedArrowDirections: [.up, .down])
    }

    @objc
    private func nextTapped() {
        viewModel.next()
    }

    @objc
    private func previousTapped() {
        viewModel.previous()
    }

    private func updateTitle() {
        updateTitle(
            firstLine: viewModel.currentVerse.sura.localizedName(withNumber: true),
            secondLine: viewModel.currentVerse.localizedAyahNumber
        )
    }

    private func updateTitle(firstLine: String, secondLine: String) {
        let titleView = navigationItem.titleView as? TwoLineNavigationTitleView ?? TwoLineNavigationTitleView(
            firstLineFont: .systemFont(ofSize: 15, weight: .light),
            secondLineFont: .boldSystemFont(ofSize: 15)
        )
        titleView.firstLine = firstLine
        titleView.secondLine = secondLine
        if navigationItem.titleView == nil {
            navigationItem.titleView = titleView
        }
    }
}

extension TranslationVerseViewController: MoreMenuListener {
    private class TranslationsSelectionNavigationController: BaseNavigationController {}

    func onTranslationsSelectionsTapped() {
        dismiss(animated: true) {
            self.presentTranslationsSelection()
        }
    }

    private func presentTranslationsSelection() {
        let controller = translationsSelectionBuilder.build()
        let navigationController = TranslationsSelectionNavigationController(rootViewController: controller)
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "x.circle"),
            style: .done,
            target: self,
            action: #selector(onTranslationsSelectionDoneTapped)
        )
        present(navigationController, animated: true, completion: nil)
    }

    @objc
    private func onTranslationsSelectionDoneTapped() {
        logger.info("Quran: translations selection dismissed")
        dismiss(animated: true)
    }

    func onIsWordPointerActiveUpdated(to isWordPointerActive: Bool) {
        fatalError("Not supported in the translation verse screen.")
    }
}
