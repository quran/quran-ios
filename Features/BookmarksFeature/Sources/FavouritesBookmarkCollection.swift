#if QURAN_SYNC
    //
    //  FavouritesBookmarkCollection.swift
    //
    //  Created by Ahmed Nabil on 2026-05-16.
    //

    import MobileSync

    enum FavouritesBookmarkCollection {
        static let localId = "local-favourites"

        static func make(
            name: String,
            bookmarks: [AyahCollectionBookmark],
            collections: [AyahBookmarkCollection]
        ) -> AyahBookmarkCollection {
            let linkedBookmarkIDs = Set(collections.flatMap { collection in
                collection.bookmarks.compactMap { bookmark -> String? in
                    guard case .collection(let collectionBookmark) = bookmark.bookmark else {
                        return nil
                    }
                    return collectionBookmark.bookmarkLocalId
                }
            })

            return AyahBookmarkCollection(
                collection: Collection_(name: name, lastUpdated: .distantPast, localId: localId),
                bookmarks: bookmarks.filter { bookmark in
                    guard case .ayah(let ayahBookmark) = bookmark.bookmark else {
                        return false
                    }
                    return !linkedBookmarkIDs.contains(ayahBookmark.localId)
                },
                isLocalOnly: true
            )
        }

        static func isFavourites(_ collection: AyahBookmarkCollection) -> Bool {
            collection.collection.localId == localId
        }
    }
#endif
