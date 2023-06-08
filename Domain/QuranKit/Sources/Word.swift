//
//  Word.swift
//
//
//  Created by Mohamed Afifi on 2021-12-17.
//

public struct Word: Equatable, Comparable {
    public let verse: AyahNumber
    public let wordNumber: Int

    public init(verse: AyahNumber, wordNumber: Int) {
        self.verse = verse
        self.wordNumber = wordNumber
    }

    public static func < (lhs: Word, rhs: Word) -> Bool {
        if lhs.verse == rhs.verse {
            return lhs.wordNumber < rhs.wordNumber
        }
        return lhs.verse < rhs.verse
    }
}
