//
//  ModernDataSource.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/3/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import GenericDataSources
import SwiftUI
import UIx
import Utilities

@MainActor
public protocol ModernDataSource: AbstractDataSource {
    var controller: UIViewController? { get set }
}

public class ModernBasicDataSource<ItemType, CellType>: BasicDataSource<ItemType, HostingTableViewCell<CellType>>, ModernDataSource
    where ItemType: Equatable, CellType: View
{
    public weak var controller: UIViewController?

    override public func ds_collectionView(
        _ collectionView: GeneralCollectionView,
        configure cell: HostingTableViewCell<CellType>,
        with item: ItemType,
        at indexPath: IndexPath
    ) {
        guard let controller else {
            return
        }
        let view = view(with: item, at: indexPath)
        cell.set(rootView: view, parentController: controller)
    }

    public func view(with item: ItemType, at indexPath: IndexPath) -> CellType {
        fatalError("\(#function) should be subclassed")
    }
}

open class ModernEditableBasicDataSource<ItemType, CellType>: EditableBasicDataSource<ItemType, HostingTableViewCell<CellType>>, ModernDataSource
    where ItemType: Equatable, CellType: View
{
    // MARK: Open

    open func view(with item: ItemType, at indexPath: IndexPath) -> CellType {
        fatalError("\(#function) should be subclassed")
    }

    // MARK: Public

    public weak var controller: UIViewController?

    override public func ds_collectionView(
        _ collectionView: GeneralCollectionView,
        configure cell: HostingTableViewCell<CellType>,
        with item: ItemType,
        at indexPath: IndexPath
    ) {
        guard let controller else {
            return
        }
        let view = view(with: item, at: indexPath)
        cell.set(rootView: view, parentController: controller)
    }

    override public func delete(item: ItemType, at indexPath: IndexPath) {
        updatingItems { items in items.remove(at: indexPath.item) }
        ds_reusableViewDelegate?.ds_deleteItems(at: [indexPath], with: .left)
        super.delete(item: item, at: indexPath)
    }
}

class ModernCompositeDataSource: CompositeDataSource {
    weak var controller: UIViewController? {
        didSet {
            for ds in dataSources {
                (ds as? ModernDataSource)?.controller = controller
            }
        }
    }

    override func add(_ dataSource: DataSource) {
        (dataSource as? ModernDataSource)?.controller = controller
        super.add(dataSource)
    }

    override func insert(_ dataSource: DataSource, at index: Int) {
        (dataSource as? ModernDataSource)?.controller = controller
        super.insert(dataSource, at: index)
    }
}
