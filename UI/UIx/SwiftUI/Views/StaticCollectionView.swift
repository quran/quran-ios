//
//  StaticCollectionView.swift
//
//
//  Created by Mohamed Afifi on 2023-12-26.
//

import SwiftUI

public protocol Kindable {
    associatedtype Kind: Hashable
    var kind: Kind { get }
}

public typealias ListItem = Identifiable & Hashable

public struct AnyListItem<Id: Hashable>: ListItem {
    // MARK: Lifecycle

    public init<Item: ListItem>(_ item: Item) where Item.ID == Id {
        hashable = item
        id = item.id
        self.item = item
    }

    // MARK: Public

    public let item: any ListItem
    public let id: Id

    public static func == (lhs: AnyListItem, rhs: AnyListItem) -> Bool {
        lhs.hashable == rhs.hashable
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hashable)
    }

    // MARK: Private

    private let hashable: AnyHashable
}

public struct ListSection<SectionId: Hashable, ItemId: Hashable>: Hashable {
    // MARK: Lifecycle

    public init(sectionId: SectionId, items: [AnyListItem<ItemId>] = []) {
        self.sectionId = sectionId
        self.items = items
    }

    // MARK: Public

    public var sectionId: SectionId
    public var items: [AnyListItem<ItemId>]

    public mutating func append<ItemType: ListItem>(_ item: ItemType) where ItemType.ID == ItemId {
        items.append(AnyListItem(item))
    }
}

public struct StaticCollectionView<SectionId: Hashable, ItemId: Hashable>: View {
    // MARK: Lifecycle

    public init(
        layout: UICollectionViewLayout,
        configure: @escaping (UICollectionViewController) -> Void,
        sections: [ListSection<SectionId, ItemId>]
    ) {
        self.layout = layout
        self.configure = configure
        self.sections = sections
    }

    // MARK: Public

    public var body: some View {
        _StaticCollectionView(
            layout: layout,
            configure: configure,
            sections: sections,
            cellRegistrations: cellRegistrations
        )
    }

    // MARK: Private

    private var cellRegistrations: [ObjectIdentifier: CellRegistration<ItemId>] = [:]
    private let layout: UICollectionViewLayout
    private let configure: (UICollectionViewController) -> Void
    private let sections: [ListSection<SectionId, ItemId>]
}

extension StaticCollectionView {
    public func register<ItemType: ListItem>(
        itemType: ItemType.Type,
        content: @escaping (ItemType) -> some View
    ) -> Self {
        let typeId = ObjectIdentifier(itemType)
        precondition(cellRegistrations[typeId] == nil, "A view already registered for '\(itemType)'")
        var mutableSelf = self
        mutableSelf.cellRegistrations[typeId] = CellRegistration(itemType: itemType, content: content)
        return mutableSelf
    }
}

private struct _StaticCollectionView<SectionId: Hashable, ItemId: Hashable>: UIViewControllerRepresentable {
    let layout: UICollectionViewLayout
    let configure: (UICollectionViewController) -> Void
    let sections: [ListSection<SectionId, ItemId>]
    let cellRegistrations: [ObjectIdentifier: CellRegistration<ItemId>]

    func makeUIViewController(context: Context) -> UICollectionViewController {
        let viewController = UICollectionViewController(collectionViewLayout: layout)
        viewController.view.backgroundColor = .clear
        configure(viewController)

        context.coordinator.viewController = viewController
        context.coordinator.setUpDataSource(cellRegistrations: cellRegistrations)

        updateUIViewController(viewController, context: context)

        return viewController
    }

