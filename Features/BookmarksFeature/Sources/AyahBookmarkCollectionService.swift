#if QURAN_SYNC
//
//  AyahBookmarkCollectionService.swift
//
//  Created by Ahmed Nabil on 2026-05-06.
//

import MobileSync
import QuranAnnotations
import QuranKit
import ReadingService
import VLogging

public struct AyahBookmarkCollection {
    public let collection: Collection_
    public let bookmarks: [AyahCollectionBookmark]
}

public struct AyahCollectionBookmark {
    public let bookmark: CollectionAyahBookmark
    public let ayah: AyahNumber
}

private enum AyahBookmarkCollectionName {
    static let oldPageBookmarks = "Old Page Bookmarks"
}

private extension HighlightColor {
    init?(collectionName: String) {
        switch collectionName.lowercased() {
        case "red": self = .red
        case "green": self = .green
        case "blue": self = .blue
        case "yellow": self = .yellow
        case "purple": self = .purple
        default: return nil
        }
    }
}

public enum AyahBookmarkCollectionKind: Equatable {
    case oldPageBookmarks
    case colored(HighlightColor)
    case user

    fileprivate init(collection: Collection_) {
        let normalizedName = collection.name.lowercased()
        if normalizedName == AyahBookmarkCollectionName.oldPageBookmarks.lowercased() {
            self = .oldPageBookmarks
        } else if let color = HighlightColor(collectionName: collection.name) {
            self = .colored(color)
        } else {
            self = .user
        }
    }

    var highlightColor: HighlightColor? {
        guard case .colored(let color) = self else {
            return nil
        }
        return color
    }

    var isOldPageBookmarks: Bool {
        self == .oldPageBookmarks
    }
}

extension AyahBookmarkCollection {
    public var kind: AyahBookmarkCollectionKind {
        AyahBookmarkCollectionKind(collection: collection)
    }
}

public struct AyahBookmarkCollectionsSequence: AsyncSequence {
    public typealias Element = [AyahBookmarkCollection]

    public struct AsyncIterator: AsyncIteratorProtocol {
        init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
            var iterator = sequence.makeAsyncIterator()
            nextValue = {
                try await iterator.next()
            }
        }

        public mutating func next() async throws -> Element? {
            try await nextValue()
        }

        private let nextValue: () async throws -> Element?
    }

    init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
        makeIterator = {
            AsyncIterator(sequence)
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        makeIterator()
    }

    private let makeIterator: () -> AsyncIterator
}

public struct AyahBookmarkCollectionService {
    // MARK: Lifecycle

    public init(
        quranDataService: QuranDataService,
        readingPreferences: ReadingPreferences = .shared
    ) {
        self.quranDataService = quranDataService
        self.readingPreferences = readingPreferences
    }

    // MARK: Public

    public func createCollection(named name: String) async throws {
        try await quranDataService.createCollection(named: name)
    }

    public func addAyahBookmarkToCollection(collectionLocalId: String, ayah: AyahNumber) async throws {
        _ = try await quranDataService.addAyahBookmarkToCollection(
            collectionLocalId: collectionLocalId,
            sura: Int32(ayah.sura.suraNumber),
            ayah: Int32(ayah.ayah)
        )
    }

    public func removeCollection(localId: String) async throws {
        try await quranDataService.removeCollection(localId: localId)
    }

    public func removeBookmarkFromCollection(_ bookmark: AyahCollectionBookmark) async throws {
        try await quranDataService.removeAyahBookmarkFromCollection(bookmark.bookmark)
    }

    public func addAyahBookmarksIfNeeded(
        _ ayahs: [AyahNumber],
        to collection: AyahBookmarkCollection
    ) async throws {
        for ayah in Self.ayahsToAdd(ayahs, to: collection) {
            try await addAyahBookmarkToCollection(
                collectionLocalId: collection.collection.localId,
                ayah: ayah
            )
        }
    }

    public func removeAyahBookmarksIfNeeded(
        _ ayahs: [AyahNumber],
        from collections: [AyahBookmarkCollection]
    ) async throws {
        let ayahs = Set(ayahs)
        for collection in collections {
            for bookmark in collection.bookmarks where ayahs.contains(bookmark.ayah) {
                try await removeBookmarkFromCollection(bookmark)
            }
        }
    }

