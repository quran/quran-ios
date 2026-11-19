//
//  FootnoteVerseReference.swift
//
//
//  Created by Marouane on 2026-11-19.
//

import Foundation

/// A Quran verse that a translation footnote refers to, like `{6:38}` in "See footnote for {6:38}".
struct FootnoteVerseReference: Hashable {
    /// The reference as written, with its braces and any range end, like `{21:51}-71`.
    let range: Range<String.Index>
    let sura: Int
    /// The verse, or the first verse of a range.
    let ayah: Int
}

extension String {
    /// The verse references in a translation footnote.
    ///
    /// Translations write them in braces, like `{6:38}`, `(V.{3:85})` or `{21:51}-71`. Bible chapter and verse
    /// use the same braces, so braces after a Bible book are left out, along with the list they start, like
    /// `Deuteronomy {18:15}-18 and {33:2}`. So are braces in Arabic-script text, where translations use them
    /// only for Bible references. The numbers aren't checked against the Quran.
    func footnoteVerseReferences() -> [FootnoteVerseReference] {
        guard contains("{") else {
            return []
        }

        var references: [FootnoteVerseReference] = []
        var previous: (end: String.Index, isBible: Bool)?
        for match in Self.bracedVerseRegex.matches(in: self, range: NSRange(startIndex..., in: self)) {
            guard let range = Range(match.range, in: self),
                  let sura = Range(match.range(at: 1), in: self).flatMap({ self[$0].decimalValue }),
                  let ayah = Range(match.range(at: 2), in: self).flatMap({ self[$0].decimalValue })
            else {
                continue
            }

            let continuesBibleList = previous.map { $0.isBible && self[$0.end ..< range.lowerBound].isListSeparator } ?? false
            let isBible = continuesBibleList || followsBibleBook(range.lowerBound)
            previous = (range.upperBound, isBible)

            if !isBible, !followsArabicScript(range.lowerBound) {
                references.append(FootnoteVerseReference(range: range, sura: sura, ayah: ayah))
            }
        }
        return references
    }

    /// `{sura:ayah}`, with an optional range end after the braces, like `{21:51}-71`.
    private static let bracedVerseRegex = try! NSRegularExpression(pattern: #"\{\s?(\d{1,3})\s?:\s?(\d{1,3})\s?\}(?:\s?[-–]\s?\d{1,3})?"#)

    /// Bible books as translations name them before chapter and verse, like `Deut. {18:18}` or `1 Kings {11:3}`.
    /// Job, Jonah and Zechariah are left out, since translations also name these prophets before Quran references.
    private static let bibleBooks: Set<String> = [
        "Genesis", "Gen", "Exodus", "Exod", "Leviticus", "Lev", "Numbers", "Num", "Deuteronomy", "Deut",
        "Joshua", "Josh", "Judges", "Judg", "Ruth", "Samuel", "Sam", "Kings", "Kgs", "Chronicles", "Chron",
        "Ezra", "Nehemiah", "Neh", "Esther", "Esth", "Psalms", "Psalm", "Psl", "Ps", "Proverbs", "Prov",
        "Ecclesiastes", "Eccl", "Isaiah", "Isa", "Jeremiah", "Jer", "Lamentations", "Lam", "Ezekiel", "Ezek",
        "Daniel", "Dan", "Hosea", "Hos", "Joel", "Amos", "Obadiah", "Obad", "Micah", "Mic", "Nahum", "Nah",
        "Habakkuk", "Hab", "Zephaniah", "Zeph", "Haggai", "Hag", "Malachi", "Mal",
        "Matthew", "Matt", "Mark", "Luke", "John", "Jn", "Acts", "Romans", "Rom", "Corinthians", "Cor",
        "Galatians", "Gal", "Ephesians", "Eph", "Philippians", "Phil", "Colossians", "Col", "Thessalonians",
        "Thess", "Timothy", "Tim", "Titus", "Philemon", "Hebrews", "Heb", "James", "Jas", "Peter", "Pet",
        "Jude", "Revelation", "Rev",
    ]

    /// Whether a Bible book comes right before `index`, like `Deuteronomy {18:15}`, `1 Kings {11:3}` or `Jn.{14:12}`.
    private func followsBibleBook(_ index: String.Index) -> Bool {
        var prefix = self[..<index]
        while let last = prefix.last, last.isWhitespace || last == "." {
            prefix.removeLast()
        }
        let wordStart = prefix.lastIndex { !$0.isLetter }.map { prefix.index(after: $0) } ?? prefix.startIndex
        return Self.bibleBooks.contains(String(prefix[wordStart...]))
    }

    /// Whether the nearest letter before `index` is in Arabic script, like `خروج {20:5}` in an Urdu footnote.
    private func followsArabicScript(_ index: String.Index) -> Bool {
        guard let letter = self[..<index].last(where: \.isLetter) else {
            return false
        }
        return letter.unicodeScalars.first?.isArabicScript == true
    }
}

private extension Substring {
    /// Whether this only separates list items, like `, ` or ` and `.
    var isListSeparator: Bool {
        split { $0.isWhitespace || ",;&".contains($0) }.allSatisfy { $0 == "and" }
    }

    /// The number its digits spell, in any script, like 255 for `٢٥٥`.
    var decimalValue: Int? {
        var value = 0
        for character in self {
            guard let digit = character.wholeNumberValue else {
                return nil
            }
            value = value * 10 + digit
        }
        return value
    }
}

private extension Unicode.Scalar {
    var isArabicScript: Bool {
        switch value {
        case 0x0600 ... 0x06FF, 0x0750 ... 0x077F, 0x0870 ... 0x08FF, 0xFB50 ... 0xFDFF, 0xFE70 ... 0xFEFF: true
        default: false
        }
    }
}
