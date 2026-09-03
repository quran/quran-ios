#if QURAN_SYNC
import QuranAnnotations

enum ReadingBookmarkSelection {
    static func latest(
        at location: ReadingPositionBookmark.Location,
        in bookmarks: [ReadingPositionBookmark]
    ) -> ReadingPositionBookmark? {
        latest(at: [location], in: bookmarks)
    }

    static func latest(
        at locations: [ReadingPositionBookmark.Location],
        in bookmarks: [ReadingPositionBookmark]
    ) -> ReadingPositionBookmark? {
        bookmarks
            .filter { locations.contains($0.location) }
            .max { $0.modifiedOn < $1.modifiedOn }
    }
}
#endif
