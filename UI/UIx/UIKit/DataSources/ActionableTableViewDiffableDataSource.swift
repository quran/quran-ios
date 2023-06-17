//
//  ActionableTableViewDiffableDataSource.swift
//
//
//  Created by Afifi, Mohamed on 11/1/21.
//

import UIKit

@available(iOS 13.0, *)
open class ActionableTableViewDiffableDataSource<SectionId: Hashable, ItemId: Hashable>: UITableViewDiffableDataSource<SectionId, ItemId> {
    public struct Actions {
        public var canEditRow: ((ItemId) -> Bool) = { _ in false }
        public var commitEditing: (UITableViewCell.EditingStyle, ItemId) -> Void = { _, _ in }
    }

    public var actions = Actions()

    override public func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if let item = itemIdentifier(for: indexPath) {
            actions.commitEditing(editingStyle, item)
        }
    }

    override public func tableView(
        _ tableView: UITableView,
        canEditRowAt indexPath: IndexPath
    ) -> Bool {
        if let item = itemIdentifier(for: indexPath) {
            return actions.canEditRow(item)
        }
        return false
    }
}
