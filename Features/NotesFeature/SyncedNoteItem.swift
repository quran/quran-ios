#if QURAN_SYNC
//
//  SyncedNoteItem.swift
//
//  Created by Ahmed Nabil on 2026-05-16.
//

import QuranAnnotations

struct SyncedNoteItem: Equatable, Identifiable, Sendable {
    let note: Note
    let verseText: String

    var id: String { note.id }
}
#endif
