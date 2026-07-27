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
import QuranLocalization
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
        let overflow = NavigationBarButton.overflow { [weak self] in
            self?.settingsTapped()
        }
        let next = NavigationBarButton.secondary(systemName: "chevron.left") { [weak self] in
            self?.viewModel.next()
        }
        let previous = NavigationBarButton.secondary(systemName: "chevron.right") { [weak self] in
            self?.viewModel.previous()
        }

        switch view.effectiveUserInterfaceLayoutDirection {
        case .leftToRight:
            navigationItem.rightBarButtonItems = [overflow, previous, next]
        case .rightToLeft:
            navigationItem.rightBarButtonItems = [overflow, next, previous]
        @unknown default:
            fatalError("Unhandled case")
        }

        nextButton = next
        previousButton = previous
    }

    private func settingsTapped() {
        guard let item = navigationItem.rightBarButtonItems?.first else {
            return
        }
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

    private func updateTitle() {
        let verse = viewModel.currentVerse
        let suraReference: MultipartText = "\(sura: verse.sura)"
        updateTitle(
            firstLine: suraReference,
            secondLine: verse.localizedAyahNumber,
            accessibilityLabel: verse.localizedName
        )
    }

    private func updateTitle(
        firstLine: MultipartText,
        secondLine: String,
        accessibilityLabel: String
    ) {
        let titleView = navigationItem.titleView as? TwoLineNavigationTitleView ?? TwoLineNavigationTitleView(
            firstLineFont: .systemFont(ofSize: 15, weight: .light),
            secondLineFont: .boldSystemFont(ofSize: 15)
        )
        titleView.firstLineAttributedText = firstLine.attributedString(ofSize: .subheadline)
        titleView.secondLine = secondLine
        titleView.isAccessibilityElement = true
        titleView.accessibilityLabel = accessibilityLabel
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
        controller.navigationItem.leftBarButtonItem = NavigationBarButton.close { [weak self] in
            self?.onTranslationsSelectionDoneTapped()
        }
        present(navigationController, animated: true, completion: nil)
    }

    private func onTranslationsSelectionDoneTapped() {
        logger.info("Quran: translations selection dismissed")
        dismiss(animated: true)
    }

    func onIsWordPointerActiveUpdated(to isWordPointerActive: Bool) {
        fatalError("Not supported in the translation verse screen.")
    }
}
