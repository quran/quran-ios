//
//  SQLiteQuranAyahTextPersistence.swift
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

    private static let quranTextPath = Bundle.main.path(forResource: "quran.ar.uthmani.v2", ofType: "db")!

    private let persistence: GeneralVerseTextPersistence

    init(quran: Quran) {
        self.init(quran: quran, mode: .arabic)
    }

    init(quran: Quran, mode: Mode, filePath: String = Self.quranTextPath) {
        let table: Table
        switch mode {
        case .arabic:
            table = Table("arabic_text")
        case .share:
            table = Table("share_text")
        }
        persistence = GeneralVerseTextPersistence(filePath: filePath, table: table, quran: quran)
    }

    func textForVerses(_ verses: [AyahNumber]) throws -> [AyahNumber: String] {
        try persistence.textForVerses(verses)
    }

    func textForVerse(_ verse: AyahNumber) throws -> String {
        try persistence.textForVerse(verse)
    }

    func autocomplete(term: String) throws -> [String] {
        try persistence.autocomplete(term: term)
    }

    func search(for term: String) throws -> [(verse: AyahNumber, text: String)] {
        try persistence.search(for: term)
    }
}
