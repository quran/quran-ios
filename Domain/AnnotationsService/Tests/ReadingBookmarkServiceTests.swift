#if QURAN_SYNC
    import MobileSync
    import QuranKit
    import XCTest
    @testable import AnnotationsService

    final class ReadingBookmarkServiceTests: XCTestCase {
        func test_bookmark_mapsAyahReadingBookmark() {
            let bookmark = AyahReadingBookmark(
                sura: 1,
                ayah: 1,
                lastUpdated: .distantPast,
                localId: "ayah-bookmark"
            )

            XCTAssertEqual(
                ReadingBookmarkService.bookmark(from: bookmark, quran: .hafsMadani1405),
                .ayah(AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!, .distantPast)
            )
        }

        func test_bookmark_mapsPageReadingBookmark() {
            let bookmark = PageReadingBookmark(
                page: 1,
                lastUpdated: .distantPast,
                localId: "page-bookmark"
            )

            XCTAssertEqual(
                ReadingBookmarkService.bookmark(from: bookmark, quran: .hafsMadani1405),
                .page(Page(quran: .hafsMadani1405, pageNumber: 1)!, .distantPast)
            )
        }

        func test_isReadingBookmark_matchesPageBookmarkAyah() {
            let ayah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
            let bookmark = QuranReadingBookmark.page(ayah.page, .distantPast)

            XCTAssertTrue(bookmark.isReadingBookmark(for: ayah))
        }

        func test_isPageBookmark_matchesAyahBookmarkPage() {
            let ayah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
            let bookmark = QuranReadingBookmark.ayah(ayah, .distantPast)

            XCTAssertTrue(bookmark.isPageBookmark(for: [ayah.page]))
        }

        func test_bookmark_skipsInvalidAyah() {
            let bookmark = AyahReadingBookmark(
                sura: 999,
                ayah: 1,
                lastUpdated: .distantPast,
                localId: "invalid-ayah-bookmark"
            )

            XCTAssertNil(ReadingBookmarkService.bookmark(from: bookmark, quran: .hafsMadani1405))
        }
    }
#endif
