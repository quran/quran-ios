#if QURAN_SYNC
    import MobileSync

    extension CollectionWithAyahBookmarks: Identifiable {
        public var id: String { collection.localId }
    }

    extension CollectionAyahBookmark: Identifiable {
        public var id: String { localId }
    }
#endif
