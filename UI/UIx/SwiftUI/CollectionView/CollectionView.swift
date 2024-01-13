//
//  CollectionView.swift
//
//
//  Created by Mohamed Afifi on 2023-12-26.
//

import SwiftUI

public struct CollectionView<
    SectionId: Hashable,
    Item: Identifiable & Hashable,
    ItemContent: View
>: View {
    // MARK: Lifecycle

    public init(
        layout: UICollectionViewLayout,
        sections: [ListSection<SectionId, Item>],
        content: @escaping (SectionId, Item) -> ItemContent
    ) {
        self.layout = layout
        self.sections = sections
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        CollectionViewBody(
            layout: layout,
            sections: sections,
            configure: configure,
            content: content
        )
    }

    public func configureCollectionView(configure: @escaping (UICollectionView) -> Void) -> Self {
        var collectionView = self
        collectionView.configure = configure
        return collectionView
    }

    // MARK: Private

    private let layout: UICollectionViewLayout
    private let sections: [ListSection<SectionId, Item>]
    private let content: (SectionId, Item) -> ItemContent
    private var configure: ((UICollectionView) -> Void)?
}

private struct CollectionViewBody<
    SectionId: Hashable,
    Item: Identifiable & Hashable,
    ItemContent: View
>: UIViewControllerRepresentable {
    typealias UIViewControllerType = CollectionViewController<ItemContent>

    // MARK: Internal

    let layout: UICollectionViewLayout
    let sections: [ListSection<SectionId, Item>]
    let configure: ((UICollectionView) -> Void)?
    let content: (SectionId, Item) -> ItemContent

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let viewController = UIViewControllerType(collectionViewLayout: layout)
        viewController.collectionView.backgroundColor = .clear
        configure?(viewController.collectionView)

        context.coordinator.viewController = viewController
        context.coordinator.setUpDataSource(content: content)

        updateUIViewController(viewController, context: context)

        return viewController
    }

    func updateUIViewController(_ viewController: UIViewControllerType, context: Context) {
        // Update the reader
        if let proxy = context.environment._collectionView {
            if proxy.wrappedValue !== viewController.collectionView {
                DispatchQueue.main.async {
                    proxy.wrappedValue = viewController.collectionView
                }
            }
        }

        let previousView = context.coordinator.parent
        if previousView.layout != layout {
            viewController.collectionView.collectionViewLayout = layout
        }

        context.coordinator.updateData(sections: sections)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

extension CollectionViewBody {
    class Coordinator {
        // MARK: Lifecycle

        init(_ parent: CollectionViewBody) {
            self.parent = parent
        }

        // MARK: Internal

        let parent: CollectionViewBody
        var dataSource: UICollectionViewDiffableDataSource<SectionId, Item.ID>?
        weak var viewController: UIViewControllerType?

        func updateData(sections: [ListSection<SectionId, Item>]) {
            let oldSections = self.sections
            self.sections = sections

            updateData(oldSections: oldSections, newSections: sections)
        }

        func setUpDataSource(content: @escaping (SectionId, Item) -> ItemContent) {
            guard let viewController else {
                fatalError("setUpDataSource called before setting the viewController.")
            }

            let cellType = UIViewControllerType.CellType.self
            viewController.collectionView.register(cellType, forCellWithReuseIdentifier: cellType.reuseId)

            dataSource = UICollectionViewDiffableDataSource(collectionView: viewController.collectionView) {
                [weak self] _, indexPath, itemId in
                guard let self, let viewController = self.viewController else {
                    return UICollectionViewCell()
                }

                // Get the item.
                let section = sections[indexPath.section]
                let item = sections[indexPath.section].items[indexPath.item]
                assert(item.id == itemId, "Sections data doesn't match data source snapshot.")

                // Get & configure the cell.
                let cell = viewController.collectionView.dequeueReusableCell(UIViewControllerType.CellType.self, for: indexPath)
                cell.configure(content: content(section.id, item), dataId: itemId)

                return cell
            }
        }

        // MARK: Private

        private var sections: [ListSection<SectionId, Item>] = []

        private func updateData(
            oldSections: [ListSection<SectionId, Item>],
            newSections: [ListSection<SectionId, Item>]
        ) {
            guard let dataSource else {
                return
            }

            var snapshot = dataSource.snapshot()
            var hasDataSourceChanged = false
            defer {
                if hasDataSourceChanged {
                    dataSource.apply(snapshot, animatingDifferences: false)
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
                    snapshot.backwardCompatibleReconfigureItems([itemId])
                }
            }
        }
    }
}

struct StaticCollectionView_Previews: PreviewProvider {
    struct Item: Identifiable & Hashable {
        let id: Int
        let text: String
    }

    enum SectionId: Hashable {
        case main
    }

    struct StaticCollectionViewPreview: View {
        @State var layout: UICollectionViewLayout = {
            let size = NSCollectionLayoutSize(
                widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
                heightDimension: NSCollectionLayoutDimension.estimated(99)
            )
            let item = NSCollectionLayoutItem(layoutSize: size)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: 1)
            let collectionViewLayout = UICollectionViewCompositionalLayout(section: .init(group: group))
            return collectionViewLayout
        }()

        @State var sections: [ListSection<SectionId, Item>] = [
            ListSection(
                sectionId: .main,
                items: (1 ... 100).map { Item(id: $0, text: "Item \($0)") }
            ),
        ]

        var body: some View {
            CollectionView(layout: layout, sections: sections) { _, item in
                VStack {
                    Text("\(item.text.uppercased())")
                        .fontWeight(.bold)
                        .padding()
                    Divider()
                }
            }
            .configureCollectionView { collectionView in
                collectionView.contentInsetAdjustmentBehavior = .never
            }
        }
    }

    // MARK: Internal

    static var previews: some View {
        StaticCollectionViewPreview()
    }
}
