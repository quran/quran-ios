//
//  Word.swift
//
//
//  Created by Mohamed Afifi on 2021-12-17.
//

import QuranKit
import UIKit

public struct Word: Equatable, Comparable {
    public let verse: AyahNumber
    let wordNumber: Int

    public static func < (lhs: Word, rhs: Word) -> Bool {
        if lhs.verse == rhs.verse {
            return lhs.wordNumber < rhs.wordNumber
        }
        return lhs.verse < rhs.verse
    }
}