    func updateUIViewController(_ viewController: UICollectionViewController, context: Context) {
        let previousView = context.coordinator.parent

        if previousView.layout != layout {
            viewController.collectionView.collectionViewLayout = layout
        }

        context.coordinator.sections = sections
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

extension _StaticCollectionView {
    class Coordinator {
        // MARK: Lifecycle

        init(_ parent: _StaticCollectionView) {
            self.parent = parent
        }

        // MARK: Internal

        let parent: _StaticCollectionView
        var dataSource: UICollectionViewDiffableDataSource<SectionId, ItemId>?
        weak var viewController: UICollectionViewController?

        var sections: [ListSection<SectionId, ItemId>] = [] {
            didSet {
                updateSections(oldSections: oldValue, newSections: sections)
            }
        }

        func setUpDataSource(cellRegistrations: [ObjectIdentifier: CellRegistration<ItemId>]) {
            guard let viewController else {
                fatalError("setUpDataSource called before setting the viewController.")
            }

            for registration in cellRegistrations.values {
                viewController.collectionView.register(registration.cellType, forCellWithReuseIdentifier: registration.reuseId)
            }

            dataSource = UICollectionViewDiffableDataSource(collectionView: viewController.collectionView) {
                [weak self] _, indexPath, itemId in
                guard let self, let viewController = self.viewController else {
                    return UICollectionViewCell()
                }

                // Get the item.
                let item = sections[indexPath.section].items[indexPath.item]
                assert(item.id == itemId, "Sections data doesn't match data source snapshot.")

                // Get the registration.
                let typeId = ObjectIdentifier(type(of: item.item))
                guard let registration = cellRegistrations[typeId] else {
                    fatalError("No cell registered for '\(typeId)'")
                }

                // Get the cell.
                let cell = registration.cellBuilder(viewController, indexPath, item)
                return cell
            }
        }

        // MARK: Private

        private func updateSections(
            oldSections: [ListSection<SectionId, ItemId>],
            newSections: [ListSection<SectionId, ItemId>]
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
                for newSection in newSections {
                    snapshot.appendSections([newSection.sectionId])
                    snapshot.appendItems(newSection.items.map(\.id))
                }
                return
            }

            // Validate Ids haven't changed.
            let oldSectionIds = oldSections.map(\.sectionId)
            let newSectionIds = newSections.map(\.sectionId)
            let oldItemIds = oldSections.map { $0.items.map(\.id) }
            let newItemIds = newSections.map { $0.items.map(\.id) }
            assert(oldSectionIds == newSectionIds, "StaticCollectionView doesn't support changing sections")
            assert(oldItemIds == newItemIds, "StaticCollectionView doesn't support changing items")

            // Reload updated items.
            let allOldItems = oldSections.flatMap(\.items)
            let allNewItems = newSections.flatMap(\.items)
            for (oldItem, newItem) in zip(allOldItems, allNewItems) {
                if newItem != oldItem {
                    hasDataSourceChanged = true
                    if #available(iOS 15.0, *) {
                        snapshot.reconfigureItems([newItem.id])
                    } else {
                        snapshot.reloadItems([newItem.id])
                    }
                }
            }
        }
    }
}

private struct CellRegistration<ItemId: Hashable> {
    // MARK: Lifecycle

    init<Content: View, ItemType: ListItem>(
        itemType: ItemType.Type,
        content: @escaping (ItemType) -> Content
    ) {
        reuseId = HostingCollectionViewCell<Content>.reuseId
        cellType = HostingCollectionViewCell<Content>.self
        cellBuilder = { viewController, indexPath, item in
            let cell = viewController.collectionView.dequeueReusableCell(
                HostingCollectionViewCell<Content>.self,
                for: indexPath
            )

            guard let item = item.item as? ItemType else {
                fatalError("Incompatible item type. Expected: '\(ItemType.self)', found: '\(type(of: item.item))'")
            }

            cell.set(rootView: content(item), parentController: viewController)
            return cell
        }
    }

    // MARK: Internal

    let reuseId: String
    let cellType: AnyClass
    let cellBuilder: (UICollectionViewController, IndexPath, AnyListItem<ItemId>) -> UICollectionViewCell
}

struct StaticCollectionView_Previews: PreviewProvider {
    enum ItemKind: Hashable {
        case header
        case footer
        case suraName
        case arabic
        case translation
    }

