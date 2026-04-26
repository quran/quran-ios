import Foundation
import QuranAnnotations
import QuranKit

#if QURAN_SYNC
    import MobileSync
    import MobileSyncSupport
#endif

public struct HighlightBookmarkSnapshot: Equatable, Hashable, Sendable {
    public init(sura: Int, ayah: Int, modifiedDate: Date) {
        self.sura = sura
        self.ayah = ayah
        self.modifiedDate = modifiedDate
    }

    public let sura: Int
    public let ayah: Int
    public let modifiedDate: Date
}

public struct HighlightCollectionSnapshot: Equatable, Sendable {
    public init(name: String, bookmarks: [HighlightBookmarkSnapshot]) {
        self.name = name
        self.bookmarks = bookmarks
    }

    public let name: String
    public let bookmarks: [HighlightBookmarkSnapshot]
}

public enum HighlightCollection: Int, CaseIterable, Identifiable, Sendable {
    case red
    case green
    case blue
    case yellow
    case purple

    // MARK: Lifecycle

    public init(color: HighlightColor) {
        switch color {
        case .red: self = .red
        case .green: self = .green
        case .blue: self = .blue
        case .yellow: self = .yellow
        case .purple: self = .purple
        }
    }

    // MARK: Public

    public var id: Int { rawValue }

    public var color: HighlightColor {
        switch self {
        case .red: .red
        case .green: .green
        case .blue: .blue
        case .yellow: .yellow
        case .purple: .purple
        }
    }

    public var localizationKey: String {
        switch self {
        case .red: "highlights.color.red"
        case .green: "highlights.color.green"
        case .blue: "highlights.color.blue"
        case .yellow: "highlights.color.yellow"
        case .purple: "highlights.color.purple"
        }
    }

    public var collectionName: String {
        switch self {
        case .red: "red"
        case .green: "green"
        case .blue: "blue"
        case .yellow: "yellow"
        case .purple: "purple"
        }
    }

    public static func count(in collections: [HighlightCollectionSnapshot]) -> Int {
        allCases.reduce(0) { $0 + $1.count(in: collections) }
    }

    public static func collection(for name: String) -> HighlightCollection? {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allCases.first { $0.collectionName == normalizedName }
    }

    public static func highlightColorsByVerse(
        in collections: [HighlightCollectionSnapshot],
        quran: Quran
    ) -> [AyahNumber: HighlightColor] {
        var colorsByVerse: [AyahNumber: HighlightColor] = [:]
        for collection in collections {
            guard let color = Self.collection(for: collection.name)?.color else {
                continue
            }
            for bookmark in collection.bookmarks {
                guard let ayah = AyahNumber(quran: quran, sura: bookmark.sura, ayah: bookmark.ayah) else {
                    continue
                }
                colorsByVerse[ayah] = color
            }
        }
        return colorsByVerse
    }

    public func count(in collections: [HighlightCollectionSnapshot]) -> Int {
        bookmarks(in: collections).count
    }

    public func bookmarks(in collections: [HighlightCollectionSnapshot]) -> [HighlightBookmarkSnapshot] {
        collections
            .filter { Self.collection(for: $0.name) == self }
            .flatMap(\.bookmarks)
            .sorted { $0.modifiedDate > $1.modifiedDate }
    }
}

