#if QURAN_SYNC
import QuranAnnotations

public protocol ReadingBookmarkDisplayable {
    var slot: ReadingBookmarkSlot { get }
    var name: String? { get }
}

public extension ReadingBookmarkDisplayable {
    var displayName: String {
        name ?? slot.displayName
    }
}

extension ReadingBookmark: ReadingBookmarkDisplayable { }
extension PlacedReadingBookmark: ReadingBookmarkDisplayable { }

#endif
