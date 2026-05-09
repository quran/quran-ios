#if QURAN_SYNC
    //
    //  AyahBookmarkCollectionPickerViewModel.swift
    //
    //  Created by Ahmed Nabil on 2026-05-09.
    //

    import Foundation
    import QuranKit
    import VLogging

    @MainActor
    final class AyahBookmarkCollectionPickerViewModel: ObservableObject {
        // MARK: Lifecycle

        init(
            ayahBookmarkCollectionService: AyahBookmarkCollectionService,
            readingBookmarkService: ReadingBookmarkService,
            verses: [AyahNumber],
            didSaveReadingBookmark: @escaping () -> Void,
            didFinish: @escaping () -> Void
        ) {
            self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
            self.readingBookmarkService = readingBookmarkService
            self.verses = verses
            self.didSaveReadingBookmark = didSaveReadingBookmark
            self.didFinish = didFinish
        }

        // MARK: Internal

        @Published var collections: [AyahBookmarkCollection] = []
        @Published var selectedCollectionIDs: Set<String> = []
        @Published var error: Error?

        var hasSelectedCollections: Bool {
            !selectedCollectionIDs.isEmpty
        }

        nonisolated static func sorted(_ collections: [AyahBookmarkCollection]) -> [AyahBookmarkCollection] {
            AyahBookmarkCollectionsViewModel.sorted(collections)
        }

        nonisolated static func bookmarksToAdd(to collection: AyahBookmarkCollection, verses: [AyahNumber]) -> [AyahNumber] {
            let existingAyahs = Set(collection.bookmarks.map { AyahKey($0.ayah) })
            return verses.filter { !existingAyahs.contains(AyahKey($0)) }
        }

        func start() async {
            do {
                let sequence = ayahBookmarkCollectionService.collectionsSequence()
                for try await collections in sequence {
                    self.collections = Self.sorted(collections)
                }
            } catch {
                self.error = error
            }
        }

        func toggleSelection(for collection: AyahBookmarkCollection) {
            let id = collection.collection.localId
            if selectedCollectionIDs.contains(id) {
                selectedCollectionIDs.remove(id)
            } else {
                selectedCollectionIDs.insert(id)
            }
        }

        func isSelected(_ collection: AyahBookmarkCollection) -> Bool {
            selectedCollectionIDs.contains(collection.collection.localId)
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
                for collection in collections where selectedCollectionIDs.contains(collection.collection.localId) {
                    for verse in Self.bookmarksToAdd(to: collection, verses: verses) {
                        try await ayahBookmarkCollectionService.addAyahBookmarkToCollection(
                            collectionLocalId: collection.collection.localId,
                            ayah: verse
                        )
                    }
                }
                didFinish()
            } catch {
                self.error = error
            }
        }

        func saveReadingBookmark() async {
            guard let firstVerse = verses.first else {
                return
            }

            do {
                try await readingBookmarkService.addReadingBookmark(ayah: firstVerse)
                didSaveReadingBookmark()
                didFinish()
            } catch {
                self.error = error
            }
        }

        // MARK: Private

        private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
        private let readingBookmarkService: ReadingBookmarkService
        private let verses: [AyahNumber]
        private let didSaveReadingBookmark: () -> Void
        private let didFinish: () -> Void
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
