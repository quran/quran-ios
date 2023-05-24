//
//  GRDBWordTextPersistence.swift
//
//
//  Created by Mohamed Afifi on 2023-05-23.
//

import Foundation
import GRDB
import SQLitePersistence

struct GRDBWordTextPersistence: WordTextPersistence {
    let db: DatabaseWriter

    init(db: DatabaseWriter) {
        self.db = db
    }

    init(fileURL: URL) {
        self.init(db: DatabasePool.unsafeNewInstance(filePath: fileURL.path, readOnly: true))
    }

    func translationForWord(_ word: Word) async throws -> String? {
        try await wordText(at: word)?.translation
    }

    func transliterationForWord(_ word: Word) async throws -> String? {
        try await wordText(at: word)?.transliteration
    }

    private func wordText(at word: Word) async throws -> GRDBWord? {
        try await db.read { db in
            let query = GRDBWord.filter(GRDBWord.Columns.sura == word.verse.sura.suraNumber
                && GRDBWord.Columns.ayah == word.verse.ayah
                && GRDBWord.Columns.word == word.wordNumber)

            let words = try query.fetchAll(db)

            guard words.count == 1 else {
                fatalError("Expected 1 word but found \(words.count) querying:\(word)")
            }

            return words[0]
        }
    }
}

private struct GRDBWord: Decodable, FetchableRecord, TableRecord {
    var word: Int
    var translation: String?
    var transliteration: String?
    var sura: Int
    var ayah: Int

    enum CodingKeys: String, CodingKey {
        case word = "word_position"
        case translation
        case transliteration
        case sura
        case ayah
    }

    enum Columns {
        static let word = Column(CodingKeys.word)
        static let translation = Column(CodingKeys.translation)
        static let transliteration = Column(CodingKeys.transliteration)
        static let sura = Column(CodingKeys.sura)
        static let ayah = Column(CodingKeys.ayah)
    }

    static let databaseTableName: String = "words"
}
