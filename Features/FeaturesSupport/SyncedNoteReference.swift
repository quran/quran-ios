#if QURAN_SYNC
    import Foundation
    import MobileSync
    import QuranAnnotations
    import QuranKit

    public struct SyncedNoteReference: Identifiable, Equatable, Sendable {
        public init(localId: String?, body: String, verses: [AyahNumber], modifiedDate: Date) {
            self.localId = localId
            self.body = body
            self.verses = verses
            self.modifiedDate = modifiedDate
        }

        public var id: String {
            localId ?? verses.map { "\($0.sura.suraNumber):\($0.ayah)" }.joined(separator: "-")
        }

        public let localId: String?
        public let body: String
        public let verses: [AyahNumber]
        public let modifiedDate: Date

        public var firstVerse: AyahNumber? {
            verses.first
        }

        public var versesSet: Set<AyahNumber> {
            Set(verses)
        }

        public func highlightColor(in colorsByVerse: [AyahNumber: HighlightColor]) -> HighlightColor? {
            let colors = Set(verses.compactMap { colorsByVerse[$0] })
            guard colors.count == 1 else {
                return nil
            }
            return colors.first
        }

        public static func makeAll(from notes: [Note_], quran: Quran) -> [SyncedNoteReference] {
            let lookup = ayahLookup(for: quran)
            return notes.compactMap { note in
                makeReference(from: note, lookup: lookup)
            }
        }

        private static func makeReference(from note: Note_, lookup: [Int64: AyahNumber]) -> SyncedNoteReference? {
            let verses = Array(note.startAyahId ... note.endAyahId).compactMap { lookup[$0] }
            guard !verses.isEmpty else {
                return nil
            }

            return SyncedNoteReference(
                localId: note.localId,
                body: note.body,
                verses: verses,
                modifiedDate: note.lastUpdated
            )
        }

        private static func ayahLookup(for quran: Quran) -> [Int64: AyahNumber] {
            var lookup: [Int64: AyahNumber] = [:]
            for sura in quran.suras {
                for verse in sura.verses {
                    let suraNumber = sura.suraNumber
                    let ayah = AyahNumber(quran: quran, sura: suraNumber, ayah: verse.ayah)!
                    let ayahId = Int64(QuranData.shared.getAyahId(sura: Int32(suraNumber), ayah: Int32(verse.ayah)))
                    lookup[ayahId] = ayah
                }
            }
            return lookup
        }
    }
#endif
