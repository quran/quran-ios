//
//  CollectionViewDataSource.swift
//
//
//  Created by Mohamed Afifi on 2024-01-10.
//

import UIKit

final class CollectionViewDataSource<
    SectionId: Hashable,
    Item: Identifiable & Hashable
>: UICollectionViewDiffableDataSource<SectionId, Item.ID> {
    // MARK: Internal

    var sections: [ListSection<SectionId, Item>] = [] {
        didSet {
            updateSections(oldSections: oldValue, newSections: sections)
        }
    }

    func section(from indexPath: IndexPath) -> ListSection<SectionId, Item>? {
        if indexPath.section < 0 || indexPath.section >= sections.count {
            return nil
        }
        return sections[indexPath.section]
    }

    func item(at indexPath: IndexPath) -> Item? {
        guard let section = section(from: indexPath) else {
            return nil
        }
        if indexPath.item < 0 || indexPath.item >= section.items.count {
            return nil
        }
        return section.items[indexPath.item]
    }

    // MARK: Private

    private func updateSections(
        oldSections: [ListSection<SectionId, Item>],
        newSections: [ListSection<SectionId, Item>]
    ) {
        var snapshot = snapshot()
        var hasDataSourceChanged = false
        defer {
            if hasDataSourceChanged {
                apply(snapshot, animatingDifferences: false)
            }
        }

        // Early return for initial update.
        guard !oldSections.isEmpty else {
            hasDataSourceChanged = true

            snapshot.deleteAllItems()
            for newSection in newSections {
                snapshot.appendSections([newSection.sectionId])
                snapshot.appendItems(newSection.items.map(\.id))
            }
            return
        }

        // Build new snapshot, if any item/section id changed.
        let oldSectionIds = oldSections.map(\.sectionId)
        let newSectionIds = newSections.map(\.sectionId)
        let oldItemIds = oldSections.map { $0.items.map(\.id) }
        let newItemIds = newSections.map { $0.items.map(\.id) }

        if oldSectionIds != newSectionIds || oldItemIds != newItemIds {
            hasDataSourceChanged = true
            snapshot = .init()
            for newSection in newSections {
                snapshot.appendSections([newSection.sectionId])
                snapshot.appendItems(newSection.items.map(\.id))
            }
        }

        // Reload updated items.
        let allOldItems = oldSections.flatMap(\.items)
        let oldItemsDictionary = Dictionary(grouping: allOldItems, by: \.id).mapValues(\.first)

        let allNewItems = newSections.flatMap(\.items)
        let newItemsDictionary = Dictionary(grouping: allNewItems, by: \.id).mapValues(\.first)

        for (itemId, newItem) in newItemsDictionary {
            if newItem != oldItemsDictionary[itemId] {
                hasDataSourceChanged = true
                snapshot.reconfigureItems([itemId])
            }
        }
    }
}
