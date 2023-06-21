//
//  HomeViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/14/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Localization
import ReadingSelectorFeature
import UIKit
import VLogging

final class HomeViewController: UIViewController, HomePresentable {
    // MARK: Lifecycle

    init(interactor: HomeInteractor, readingSelectorBuilder: ReadingSelectorBuilder) {
        self.interactor = interactor
        self.readingSelectorBuilder = readingSelectorBuilder
        super.init(nibName: nil, bundle: nil)
        interactor.presenter = self
        interactor.start()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let interactor: HomeInteractor
    let readingSelectorBuilder: ReadingSelectorBuilder
    lazy var segmentedControl = UISegmentedControl(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentedControl.insertSegment(withTitle: lAndroid("quran_sura"), at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: lAndroid("quran_juz2"), at: 1, animated: false)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        navigationItem.titleView = segmentedControl

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage.symbol("books.vertical.fill"),
            style: .plain,
            target: self,
            action: #selector(openReadingSelectors)
        )
    }

    func selectSuras() {
        loadViewIfNeeded()
        segmentedControl.selectedSegmentIndex = 0
        segmentChanged()
    }

    func selectJuzs() {
        loadViewIfNeeded()
        segmentedControl.selectedSegmentIndex = 1
        segmentChanged()
    }

    // MARK: Private

    @objc
    private func openReadingSelectors() {
        let readingSelector = readingSelectorBuilder.build()
        navigationController?.pushViewController(readingSelector, animated: true)
    }

    @objc
    private func segmentChanged() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            logger.info("Home: Suras tapped")
            navigationItem.title = lAndroid("quran_sura")
            interactor.surasSelected()
        default:
            logger.info("Home: Juzs tapped")
            navigationItem.title = lAndroid("quran_juz2")
            interactor.juzsSelected()
        }
    }
}
