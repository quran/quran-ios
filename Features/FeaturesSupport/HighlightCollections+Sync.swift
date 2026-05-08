#if QURAN_SYNC
    import MobileSync
    import QuranAnnotations
    import QuranKit

    public extension HighlightColor {
        init?(collectionName: String) {
            self.init(rawValue: collectionName)
        }

        var collectionName: String {
            rawValue
        }
    }

    public extension CollectionWithAyahBookmarks {
        var highlightColor: HighlightColor? {
            HighlightColor(collectionName: collection.name)
        }
    }

    public extension Sequence<CollectionWithAyahBookmarks> {
        func highlightedAyahs(quran: Quran) -> [AyahNumber: HighlightColor] {
            var highlights: [AyahNumber: HighlightColor] = [:]
            for collection in self {
                guard let color = collection.highlightColor else {
                    continue
                }
                for bookmark in collection.bookmarks {
                    guard let ayah = AyahNumber(quran: quran, sura: Int(bookmark.sura), ayah: Int(bookmark.ayah)) else {
                        continue
                    }
                    highlights[ayah] = color
                }
            }
            return highlights
        }
    }
#endif
