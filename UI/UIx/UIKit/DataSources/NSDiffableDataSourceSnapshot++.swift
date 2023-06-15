//
//  NSDiffableDataSourceSnapshot++.swift
//
//
//  Created by Afifi, Mohamed on 9/6/21.
//

import UIKit

@available(iOS 13.0, *)
extension NSDiffableDataSourceSnapshot {
    public mutating func appendSections(_ identifiers: SectionIdentifierType...) {
        appendSections(identifiers)
    }

    public mutating func appendItems(_ identifiers: ItemIdentifierType...) {
        appendItems(identifiers)
    }

    public func hasSameItems(_ other: Self) -> Bool {
        if sectionIdentifiers != other.sectionIdentifiers {
            return false
        }
        for section in 0 ..< numberOfSections {
            let sectionId = sectionIdentifiers[section]
            if itemIdentifiers(inSection: sectionId) != other.itemIdentifiers(inSection: sectionId) {
                return false
            }
        }

        return true
    }

    public mutating func backwardCompatibleReconfigureItems(_ identifiers: [ItemIdentifierType]) {
        if #available(iOS 15.0, *) {
            reconfigureItems(identifiers)
        } else {
            reloadItems(identifiers)
        }
    }
}
