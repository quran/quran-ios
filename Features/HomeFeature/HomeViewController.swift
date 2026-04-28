//
//  HomeViewController.swift
//
//
//  Created by Mohamed Afifi on 2023-07-16.
//

import Combine
import Localization
import ReadingSelectorFeature
import SwiftUI
import UIx

final class HomeViewController: UIHostingController<HomeView> {
    // MARK: Lifecycle

    init(viewModel: HomeViewModel, readingSelectorBuilder: ReadingSelectorBuilder) {
        self.viewModel = viewModel
        self.readingSelectorBuilder = readingSelectorBuilder
        super.init(rootView: HomeView(viewModel: viewModel))

        initialize()
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    private let viewModel: HomeViewModel
    private let readingSelectorBuilder: ReadingSelectorBuilder
    private lazy var segmentedControl = UISegmentedControl(frame: .zero)
    private lazy var collapseAllButton = UIBarButtonItem(
        image: UIImage.symbol("chevron.up.chevron.down"),
        style: .plain,
        target: self,
        action: #selector(toggleCollapseAllJuzs)
    )
    private var cancellables: Set<AnyCancellable> = []

    private func initialize() {
        configureSegmentedControl()
        configureNavigationBarButtons()
        observeCollapseState()
    }

    private func configureSegmentedControl() {
        segmentedControl.insertSegment(withTitle: lAndroid("quran_sura"), at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: lAndroid("quran_juz2"), at: 1, animated: false)
        segmentedControl.selectedSegmentIndex = viewModel.type.rawValue
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        navigationItem.titleView = segmentedControl
        segmentChanged()
    }

    private func configureNavigationBarButtons() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage.symbol("books.vertical.fill"),
                style: .plain,
                target: self,
                action: #selector(openReadingSelectors)
            ),
            collapseAllButton,
        ]

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.symbol("arrow.up.arrow.down"),
            style: .plain,
            target: self,
            action: #selector(toggleSort)
        )
    }

    private func observeCollapseState() {
        viewModel.$collapsedJuzs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] collapsed in
                self?.updateCollapseAllButton(hasAnyCollapsed: !collapsed.isEmpty)
            }
            .store(in: &cancellables)
    }

    private func updateCollapseAllButton(hasAnyCollapsed: Bool) {
        let symbolName = hasAnyCollapsed ? "rectangle.expand.vertical" : "rectangle.compress.vertical"
        collapseAllButton.image = UIImage.symbol(symbolName)
        collapseAllButton.accessibilityLabel = hasAnyCollapsed ? "Expand all" : "Collapse all"
    }

    @objc
    private func toggleSort() {
        viewModel.toggleSurahSortOrder()
    }

    @objc
    private func toggleCollapseAllJuzs() {
        viewModel.toggleCollapseAllJuzs()
    }

    @objc
    private func openReadingSelectors() {
        let readingSelector = readingSelectorBuilder.build()
        navigationController?.pushViewController(readingSelector, animated: true)
    }

    @objc
    private func segmentChanged() {
        let type = HomeViewType(rawValue: segmentedControl.selectedSegmentIndex) ?? .suras
        switch type {
        case .suras:
            navigationItem.title = lAndroid("quran_sura")
        case .juzs:
            navigationItem.title = lAndroid("quran_juz2")
        }
        viewModel.type = type
    }
}
