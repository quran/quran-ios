#if QURAN_SYNC
import MobileSync

extension AyahBookmarkCollection: Identifiable {
    public var id: String { collection.id }
}

extension AyahCollectionBookmark: Identifiable {
    public var id: String { bookmark.bookmarkId }
}
#endif
