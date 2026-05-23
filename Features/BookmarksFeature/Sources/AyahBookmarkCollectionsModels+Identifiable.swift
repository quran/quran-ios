#if QURAN_SYNC
    extension AyahBookmarkCollection: Identifiable {
        public var id: String { collection.localId }
    }

    extension AyahCollectionBookmark: Identifiable {
        public var id: String {
            switch bookmark {
            case .collection(let bookmark):
                return bookmark.localId
            case .ayah(let bookmark):
                return bookmark.localId
            }
        }
    }
#endif
