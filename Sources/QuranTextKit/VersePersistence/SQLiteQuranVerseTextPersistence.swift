//
//  SQLiteQuranVerseTextPersistence.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/20/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation
import QuranKit
import SQLite
import SQLitePersistence

struct SQLiteQuranVerseTextPersistence: VerseTextPersistence {
    enum Mode {
        case arabic
        case share
    }

    private let persistence: GeneralVerseTextPersistence

    init(fileURL: URL) {
        self.init(mode: .arabic, fileURL: fileURL)
    }

    init(mode: Mode, fileURL: URL) {
        let table: Table
        switch mode {
        case .arabic:
            table = Table("arabic_text")
        case .share:
            table = Table("share_text")
        }
        persistence = GeneralVerseTextPersistence(filePath: fileURL.path, table: table)
    }

    func textForVerses(_ verses: [AyahNumber]) throws -> [AyahNumber: String] {
        try persistence.textForVerses(verses, transform: textFromRow)
    }

    func textForVerse(_ verse: AyahNumber) throws -> String {
        try persistence.textForVerse(verse, transform: textFromRow)
    }

    func autocomplete(term: String) throws -> [String] {
        try persistence.autocomplete(term: term)
    }

    func search(for term: String, quran: Quran) throws -> [(verse: AyahNumber, text: String)] {
        try persistence.search(for: term, quran: quran)
    }

    private func textFromRow(_ row: Row, quran: Quran) -> String {
        let text = Expression<String>("text")
        return row[text]
    }
}
