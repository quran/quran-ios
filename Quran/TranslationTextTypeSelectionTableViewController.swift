//
//  TranslationTextTypeSelectionTableViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 6/19/17.
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
import GenericDataSources
import UIKit

private class TableViewCell: UITableViewCell {
    static let font = UIFont.systemFont(ofSize: 17)
    let label: UILabel = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    private func setUp() {
        contentView.addAutoLayoutSubview(label)
        contentView.pinParentAllDirections(label, leadingValue: 15, trailingValue: 15, topValue: 0, bottomValue: 0)
    }
}

private class DataSource: BasicDataSource<String, TableViewCell> {
    var selectedIndex: Int?
    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: TableViewCell,
                                    with item: String,
                                    at indexPath: IndexPath) {
        cell.label.text = item
        cell.accessoryType = indexPath.item == selectedIndex ? .checkmark : .none
    }
}

class TranslationTextTypeSelectionTableViewController: UITableViewController {
    private let dataSource = DataSource()

    var selectionChanged: ((Int) -> Void)?

    var retainedPopoverPresentationHandler: UIPopoverPresentationControllerDelegate? {
        didSet {
            popoverPresentationController?.delegate = retainedPopoverPresentationHandler
        }
    }

    init(selectedIndex: Int?, items: [String]) {
        super.init(style: .plain)
        dataSource.selectedIndex = selectedIndex
        dataSource.items = items

        let block = BlockSelectionHandler<String, TableViewCell>()
        dataSource.setSelectionHandler(block)
        block.didSelectBlock = { [weak self] (_, _, indexPath) in
            self?.selectionChanged?(indexPath.item)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        popoverPresentationController?.backgroundColor = .white
        view.backgroundColor = .white
        tableView.ds_register(cellClass: TableViewCell.self)
        tableView.ds_useDataSource(dataSource)
        tableView.rowHeight = 44

        let itemsWidths = dataSource.items.map { $0.size(withFont: TableViewCell.font).width }
        let width = unwrap(itemsWidths.max()) + 70
        let height = tableView.rowHeight * CGFloat(dataSource.items.count)
        preferredContentSize = CGSize(width: width, height: height)
    }
}
