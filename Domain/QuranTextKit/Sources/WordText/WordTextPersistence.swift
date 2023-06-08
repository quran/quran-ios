//
//  WordTextPersistence.swift
//
//
//  Created by Mohamed Afifi on 2023-05-23.
//

import QuranKit

protocol WordTextPersistence {
    func translationForWord(_ word: Word) async throws -> String?
    func transliterationForWord(_ word: Word) async throws -> String?
}
