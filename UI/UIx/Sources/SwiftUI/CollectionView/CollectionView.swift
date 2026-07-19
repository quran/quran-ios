//
//  CollectionView.swift
//
//
//  Created by Mohamed Afifi on 2023-12-26.
//

import SwiftUI

public enum ScrollAnchor {
    case center
}

public struct CollectionView<
    SectionId: Hashable,
    Item: Identifiable & Hashable,
    ItemContent: View
>: View {
    // MARK: Lifecycle

    public init(
        layout: UICollectionViewLayout,
        sections: [ListSection<SectionId, Item>],
        @ViewBuilder content: @escaping (SectionId, Item) -> ItemContent
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
            content: content,
            isPagingEnabled: isPagingEnabled,
            usesCollectionViewSafeAreaForCellLayoutMargins: usesCollectionViewSafeAreaForCellLayoutMargins,
            scrollAnchorId: scrollAnchorId,
            scrollAnchor: scrollAnchor
        )
    }

    public func configureCollectionView(configure: @escaping (UICollectionView) -> Void) -> Self {
        mutateSelf {
            $0.configure = configure
        }
    }

    public func anchorScrollTo(
        id scrollAnchorId: Binding<Item.ID>,
        anchor: ScrollAnchor = .center
    ) -> Self {
        mutateSelf {
            $0.scrollAnchorId = scrollAnchorId
            $0.scrollAnchor = anchor
        }
    }

    public func pagingEnabled(_ isPagingEnabled: Bool) -> Self {
        mutateSelf {
            $0.isPagingEnabled = isPagingEnabled
        }
    }

    public func usesCollectionViewSafeAreaForCellLayoutMargins(_ flag: Bool) -> Self {
        mutateSelf {
            $0.usesCollectionViewSafeAreaForCellLayoutMargins = flag
        }
    }

    // MARK: Private

    private let layout: UICollectionViewLayout
    private let sections: [ListSection<SectionId, Item>]
    private let content: (SectionId, Item) -> ItemContent
    private var configure: ((UICollectionView) -> Void)?

    private var isPagingEnabled: Bool = false
    private var usesCollectionViewSafeAreaForCellLayoutMargins: Bool = false

    private var scrollAnchorId: Binding<Item.ID>?
    private var scrollAnchor: ScrollAnchor = .center
}

private struct CollectionViewBody<
    SectionId: Hashable,
    Item: Identifiable & Hashable,
    ItemContent: View
>: UIViewControllerRepresentable {
    typealias UIViewControllerType = CollectionViewController<SectionId, Item, ItemContent>

    // MARK: Internal

    let layout: UICollectionViewLayout
    let sections: [ListSection<SectionId, Item>]
    let configure: ((UICollectionView) -> Void)?
    let content: (SectionId, Item) -> ItemContent

    let isPagingEnabled: Bool
    let usesCollectionViewSafeAreaForCellLayoutMargins: Bool

    let scrollAnchorId: Binding<Item.ID>?
    let scrollAnchor: ScrollAnchor

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let viewController = UIViewControllerType(collectionViewLayout: layout, content: content)
        configure?(viewController.collectionView)

        context.coordinator.viewController = viewController
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

        viewController.dataSource?.sections = sections

        viewController.usesCollectionViewSafeAreaForCellLayoutMargins = usesCollectionViewSafeAreaForCellLayoutMargins

        viewController.scroller.isPagingEnabled = isPagingEnabled
        viewController.scroller.onScrollAnchorIdUpdated = {
            scrollAnchorId?.wrappedValue = $0
        }
        if let scrollAnchorId {
            viewController.scroller.anchorScrollTo(id: scrollAnchorId.wrappedValue, anchor: scrollAnchor)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

extension CollectionViewBody {
    class Coordinator {
        let parent: CollectionViewBody
        weak var viewController: UIViewControllerType?

        init(_ parent: CollectionViewBody) {
            self.parent = parent
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
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 60
            let collectionViewLayout = UICollectionViewCompositionalLayout(section: section)
            return collectionViewLayout
        }()

        @State var sections: [ListSection<SectionId, Item>] = [
            ListSection(
                sectionId: .main,
                items: (1 ... 100).map { Item(id: $0, text: "Item \($0)") }
            ),
        ]

        @State var scrollAnchorId: Int = 45 {
            didSet {
                print("Scrolled to item \(scrollAnchorId)")
            }
        }

        var body: some View {
            ZStack {
                CollectionView(layout: layout, sections: sections) { _, item in
                    VStack {
                        Text(item.text)
                            .padding()
                        Divider()
                    }
                    .border(.purple)
                }
                .configureCollectionView { collectionView in
                    collectionView.contentInsetAdjustmentBehavior = .never
                }
                .anchorScrollTo(id: $scrollAnchorId)

                Circle()
                    .foregroundColor(.purple)
                    .frame(width: 10)
            }
        }
    }

    // MARK: Internal

    static var previews: some View {
        StaticCollectionViewPreview()
    }
}
