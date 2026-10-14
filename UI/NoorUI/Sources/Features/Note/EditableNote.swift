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
import QuranText

public class EditableNote: ObservableObject {
    // MARK: Lifecycle

    public init(
        ayahRanges: [ClosedRange<AyahNumber>],
        ayahText: QuranText,
        reading: Reading,
        modifiedSince: String,
        selectedColor: HighlightColor,
        note: String
    ) {
        self.ayahRanges = ayahRanges
        self.ayahText = ayahText
        self.reading = reading
        self.modifiedSince = modifiedSince
        self.selectedColor = selectedColor
        self.note = note
        editing = false
    }

    // MARK: Public

    /// The note's verses as runs of consecutive verses: one for a note made in the app, maybe more for one
    /// made on Quran.com.
    public let ayahRanges: [ClosedRange<AyahNumber>]
    public let ayahText: QuranText
    public let modifiedSince: String
    @Published public private(set) var reading: Reading
    @Published public internal(set) var selectedColor: HighlightColor
    @Published public internal(set) var note: String

    public func updateReading(_ reading: Reading) {
        self.reading = reading
    }

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
