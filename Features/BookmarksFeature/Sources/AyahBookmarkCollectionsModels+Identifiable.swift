#if QURAN_SYNC
    import MobileSync

    extension AyahBookmarkCollection: Identifiable {
        public var id: String { collection.localId }
    }

    extension AyahCollectionBookmark: Identifiable {
        public var id: String { bookmark.localId }
    }
#endif
