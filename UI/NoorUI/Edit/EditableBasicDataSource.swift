//
//  EditableBasicDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/7/17.
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

import Foundation
import GenericDataSources
import UIKit

@MainActor
protocol EditableDataSource: AbstractDataSource {
    func configureEditController(_ tableView: UITableView, navigationItem: UINavigationItem)
    func endEditing(animated: Bool)
}

open class EditableBasicDataSource<ItemType: Equatable, CellType: ReusableCell>: EquatableDataSource<ItemType, CellType>,
    EditControllerDelegate, EditableDataSource
{
    // MARK: Public

    override public var items: [ItemType] {
        didSet {
            editController.onEditableItemsUpdated()
        }
    }

    public func hasItemsToEdit() -> Bool {
        !items.isEmpty
    }

    override public func ds_collectionView(
        _ collectionView: GeneralCollectionView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forItemAt indexPath: IndexPath
    ) {
        guard editingStyle == .delete else {
            return
        }
        let item = item(at: indexPath)
        delete(item: item, at: indexPath)
    }

    override public func ds_collectionView(_ collectionView: GeneralCollectionView, willBeginEditingItemAt indexPath: IndexPath) {
        // call it in the next cycle to give isEditing a chance to change
        DispatchQueue.main.async {
            self.editingChanged()
        }
    }

    override public func ds_collectionView(_ collectionView: GeneralCollectionView, didEndEditingItemAt indexPath: IndexPath) {
        editingChanged()
    }

    // MARK: Internal

    var deleteItem: ((ItemType, IndexPath) -> Void)?

    func configureEditController(_ tableView: UITableView, navigationItem: UINavigationItem) {
        editController.configure(tableView: tableView, delegate: self, navigationItem: navigationItem)
    }

    func endEditing(animated: Bool) {
        editController.endEditing(animated)
    }

    func delete(item: ItemType, at indexPath: IndexPath) {
        deleteItem?(item, indexPath)
    }

    // MARK: Private

    private lazy var editController = EditController(usesRightBarButton: true)

    private func editingChanged() {
        editController.onEditingStateChanged()
    }
}
