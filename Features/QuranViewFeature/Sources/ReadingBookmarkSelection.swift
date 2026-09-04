#if QURAN_SYNC
import QuranAnnotations

enum ReadingBookmarkSelection {
    static func latest(
        at placement: PlacedReadingBookmark.Placement,
        in bookmarks: [PlacedReadingBookmark]
    ) -> PlacedReadingBookmark? {
        latest(at: [placement], in: bookmarks)
    }

    static func latest(
        at placements: [PlacedReadingBookmark.Placement],
        in bookmarks: [PlacedReadingBookmark]
    ) -> PlacedReadingBookmark? {
        bookmarks
            .filter { placements.contains($0.placement) }
            .max { $0.modifiedOn < $1.modifiedOn }
    }
}
#endif
