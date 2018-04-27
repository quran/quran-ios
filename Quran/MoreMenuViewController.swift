//
//  MoreMenuViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/25/18.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
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

enum QuranMode {
    case arabic
    case translation
}

protocol MoreMenuViewControllerDelegate: class {
    func moreMenuViewController(_ controller: MoreMenuViewController, quranModeSelected: QuranMode)
    func moreMenuViewControllerTranslationsSelectionSelected(_ controller: MoreMenuViewController)
    func moreMenuViewController(_ controller: MoreMenuViewController, shouldShowWordPointer: Bool)
}

class MoreMenuViewController: UIViewController {

    weak var delegate: MoreMenuViewControllerDelegate?

    @IBOutlet weak var tableView: UITableView!

    private let dataSource = CompositeDataSource(sectionType: .single)
    private let empty = EmptyDataSource()
    private let arabicTranslation = MoreArabicTranslationDataSource()
    private let selection = MoreTranslationsSelectionDataSource()
    private let pointer = MoreWordByWordPointerSelectionDataSource()

    var isWordPointerActive: Bool {
        didSet {
            pointer.items[0].isSelected = isWordPointerActive
            let cell = pointer.ds_reusableViewDelegate?.ds_cellForItem(at: IndexPath(item: 0, section: 0)) as? MoreWordByWordPointerTableViewCell
            cell?.switchControl.setOn(isWordPointerActive, animated: true)
        }
    }

    init(mode: QuranMode, isWordPointerActive: Bool) {
        self.isWordPointerActive = isWordPointerActive
        super.init(nibName: nil, bundle: nil)

        arabicTranslation.itemHeight = 44
        selection.itemHeight = 44
        pointer.itemHeight = 44
        empty.itemHeight = 12

        arabicTranslation.items = [[
            SelectableItem(text: l("menu.arabic"), isSelected: mode == .arabic) { [weak self] _ in
                self?.arabicSelected()
            },
            SelectableItem(text: l("menu.translation"), isSelected: mode == .translation) { [weak self] _ in
                self?.translationsSelected()
            }
        ]]
        selection.items = [l("menu.select_translation")]
        pointer.items = [SelectableItem(text: l("menu.pointer"), isSelected: isWordPointerActive) { [weak self] item in
            guard let `self` = self else { return }
            self.delegate?.moreMenuViewController(self, shouldShowWordPointer: item.isSelected)
        }]
        empty.items = [()]

        let selectionHandler = BlockSelectionHandler<String, MoreTranslationsSelectionTableViewCell>()
        selectionHandler.didSelectBlock = { [weak self] (_, _, _) in
            guard let `self` = self else { return }
            self.delegate?.moreMenuViewControllerTranslationsSelectionSelected(self)
        }
        selection.setSelectionHandler(selectionHandler)

        dataSource.add(arabicTranslation)

        if mode == .translation {
            dataSource.add(selection)
        } else {
            dataSource.add(empty)
            dataSource.add(pointer)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.ds_register(cellClass: EmptyTableViewCell.self)
        tableView.ds_register(cellNib: MoreArabicTranslationTableViewCell.self)
        tableView.ds_register(cellNib: MoreWordByWordPointerTableViewCell.self)
        tableView.ds_register(cellNib: MoreTranslationsSelectionTableViewCell.self)
        tableView.ds_useDataSource(dataSource)

        updateSize()
    }

    private func updateSize() {
        var height: CGFloat = 0
        for section in 0..<dataSource.ds_numberOfSections() {
            for item in 0..<dataSource.ds_numberOfItems(inSection: section) {
                let indexPath = IndexPath(item: item, section: section)
                height += dataSource.tableView(tableView, heightForRowAt: indexPath)
            }
        }
        preferredContentSize = CGSize(width: 280, height: height - 1)
    }

    private func remove(dataSource child: DataSource) {
        if let index = dataSource.index(of: child) {
            dataSource.remove(at: index)
            dataSource.ds_reusableViewDelegate?.ds_deleteItems(at: [IndexPath(item: index, section: 0)], with: .fade)
        }
    }

    private func insert(dataSource child: DataSource) {
        guard !dataSource.contains(child) else {
            return
        }
        dataSource.add(child)
        let indexPath = IndexPath(item: dataSource.dataSources.count - 1, section: 0)
        dataSource.ds_reusableViewDelegate?.ds_insertItems(at: [indexPath], with: .fade)
    }

    private func arabicSelected() {
        tableView.ds_performBatchUpdates({
            self.remove(dataSource: self.selection)
            self.insert(dataSource: self.empty)
            self.insert(dataSource: self.pointer)
        }, completion: nil)

        delegate?.moreMenuViewController(self, quranModeSelected: .arabic)
        updateSize()
    }

    private func translationsSelected() {
        tableView.ds_performBatchUpdates({
            self.remove(dataSource: self.pointer)
            self.remove(dataSource: self.empty)
            self.insert(dataSource: self.selection)
        }, completion: nil)

        delegate?.moreMenuViewController(self, quranModeSelected: .translation)
        updateSize()
    }
}

private struct SelectableItem {
    let text: String
    var isSelected: Bool
    let onSelection: (SelectableItem) -> Void
}

private class MoreArabicTranslationDataSource: BasicDataSource<[SelectableItem], MoreArabicTranslationTableViewCell> {

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: MoreArabicTranslationTableViewCell,
                                    with items: [SelectableItem],
                                    at indexPath: IndexPath) {
        cell.segmentedControl.removeAllSegments()
        for (index, item) in items.enumerated() {
            cell.segmentedControl.insertSegment(withTitle: item.text, at: index, animated: false)
            if item.isSelected {
                cell.segmentedControl.selectedSegmentIndex = index
            }
        }
        cell.onSegmentChanged = { [weak self] segment in
            var mutableItems = items
            for var item in mutableItems {
                item.isSelected = false
            }
            mutableItems[segment].isSelected = true
            self?.items[indexPath.item] = mutableItems
            mutableItems[segment].onSelection(mutableItems[segment])
        }
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}

private class MoreTranslationsSelectionDataSource: BasicDataSource<String, MoreTranslationsSelectionTableViewCell> {

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: MoreTranslationsSelectionTableViewCell,
                                    with item: String,
                                    at indexPath: IndexPath) {
        cell.textLabel?.text = item
    }
}

private class MoreWordByWordPointerSelectionDataSource: BasicDataSource<SelectableItem, MoreWordByWordPointerTableViewCell> {

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: MoreWordByWordPointerTableViewCell,
                                    with item: SelectableItem,
                                    at indexPath: IndexPath) {
        cell.textLabel?.text = item.text
        cell.switchControl.isOn = item.isSelected
        cell.onSwitchChanged = { [weak self] isOn in
            var mutableItem = item
            mutableItem.isSelected = isOn
            self?.items[indexPath.item] = mutableItem
            mutableItem.onSelection(mutableItem)
        }
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}
