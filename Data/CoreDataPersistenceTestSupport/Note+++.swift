//
//  Note+++.swift
//
//
//  Created by Mohamed Afifi on 2023-06-01.
//

import CoreData
import CoreDataModel

extension NSManagedObjectContext {
    public func newVerse(sura: Int32, ayah: Int32) -> MO_Verse {
        let verse = MO_Verse(context: self)
        verse.sura = sura
        verse.ayah = ayah
        return verse
    }

    public func newNote(_ text: String, modifiedOn: TimeInterval) -> MO_Note {
        let note = MO_Note(context: self)
        note.note = text
        note.modifiedOn = Date(timeIntervalSince1970: modifiedOn)
        return note
    }

    public func allNotes() throws -> [MO_Note] {
        let fetchRequest = MO_Note.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Schema.Note.modifiedOn, ascending: false)]
        return try fetch(fetchRequest)
    }
}
