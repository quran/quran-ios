#if QURAN_SYNC
    //
    //  AyahBookmarkCollectionService.swift
    //
    //  Created by Ahmed Nabil on 2026-05-06.
    //

    import MobileSync
    import QuranKit
    import ReadingService

    struct AyahBookmarkCollectionService {
        // MARK: Lifecycle

        init(quran: Quran = ReadingPreferences.shared.reading.quran) {
            self.quran = quran
        }

        // MARK: Internal

        func ayah(for bookmark: CollectionAyahBookmark) -> AyahNumber? {
            AyahNumber(quran: quran, sura: Int(bookmark.sura), ayah: Int(bookmark.ayah))
        }

        func page(for bookmark: CollectionAyahBookmark) -> Page? {
            ayah(for: bookmark)?.page
        }

        // MARK: Private

        private let quran: Quran
    }

    // TODO: Move this extension to mobile-sync repository in a follow-up PR.
    // This is a temporary workaround to support CollectionAyahBookmark directly.
    // The mobile-sync API should be enhanced to accept CollectionAyahBookmark
    // instead of requiring conversion to AyahBookmark.
    extension SyncService {
        func removeBookmarkFromCollection(_ bookmark: CollectionAyahBookmark) async throws {
            try await removeBookmarkFromCollection(
                collectionLocalId: bookmark.collectionLocalId,
                bookmark: AyahBookmark(
                    sura: bookmark.sura,
                    ayah: bookmark.ayah,
                    lastUpdated: bookmark.lastUpdated,
                    localId: bookmark.bookmarkLocalId
                )
            )
        }
    }
#endif
