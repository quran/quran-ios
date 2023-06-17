//
//  TableHeaderSupplementaryViewCreator.swift
//  Quran
//
//  Created by Afifi, Mohamed on 7/24/21.
//  Copyright © 2021 Quran.com. All rights reserved.
//

import GenericDataSources
import UIKit
import UIx

@MainActor
public class TableHeaderSupplementaryViewCreator: BasicSupplementaryViewCreator<String, HostingTableViewHeaderFooterView<TableHeaderView>> {
    // MARK: Lifecycle

    override public init() {
        super.init(size: CGSize(width: UITableView.automaticDimension, height: UITableView.automaticDimension))
    }

    // MARK: Public

    public weak var controller: UIViewController?

    override public func collectionView(
        _ collectionView: GeneralCollectionView,
        configure view: HostingTableViewHeaderFooterView<TableHeaderView>,
        with item: String,
        at indexPath: IndexPath
    ) {
        guard let controller else {
            return
        }
        let header = TableHeaderView(title: item)
        view.set(rootView: header, parentController: controller)
    }
}
