#if QURAN_SYNC
    //
    //  HighlightBookmarkCollections.swift
    //
    //  Created by Ahmed Nabil on 2026-05-10.
    //

    import QuranAnnotations

    enum HighlightBookmarkCollections {
        static let names = HighlightColor.allCases.map(\.collectionName)

        static func ensure(in collections: [AyahBookmarkCollection], using service: AyahBookmarkCollectionService) async throws {
            let existingNames = Set(collections.map(\.collection.name))
            for name in names where !existingNames.contains(name) {
                try await service.createCollection(named: name)
            }
        }
    }
#endif
