//
//  EditableNote.swift
//
//
//  Created by Afifi, Mohamed on 10/26/21.
//

import Combine
import Foundation
import QuranAnnotations
import QuranKit

public class EditableNote: ObservableObject {
    // MARK: Lifecycle

    public init(
        ayahRange: ClosedRange<AyahNumber>,
        ayahText: String,
        modifiedSince: String,
        selectedColor: HighlightColor,
        note: String
    ) {
        self.ayahRange = ayahRange
        self.ayahText = ayahText
        self.modifiedSince = modifiedSince
        self.selectedColor = selectedColor
        self.note = note
        editing = false
    }

    // MARK: Public

    public let ayahRange: ClosedRange<AyahNumber>
    public let ayahText: String
    public let modifiedSince: String
    @Published public internal(set) var selectedColor: HighlightColor
    @Published public internal(set) var note: String

    public var wordCount: Int {
        var count = 0
        note.enumerateSubstrings(
            in: note.startIndex ..< note.endIndex,
            options: [.byWords, .localized, .substringNotRequired]
        ) { _, _, _, _ in
            count += 1
        }
        return count
    }

    public var notePublisher: AnyPublisher<String, Never> {
        $note.eraseToAnyPublisher()
    }

    // MARK: Internal

    @Published var editing: Bool
}
