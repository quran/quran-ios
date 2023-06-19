//
//  ReciterTableViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Combine
import Localization
import NoorUI
import QuranAudio
import UIKit

protocol ReciterListPresentableListener: AnyObject {
    func onReciterItemTapped(_ reciter: Reciter)
    func onCancelButtonTapped()
}

class ReciterTableViewController: BaseTableViewController {
    // MARK: Lifecycle

    init(viewModel: ReciterListViewModel) {
        self.viewModel = viewModel
        super.init(style: .grouped)
        rotateToPortraitIfPhone()

        Task {
            await viewModel.start()
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    // MARK: Internal

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundView = nil
        navigationItem.largeTitleDisplayMode = .never

        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        tableView.ds_register(cellNib: ReciterTableViewCell.self, in: .module)

        tableView.rowHeight = 70

        tableView.ds_useDataSource(dataSource)

        title = l("reciters.title")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(cancelButtonTapped))

        cancellable = Publishers.CombineLatest(viewModel.$reciters, viewModel.$selectedReciterId)
            .sink { [weak self] reciters, selectedReciterId in
                guard let selectedReciterId else {
                    return
                }
                self?.setReciters(reciters, selectedReciterId: selectedReciterId)
            }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedReciterId {
            selectItem(withId: selectedReciterId)
        }
    }

    // MARK: Private

    private static let disableInitialScroll = true

    private let viewModel: ReciterListViewModel

    private let dataSource = ReciterGroupedDataSource(sectionType: .multi)

    private var selectedReciterId: Int?

    private var cancellable: AnyCancellable?

    @objc
    private func cancelButtonTapped() {
        viewModel.onCancelButtonTapped()
    }

    private func setReciters(_ reciters: [[Reciter]], selectedReciterId: Int) {
        for recitersSection in reciters {
            createDataSource(for: recitersSection)
        }
        self.selectedReciterId = selectedReciterId
        tableView?.reloadData()
        selectItem(withId: selectedReciterId)
    }

    private func createDataSource(for reciters: [Reciter]) {
        let recitersDataSource = RecitersDataSource()
        recitersDataSource.setDidSelect { [weak self] ds, _, indexPath in
            self?.viewModel.onReciterItemTapped(ds.item(at: indexPath))
        }
        recitersDataSource.items = reciters
        dataSource.add(recitersDataSource)
    }

    private func selectItem(withId id: Int) {
        guard let indexPath = indexPath(forReciterId: id) else {
            return
        }
        tableView?.ds_selectItem(at: indexPath, animated: false, scrollPosition: [])
        if !Self.disableInitialScroll {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.tableView?.scrollToRow(at: indexPath, at: .middle, animated: true)
            }
        }
    }

    private func indexPath(forReciterId id: Int) -> IndexPath? {
        for (section, dataSource) in (dataSource.dataSources as? [RecitersDataSource] ?? []).enumerated() {
            if let index = dataSource.items.firstIndex(where: { $0.id == id }) {
                return IndexPath(item: index, section: section)
            }
        }
        return nil
    }
}
