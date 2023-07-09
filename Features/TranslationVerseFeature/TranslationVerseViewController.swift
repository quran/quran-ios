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
import QuranKit
import QuranTextKit
import QuranTranslationFeature
import TranslationService
import TranslationsFeature
import UIKit
import UIx
import VLogging

class TranslationVerseViewController: UIViewController {
    // MARK: Lifecycle

    init(
        viewModel: TranslationVerseViewModel,
        quranUITraits: QuranUITraits,
        moreMenuBuilder: MoreMenuBuilder,
        translationsSelectionBuilder: TranslationsListBuilder
    ) {
        self.viewModel = viewModel
        self.moreMenuBuilder = moreMenuBuilder
        self.translationsSelectionBuilder = translationsSelectionBuilder
        collectionView = QuranTranslationDiffableDataSource.translationCollectionView()
        dataSource = TranslationVerseDataSource(collectionView: collectionView)
        super.init(nibName: nil, bundle: nil)
        self.quranUITraits = quranUITraits
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.reading

        configureCollectionView()
        configureNavigationBar()
        configureSettingsObservers()

        viewModel.$translatedVerse
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)

        viewModel.$currentVerse
            .receive(on: DispatchQueue.main)
            .sink { [weak self] verse in
                self?.nextButton?.isEnabled = verse.next != nil
                self?.previousButton?.isEnabled = verse.previous != nil
            }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let noTranslationsSelected = selectedTranslationsPreferences.selectedTranslations.isEmpty
        if firstTime && noTranslationsSelected {
            presentTranslationsSelection()
        }
        firstTime = false
    }

    // MARK: Private

    private let collectionView: UICollectionView

    private let dataSource: TranslationVerseDataSource
    private let viewModel: TranslationVerseViewModel
    private var cancellables: Set<AnyCancellable> = []

    private var nextButton: UIBarButtonItem?
    private var previousButton: UIBarButtonItem?

    private let moreMenuBuilder: MoreMenuBuilder
    private let translationsSelectionBuilder: TranslationsListBuilder

    private let fontSizePreferences = FontSizePreferences.shared
    private let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared

    private var firstTime = true

    private var quranUITraits: QuranUITraits {
        get { dataSource.quranUITraits }
        set {
            logger.info("Verse Translation: set quranUITraits")
            var newQuranUITraits = newValue
            newQuranUITraits.removeHighlights()
            dataSource.quranUITraits = newQuranUITraits
        }
    }

    private func configureCollectionView() {
        collectionView.contentInsetAdjustmentBehavior = .automatic
        view.addAutoLayoutSubview(collectionView)
        collectionView.vc.edges()
    }

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
        state.theme = .alwaysOff
        let viewController = moreMenuBuilder.build(withListener: self, model: MoreMenuModel(isWordPointerActive: false, state: state))
        presentPopover(viewController, pointingTo: item, permittedArrowDirections: [.up, .down])
    }

    private func configureSettingsObservers() {
        selectedTranslationsPreferences.$selectedTranslations
            .sink { [weak self] _ in self?.viewModel.reload() }
            .store(in: &cancellables)
        fontSizePreferences.$arabicFontSize
            .sink { [weak self] in self?.quranUITraits.arabicFontSize = $0 }
            .store(in: &cancellables)
        fontSizePreferences.$translationFontSize
            .sink { [weak self] in self?.quranUITraits.translationFontSize = $0 }
            .store(in: &cancellables)
    }

    @objc
    private func nextTapped() {
        viewModel.next()
    }

    @objc
    private func previousTapped() {
        viewModel.previous()
    }

    private func updateUI() {
        guard let translatedVerse = viewModel.translatedVerse else {
            return
        }
        logger.info("Verse Translation: set TranslatedVerse")
        updateTitle(
            firstLine: translatedVerse.verse.sura.localizedName(withNumber: true),
            secondLine: translatedVerse.verse.localizedAyahNumber
        )
        dataSource.translatedVerse = translatedVerse
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
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
        Task { @MainActor in
            let controller = await translationsSelectionBuilder.build()
            let navigationController = TranslationsSelectionNavigationController(rootViewController: controller)
            controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "x.circle"),
                style: .done,
                target: self,
                action: #selector(onTranslationsSelectionDoneTapped)
            )
            present(navigationController, animated: true, completion: nil)
        }
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
