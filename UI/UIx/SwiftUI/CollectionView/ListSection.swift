//
//  ListSection.swift
//
//
//  Created by Mohamed Afifi on 2024-01-07.
//

public struct ListSection<
    SectionId: Hashable,
    Item: Identifiable & Hashable
>: Hashable, Identifiable {
    // MARK: Lifecycle

    public init(sectionId: SectionId, items: [Item] = []) {
        self.sectionId = sectionId
        self.items = items
    }

    // MARK: Public

    public var sectionId: SectionId
    public var items: [Item]

    public var id: SectionId { sectionId }

    public mutating func append(_ item: Item) {
        items.append(item)
    }
}

extension ListSection {
    public func mapItems<NewItem>(_ transform: (Item) -> NewItem) -> ListSection<SectionId, NewItem>
        where NewItem: Identifiable & Hashable
    {
        ListSection<SectionId, NewItem>(sectionId: sectionId, items: items.map(transform))
    }
}
