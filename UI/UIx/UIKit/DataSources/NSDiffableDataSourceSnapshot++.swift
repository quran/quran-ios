//
//  NSDiffableDataSourceSnapshot++.swift
//
//
//  Created by Afifi, Mohamed on 9/6/21.
//

import UIKit

extension NSDiffableDataSourceSnapshot {
    public mutating func appendSections(_ identifiers: SectionIdentifierType...) {
        appendSections(identifiers)
    }

    public mutating func appendItems(_ identifiers: ItemIdentifierType...) {
        appendItems(identifiers)
    }
}
