//
//  NoteItem.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/22/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Foundation
import QuranAnnotations

struct NoteItem: Equatable, Identifiable {
    let note: Note
    let verseText: String

    var id: String {
        #if QURAN_SYNC
        note.id
        #else
        note.verses.description
        #endif
    }

    var noteText: String {
        #if QURAN_SYNC
        note.note
        #else
        note.note ?? ""
        #endif
    }
}

#if QURAN_SYNC
extension NoteItem: Sendable {}
#endif
