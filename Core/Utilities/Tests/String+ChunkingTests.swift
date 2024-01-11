//
//  String+ChunkingTests.swift
//
//
//  Created by Mohamed Afifi on 2023-12-31.
//

import Foundation
import Utilities
import XCTest

class StringChunkingTests: XCTestCase {
    func test_shortText() {
        let text = "Short text."
        let chunks = text.chunkIntoStrings(maxChunkSize: 50)
        XCTAssertEqual(chunks, [text])
        XCTAssertEqual(chunks.joined(separator: ""), text)
    }

    func test_longParagraph_manySmallSentences() {
        let text = String(repeating: "A long paragraph. ", count: 1000)
        let chunks = text.chunkIntoStrings(maxChunkSize: 1500)
        XCTAssertTrue(chunks.allSatisfy { $0.count <= 1500 })
        XCTAssertEqual(chunks.joined(separator: ""), text)
    }

    func test_longSentence_manySmallWords() {
        let text = String(repeating: "Morning ", count: 1500)
        let chunks = text.chunkIntoStrings(maxChunkSize: 1500)
        XCTAssertTrue(chunks.allSatisfy { $0.count <= 1500 })
        XCTAssertEqual(chunks.joined(separator: ""), text)
    }

    func test_separateParagraphs() {
        let paragraphs = [
            "First paragraph.",
            "Second paragraph.",
            "Third paragraph.",
        ]
        let expectedChunks = [
            "First paragraph.\n",
            "Second paragraph.\n",
            "Third paragraph.",
        ]

        let text = paragraphs.joined(separator: "\n")
        let maxChunkSize = (paragraphs.map(\.count).max() ?? 1) + 1
        let chunks = text.chunkIntoStrings(maxChunkSize: maxChunkSize)

        XCTAssertEqual(chunks, expectedChunks)
        XCTAssertEqual(chunks.joined(separator: ""), text)
    }

    func test_longParagraphs_singleSentence() {
        let paragraphs = [
            "First paragraph.",
            "Second paragraph.",
            "Third paragraph.",
        ]
        let expectedChunks = [
            "First ", "paragraph.\n",
            "Second ", "paragraph.\n",
            "Third ", "paragraph.",
        ]
        let text = paragraphs.joined(separator: "\n")
        let chunks = text.chunkIntoStrings(maxChunkSize: 1)

        XCTAssertEqual(chunks, expectedChunks)
        XCTAssertEqual(chunks.joined(separator: ""), text)
    }

    func test_longFirstParagraph_singleSentence() {
        let paragraphs = [
            "Long first paragraph.",
            "Abbreviations.",
            "Small.",
        ]
        let expectedChunks = [
            "Long first ", "paragraph.\n",
            "Abbreviations.\n",
            "Small.",
        ]
        let text = paragraphs.joined(separator: "\n")
        let maxChunkSize = "Long first ".count
        let chunks = text.chunkIntoStrings(maxChunkSize: maxChunkSize)

        XCTAssertEqual(chunks, expectedChunks)
        XCTAssertEqual(chunks.joined(separator: ""), text)
    }

    func test_longMiddlParagraph_singleSentence() {
        let paragraphs = [
            "Abbreviations.",
            "Long first paragraph.",
            "Small.",
        ]
        let expectedChunks = [
            "Abbreviations.\n",
            "Long first ", "paragraph.\n",
            "Small.",
        ]
        let text = paragraphs.joined(separator: "\n")
        let maxChunkSize = "Long first ".count
        let chunks = text.chunkIntoStrings(maxChunkSize: maxChunkSize)

        XCTAssertEqual(chunks, expectedChunks)
        XCTAssertEqual(chunks.joined(separator: ""), text)
    }

    func test_longLastParagraph_singleSentence() {
        let paragraphs = [
            "Long first paragraph.",
            "Abbreviations.",
            "Small.",
        ]
        let expectedChunks = [
            "Long first ", "paragraph. ",
            "Abbreviations. ",
            "Small.",
        ]
        let text = paragraphs.joined(separator: " ")
        let maxChunkSize = "Long first ".count
        let chunks = text.chunkIntoStrings(maxChunkSize: maxChunkSize)

        XCTAssertEqual(chunks, expectedChunks)
        XCTAssertEqual(chunks.joined(separator: ""), text)
    }

    func test_emptyParagraphs() {
        let paragraphs = [
            "",
            "Word.",
            "",
            " ",
            "Something.",
            "",
        ]
        let expectedChunks = [
            "\n",
            "Word.\n",
            "\n",
            " \n",
            "Something.\n",
        ]
        let text = paragraphs.joined(separator: "\n")
        let chunks = text.chunkIntoStrings(maxChunkSize: 1)

        XCTAssertEqual(chunks, expectedChunks)
        XCTAssertEqual(chunks.joined(separator: ""), text)
    }

    func test_longFirstSentence() {
        let text = "Abbreviations. Long first paragraph. Small."
        let expectedChunks = [
            "Abbreviations. ",
            "Long first ", "paragraph. ",
            "Small.",
        ]
        let maxChunkSize = "Long first ".count
        let chunks = text.chunkIntoStrings(maxChunkSize: maxChunkSize)

        XCTAssertEqual(chunks, expectedChunks)
        XCTAssertEqual(chunks.joined(separator: ""), text)
    }

    func test_emptySentences() {
        let text = ". Word. .   . Something. .."
        let expectedChunks = [
            ". ",
            "Word. .   . ",
            "Something. ..",
        ]
        let chunks = text.chunkIntoStrings(maxChunkSize: 1)

        XCTAssertEqual(chunks, expectedChunks)
        XCTAssertEqual(chunks.joined(separator: ""), text)
    }

    func test_longWord_noChunking() {
        let text = String(repeating: "a", count: 1600)
        let chunks = text.chunkIntoStrings(maxChunkSize: 1500)
        XCTAssertEqual(chunks, [text])
        XCTAssertEqual(chunks.joined(separator: ""), text)
    }

    func test_exactChunkSize() {
        let charCount = 5
        let wordsCount = 1000
        let chunkSize = charCount * wordsCount
        let word = String(repeating: "a", count: charCount - 1) + " "
        let text = String(repeating: word, count: wordsCount)
        let chunks = text.chunkIntoStrings(maxChunkSize: chunkSize)
        XCTAssertTrue(chunks.allSatisfy { $0.count == chunkSize })
        XCTAssertEqual(chunks.joined(separator: ""), text)
    }
}

private extension String {
    func chunkIntoStrings(maxChunkSize: Int) -> [String] {
        chunk(maxChunkSize: maxChunkSize).map { String($0) }
    }
}
