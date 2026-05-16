#if QURAN_SYNC
    //
    //  SyncedNoteItem.swift
    //
    //  Created by Ahmed Nabil on 2026-05-16.
    //

    import AnnotationsService

    struct SyncedNoteItem: Equatable, Identifiable {
        let note: SyncedNote
        let verseText: String

        var id: String { note.id }
    }
#endif