    public func collectionsSequence() -> AyahBookmarkCollectionsSequence {
        let quranDataService = quranDataService
        let readingPreferences = readingPreferences
        let sequence = quranDataService.collectionsWithBookmarksSequence()
            .map { collections in
                let collections = Self.collections(
                    from: collections,
                    quran: readingPreferences.reading.quran
                )
                await quranDataService.createHighlightCollectionsIfNeeded(collections)
                return collections
            }
        return AyahBookmarkCollectionsSequence(sequence)
    }

    // MARK: Internal

    static func collections(from collections: [CollectionWithAyahBookmarks], quran: Quran) -> [AyahBookmarkCollection] {
        collections.map { collection in
            AyahBookmarkCollection(
                collection: collection.collection,
                bookmarks: collection.bookmarks.compactMap { bookmark(for: $0, quran: quran) }
            )
        }
    }

    static func ayahsToAdd(_ ayahs: [AyahNumber], to collection: AyahBookmarkCollection) -> [AyahNumber] {
        let existingAyahs = Set(collection.bookmarks.map(\.ayah))
        var seenAyahs = Set<AyahNumber>()

        return ayahs.filter { ayah in
            guard !existingAyahs.contains(ayah), !seenAyahs.contains(ayah) else {
                return false
            }
            seenAyahs.insert(ayah)
            return true
        }
    }

    // MARK: Private

    private let quranDataService: QuranDataService
    private let readingPreferences: ReadingPreferences

    private static func bookmark(for bookmark: CollectionAyahBookmark, quran: Quran) -> AyahCollectionBookmark? {
        guard let ayah = AyahNumber(
            quran: quran,
            sura: Int(bookmark.sura),
            ayah: Int(bookmark.ayah)
        ) else {
            return nil
        }

        return AyahCollectionBookmark(bookmark: bookmark, ayah: ayah)
    }
}

actor HighlightCollectionCreationPlanner {
    func reserveMissingCollectionNames(from collections: [AyahBookmarkCollection]) -> [String] {
        let existingNames = Set(collections.map(\.collection.name))
        reservedCollectionNames.formUnion(existingNames)

        let missingCollectionNames = HighlightColor.sortedColors
            .map(\.collectionName)
            .filter { !existingNames.contains($0) && !reservedCollectionNames.contains($0) }

        reservedCollectionNames.formUnion(missingCollectionNames)
        return missingCollectionNames
    }

    func releaseCollectionNames(_ names: some Sequence<String>) {
        reservedCollectionNames.subtract(names)
    }

    private var reservedCollectionNames: Set<String> = []
}

private extension QuranDataService {
    func createHighlightCollectionsIfNeeded(_ collections: [AyahBookmarkCollection]) async {
        let planner = await highlightCollectionCreationPlanners.planner(for: self)
        let missingCollectionNames = await planner.reserveMissingCollectionNames(from: collections)

        let failedCollections = await createHighlightCollections(named: missingCollectionNames)
        if !failedCollections.isEmpty {
            await planner.releaseCollectionNames(failedCollections)
        }
    }

    private func createHighlightCollections(named names: [String]) async -> [String] {
        await withTaskGroup(of: String?.self) { group in
            for name in names {
                group.addTask {
                    do {
                        try await self.createCollection(named: name)
                        return nil
                    } catch {
                        logger.error("Bookmarks: failed to create highlight collection '\(name)': \(error)")
                        return name
                    }
                }
            }

            var failures: [String] = []
            for await name in group {
                if let name {
                    failures.append(name)
                }
            }

            return failures
        }
    }
}

private let highlightCollectionCreationPlanners = HighlightCollectionCreationPlanners()

private actor HighlightCollectionCreationPlanners {
    func planner(for quranDataService: QuranDataService) -> HighlightCollectionCreationPlanner {
        let id = ObjectIdentifier(quranDataService)
        let planner = planners[id] ?? HighlightCollectionCreationPlanner()
        planners[id] = planner
        return planner
    }

    private var planners: [ObjectIdentifier: HighlightCollectionCreationPlanner] = [:]
}

#endif