    struct ItemId: Hashable, Kindable {
        let kind: ItemKind
        let position: Int
    }

    struct Header: ListItem {
        let position: Int

        var id: ItemId { .init(kind: .header, position: position) }
        var headerText: String { "Header" }
    }

    struct Footer: ListItem {
        let position: Int

        var id: ItemId { .init(kind: .footer, position: position) }
        var footerText: String { "Footer" }
    }

    struct SuraName: ListItem {
        let position: Int
        let name: String

        var id: ItemId { .init(kind: .suraName, position: position) }
    }

    struct Arabic: ListItem {
        let position: Int
        let arabicText: String

        var id: ItemId { .init(kind: .arabic, position: position) }
    }

    struct Translation: ListItem {
        let position: Int
        let translationText: String

        var id: ItemId { .init(kind: .translation, position: position) }
    }

    enum SectionId: Hashable {
        case header
        case footer
        case verse(_ position: Int)
    }

    struct StaticCollectionViewPreview: View {
        static let layout: UICollectionViewLayout = {
            let size = NSCollectionLayoutSize(
                widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
                heightDimension: NSCollectionLayoutDimension.estimated(99)
            )
            let item = NSCollectionLayoutItem(layoutSize: size)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: 1)
            let collectionViewLayout = UICollectionViewCompositionalLayout(section: .init(group: group))
            return collectionViewLayout
        }()

        @State var sections: [ListSection<SectionId, ItemId>] = [
            ListSection(sectionId: .header, items: [
                AnyListItem(Header(position: 0)),
            ]),
        ] + (1 ... 100).map { section($0) } + [
            ListSection(sectionId: .footer, items: [
                AnyListItem(Footer(position: 0)),
            ]),
        ]

        var body: some View {
            StaticCollectionView(
                layout: Self.layout,
                configure: { viewController in
                    viewController.collectionView.contentInsetAdjustmentBehavior = .never
                },
                sections: sections
            )
            .register(itemType: Header.self) { item in
                VStack {
                    Text("\(item.headerText.uppercased())")
                        .fontWeight(.bold)
                        .padding()
                    Divider()
                }
            }
            .register(itemType: Footer.self) { item in
                VStack {
                    Text("\(item.footerText.uppercased())")
                        .fontWeight(.bold)
                        .padding()
                }
            }
            .register(itemType: SuraName.self) { item in
                VStack {
                    HStack {
                        Spacer()
                        Text("<<< \(item.position). \(item.name) >>>")
                        Spacer()
                    }
                    .padding()
                    Divider()
                }
            }
            .register(itemType: Arabic.self) { item in
                VStack {
                    Button("Update") {
                        let sectionIndex = sections.firstIndex { $0.items.contains(AnyListItem(item)) }!
                        let itemIndex = sections[sectionIndex].items.firstIndex(of: AnyListItem(item))!
                        sections[sectionIndex].items[itemIndex] = AnyListItem(Arabic(position: item.position, arabicText: item.arabicText + " >> Updated"))
                    }
                    HStack {
                        Spacer()
                        Text("\(item.position). Arabic \(item.arabicText)")
                        Spacer()
                    }
                    Divider()
                }
                .padding()
            }
            .register(itemType: Translation.self) { item in
                VStack {
                    HStack {
                        Spacer()
                        Text("\(item.position). \(item.translationText)")
                        Spacer()
                    }
                    .padding()
                    Divider()
                }
            }
        }

        static func section(_ position: Int) -> ListSection<SectionId, ItemId> {
            var section = ListSection<SectionId, ItemId>(sectionId: .verse(position))
            section.append(SuraName(position: position, name: "Sura Name"))
            section.append(Arabic(position: position, arabicText: "Arabic"))
            section.append(Translation(position: position, translationText: "Translation"))
            return section
        }
    }

    // MARK: Internal

    static var previews: some View {
        StaticCollectionViewPreview()
    }
}
