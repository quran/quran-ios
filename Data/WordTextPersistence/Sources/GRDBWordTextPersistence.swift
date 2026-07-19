//
//  GRDBWordTextPersistence.swift
//
//
//  Created by Mohamed Afifi on 2023-05-23.
//

import Foundation
import GRDB
import QuranKit
import SQLitePersistence

public struct GRDBWordTextPersistence: WordTextPersistence {
    // MARK: Lifecycle

    init(db: DatabaseConnection) {
        self.db = db
    }

    public init(fileURL: URL) {
        self.init(db: DatabaseConnection(url: fileURL))
    }

    // MARK: Public

    public func translationForWord(_ word: Word) async throws -> String? {
        try await wordText(at: word)?.translation
    }

    public func transliterationForWord(_ word: Word) async throws -> String? {
        try await wordText(at: word)?.transliteration
    }

    // MARK: Internal

    let db: DatabaseConnection

    // MARK: Private

    private func wordText(at word: Word) async throws -> GRDBWord? {
        try await db.read { db in
            let query = GRDBWord.filter(GRDBWord.Columns.sura == word.verse.sura.suraNumber
                && GRDBWord.Columns.ayah == word.verse.ayah
                && GRDBWord.Columns.word == word.wordNumber)

            let words = try query.fetchAll(db)

            return words.first
        }
    }
}

private struct GRDBWord: Decodable, FetchableRecord, TableRecord {
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

    var word: Int
    var translation: String?
    var transliteration: String?
    var sura: Int
    var ayah: Int
}
