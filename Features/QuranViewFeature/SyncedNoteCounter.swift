#if QURAN_SYNC
//
//  SyncedNoteCounter.swift
//  Quran
//
//  Created by Ahmed Nabil on 2026-05-20.
//

import AnnotationsService
import QuranKit

enum SyncedNoteCounter {
    static func count(_ notes: [SyncedNote], interacting verses: [AyahNumber]) -> Int {
        let selectedVerses = Set(verses)
        return notes.filter { note in
            guard note.endAyah >= note.startAyah else {
                return false
            }
            return !selectedVerses.isDisjoint(with: note.startAyah.array(to: note.endAyah))
        }.count
    }
}
#endif
