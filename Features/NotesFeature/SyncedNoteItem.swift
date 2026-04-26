#if QURAN_SYNC
    import FeaturesSupport
    import QuranAnnotations

    struct SyncedNoteItem: Equatable, Identifiable {
        let note: SyncedNoteReference
        let verseText: String
        let highlightColor: HighlightColor?

        var id: String { note.id }
    }
#endif
