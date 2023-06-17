//
//  EditableNote.swift
//
//
//  Created by Afifi, Mohamed on 10/26/21.
//

import Combine

public class EditableNote: ObservableObject {
    // MARK: Lifecycle

    public init(ayahText: String, modifiedSince: String, selectedColor: NoteColor, note: String) {
        self.ayahText = ayahText
        self.modifiedSince = modifiedSince
        self.selectedColor = selectedColor
        self.note = note
        editing = false
    }

    // MARK: Public

    public let ayahText: String
    public let modifiedSince: String
    @Published public internal(set) var selectedColor: NoteColor
    @Published public internal(set) var note: String

    // MARK: Internal

    @Published var editing: Bool
}