#if QURAN_SYNC
    extension HighlightCollection {
        public static func updates(from syncService: SyncService) -> AsyncThrowingStream<[HighlightCollectionSnapshot], Error> {
            AsyncThrowingStream { continuation in
                let task = Task { @MainActor in
                    do {
                        for try await collections in syncService.collectionsWithBookmarksSequence() {
                            continuation.yield(collections.map(snapshot(from:)))
                        }
                        continuation.finish()
                    } catch is CancellationError {
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }

                continuation.onTermination = { _ in
                    task.cancel()
                }
            }
        }

        public static func setHighlight(
            verses: [AyahNumber],
            color: HighlightColor,
            syncService: SyncService,
            bookmarkCollectionService: BookmarkCollectionService
        ) async throws {
            guard !verses.isEmpty else {
                return
            }

            let target = try await ensureCollection(
                for: HighlightCollection(color: color),
                syncService: syncService,
                bookmarkCollectionService: bookmarkCollectionService
            )
            let collections = try await collectionsSnapshot(from: syncService)
            let highlightCollections = collections.filter { collection(for: $0.collection.name) != nil }
            let otherCollections = highlightCollections.filter { $0.collection.localId != target.collection.localId }

            for verse in verses {
                for collection in otherCollections {
                    try await removeBookmarks(
                        matching: verse,
                        from: collection,
                        bookmarkCollectionService: bookmarkCollectionService
                    )
                }

                guard !target.contains(verse) else {
                    continue
                }
                try await bookmarkCollectionService.addAyahBookmark(verse, toCollectionLocalId: target.collection.localId)
            }
        }

        public static func removeHighlights(
            verses: [AyahNumber],
            syncService: SyncService,
            bookmarkCollectionService: BookmarkCollectionService
        ) async throws {
            guard !verses.isEmpty else {
                return
            }

            let collections = try await collectionsSnapshot(from: syncService)
                .filter { collection(for: $0.collection.name) != nil }
            for verse in verses {
                for collection in collections {
                    try await removeBookmarks(
                        matching: verse,
                        from: collection,
                        bookmarkCollectionService: bookmarkCollectionService
                    )
                }
            }
        }

        // MARK: Private

        private enum HighlightCollectionError: Error {
            case collectionUnavailable(String)
        }

        private static func ensureCollection(
            for highlightCollection: HighlightCollection,
            syncService: SyncService,
            bookmarkCollectionService: BookmarkCollectionService
        ) async throws -> CollectionWithBookmarks {
            if let existing = try await findCollection(for: highlightCollection, syncService: syncService) {
                return existing
            }

            try await bookmarkCollectionService.createCollection(named: highlightCollection.collectionName)

            for _ in 0 ..< 5 {
                if let created = try await findCollection(for: highlightCollection, syncService: syncService) {
                    return created
                }
                await Task.yield()
            }

            if let created = try await findCollection(for: highlightCollection, syncService: syncService) {
                return created
            }
            throw HighlightCollectionError.collectionUnavailable(highlightCollection.collectionName)
        }

        private static func findCollection(
            for highlightCollection: HighlightCollection,
            syncService: SyncService
        ) async throws -> CollectionWithBookmarks? {
            try await collectionsSnapshot(from: syncService)
                .first { $0.collection.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == highlightCollection.collectionName }
        }

        private static func collectionsSnapshot(from syncService: SyncService) async throws -> [CollectionWithBookmarks] {
            for try await collections in syncService.collectionsWithBookmarksSequence() {
                return collections
            }
            return []
        }

        private static func removeBookmarks(
            matching verse: AyahNumber,
            from collection: CollectionWithBookmarks,
            bookmarkCollectionService: BookmarkCollectionService
        ) async throws {
            for case let bookmark as CollectionBookmark.AyahBookmark in collection.bookmarks where bookmark.matches(verse) {
                try await bookmarkCollectionService.removeBookmark(
                    bookmark.bookmark,
                    fromCollectionLocalId: collection.collection.localId
                )
            }
        }

        private static func snapshot(from collection: CollectionWithBookmarks) -> HighlightCollectionSnapshot {
            HighlightCollectionSnapshot(
                name: collection.collection.name,
                bookmarks: collection.bookmarks.compactMap(snapshot(from:))
            )
        }

        private static func snapshot(from bookmark: CollectionBookmark) -> HighlightBookmarkSnapshot? {
            guard let bookmark = bookmark as? CollectionBookmark.AyahBookmark else {
                return nil
            }

            return HighlightBookmarkSnapshot(
                sura: Int(bookmark.sura),
                ayah: Int(bookmark.ayah),
                modifiedDate: bookmark.lastUpdated
            )
        }
    }

    private extension CollectionWithBookmarks {
        func contains(_ verse: AyahNumber) -> Bool {
            bookmarks.contains { bookmark in
                guard let bookmark = bookmark as? CollectionBookmark.AyahBookmark else {
                    return false
                }
                return bookmark.matches(verse)
            }
        }
    }

    private extension CollectionBookmark.AyahBookmark {
        var bookmark: Bookmark.AyahBookmark {
            Bookmark.AyahBookmark(
                sura: sura,
                ayah: ayah,
                lastUpdated: lastUpdated,
                localId: bookmarkLocalId
            )
        }

        func matches(_ verse: AyahNumber) -> Bool {
            Int(sura) == verse.sura.suraNumber && Int(ayah) == verse.ayah
        }
    }
#endif
