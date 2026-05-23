#if QURAN_SYNC
    //
    //  AyahBookmarkCollectionPickerViewModel.swift
    //
    //  Created by Ahmed Nabil on 2026-05-09.
    //

    import AnnotationsService
    import Foundation
    import QuranAnnotations
    import QuranKit
    import VLogging

    @MainActor
    final class AyahBookmarkCollectionPickerViewModel: ObservableObject {
        // MARK: Lifecycle

        init(
            ayahBookmarkCollectionService: AyahBookmarkCollectionService,
            readingBookmarkService: ReadingBookmarkService,
            verses: [AyahNumber],
            didUpdateReadingBookmark: @escaping (QuranReadingBookmark?) -> Void,
            didFinish: @escaping () -> Void
        ) {
            self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
            self.readingBookmarkService = readingBookmarkService
            self.verses = verses
            self.didUpdateReadingBookmark = didUpdateReadingBookmark
            self.didFinish = didFinish
        }

        // MARK: Internal

        @Published var collections: [AyahBookmarkCollection] = []
        @Published var selectedCollectionIDs: Set<String> = []
        @Published var selectedHighlightCollectionID: String?
        @Published var readingBookmark: QuranReadingBookmark?
        @Published var error: Error?

        var bookmarkCollections: [AyahBookmarkCollection] {
            collections.filter { Self.highlightColor(for: $0) == nil }
        }

        var highlightCollections: [AyahBookmarkCollection] {
            collections.filter { Self.highlightColor(for: $0) != nil }
        }

        var isSelectedVerseReadingBookmark: Bool {
            guard let firstVerse = verses.first else {
                return false
            }
            return readingBookmark?.isAyahBookmark(for: firstVerse) == true
        }

        nonisolated static func sorted(_ collections: [AyahBookmarkCollection]) -> [AyahBookmarkCollection] {
            AyahBookmarkCollectionsViewModel.sorted(collections)
        }

        nonisolated static func bookmarksToAdd(to collection: AyahBookmarkCollection, verses: [AyahNumber]) -> [AyahNumber] {
            let existingAyahs = Set(collection.bookmarks.map { AyahKey($0.ayah) })
            return verses.filter { !existingAyahs.contains(AyahKey($0)) }
        }

        nonisolated static func bookmarksToRemove(from collection: AyahBookmarkCollection, verses: [AyahNumber]) -> [AyahCollectionBookmark] {
            let selectedAyahs = Set(verses.map(AyahKey.init))
            return collection.bookmarks.filter { selectedAyahs.contains(AyahKey($0.ayah)) }
        }

        nonisolated static func containsAnyBookmark(in collection: AyahBookmarkCollection, verses: [AyahNumber]) -> Bool {
            !bookmarksToRemove(from: collection, verses: verses).isEmpty
        }

        nonisolated static func highlightColor(for collection: AyahBookmarkCollection) -> HighlightColor? {
            HighlightColor(collectionName: collection.collection.name)
        }

        func start() async {
            async let collections: () = loadCollections()
            async let readingBookmark: () = loadReadingBookmark()
            _ = await [collections, readingBookmark]
        }

        func toggleSelection(for collection: AyahBookmarkCollection) {
            let id = collection.collection.localId
            didUpdateSelection = true
            if Self.highlightColor(for: collection) != nil {
                selectedHighlightCollectionID = selectedHighlightCollectionID == id ? nil : id
            } else if selectedCollectionIDs.contains(id) {
                selectedCollectionIDs.remove(id)
            } else {
                selectedCollectionIDs.insert(id)
            }
        }

        func isSelected(_ collection: AyahBookmarkCollection) -> Bool {
            let id = collection.collection.localId
            if Self.highlightColor(for: collection) != nil {
                return selectedHighlightCollectionID == id
            }
            return selectedCollectionIDs.contains(id)
        }

        func createCollection(name: String) async {
            do {
                try await ayahBookmarkCollectionService.createCollection(named: name)
            } catch {
                self.error = error
            }
        }

        func saveSelectedCollections() async {
            do {
                try await saveSelectedHighlight()
                try await saveSelectedBookmarkCollections()
                didFinish()
            } catch {
                self.error = error
            }
        }

        func toggleReadingBookmark() async {
            guard let firstVerse = verses.first else {
                return
            }

            do {
                if isSelectedVerseReadingBookmark {
                    try await readingBookmarkService.removeReadingBookmark()
                    readingBookmark = nil
                    didUpdateReadingBookmark(nil)
                } else {
                    let bookmark = try await readingBookmarkService.addReadingBookmark(ayah: firstVerse)
                    readingBookmark = bookmark
                    didUpdateReadingBookmark(bookmark)
                }
            } catch {
                self.error = error
            }
        }

        // MARK: Private

        private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
        private let readingBookmarkService: ReadingBookmarkService
        private let verses: [AyahNumber]
        private let didUpdateReadingBookmark: (QuranReadingBookmark?) -> Void
        private let didFinish: () -> Void
        private var didEnsureHighlightCollections = false
        private var didUpdateSelection = false

        private func loadCollections() async {
            do {
                let sequence = ayahBookmarkCollectionService.collectionsSequence()
                for try await collections in sequence {
                    self.collections = Self.sorted(collections)
                    selectExistingBookmarksIfNeeded(in: self.collections)
                    try await ensureHighlightCollections(collections)
                }
            } catch {
                self.error = error
            }
        }

        private func ensureHighlightCollections(_ collections: [AyahBookmarkCollection]) async throws {
            guard !didEnsureHighlightCollections else {
                return
            }
            didEnsureHighlightCollections = true
            try await HighlightBookmarkCollections.ensure(in: collections, using: ayahBookmarkCollectionService)
        }

        private func selectExistingBookmarksIfNeeded(in collections: [AyahBookmarkCollection]) {
            guard !didUpdateSelection else {
                return
            }

            for collection in collections where Self.containsAnyBookmark(in: collection, verses: verses) {
                if Self.highlightColor(for: collection) != nil {
                    selectedHighlightCollectionID = collection.collection.localId
                } else {
                    selectedCollectionIDs.insert(collection.collection.localId)
                }
            }
        }

        private func loadReadingBookmark() async {
            do {
                let sequence = readingBookmarkService.readingBookmarkSequence()
                for try await bookmark in sequence {
                    readingBookmark = bookmark
                }
            } catch {
                self.error = error
            }
        }

        private func saveSelectedHighlight() async throws {
            let selectedAyahs = Set(verses.map(AyahKey.init))
            var targetAyahs = Set<AyahKey>()

            for collection in highlightCollections {
                let isTarget = collection.collection.localId == selectedHighlightCollectionID
                for bookmark in collection.bookmarks where selectedAyahs.contains(AyahKey(bookmark.ayah)) {
                    if isTarget {
                        targetAyahs.insert(AyahKey(bookmark.ayah))
                    } else {
                        try await ayahBookmarkCollectionService.removeBookmarkFromCollection(bookmark)
                    }
                }
            }

            guard let selectedHighlightCollectionID else {
                return
            }

            for verse in verses where !targetAyahs.contains(AyahKey(verse)) {
                try await ayahBookmarkCollectionService.addAyahBookmarkToCollection(
                    collectionLocalId: selectedHighlightCollectionID,
                    ayah: verse
                )
            }
        }

        private func saveSelectedBookmarkCollections() async throws {
            for collection in bookmarkCollections {
                if selectedCollectionIDs.contains(collection.collection.localId) {
                    for verse in Self.bookmarksToAdd(to: collection, verses: verses) {
                        try await ayahBookmarkCollectionService.addAyahBookmarkToCollection(
                            collectionLocalId: collection.collection.localId,
                            ayah: verse
                        )
                    }
                } else {
                    for bookmark in Self.bookmarksToRemove(from: collection, verses: verses) {
                        try await ayahBookmarkCollectionService.removeBookmarkFromCollection(bookmark)
                    }
                }
            }
        }
    }

    private struct AyahKey: Hashable {
        init(_ ayahNumber: AyahNumber) {
            sura = Int32(ayahNumber.sura.suraNumber)
            ayah = Int32(ayahNumber.ayah)
        }

        let sura: Int32
        let ayah: Int32
    }
#endif
