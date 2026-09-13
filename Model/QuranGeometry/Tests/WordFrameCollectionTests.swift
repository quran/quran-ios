import QuranGeometry
import QuranKit
import XCTest

final class WordFrameCollectionTests: XCTestCase {
    func testVerseStartFramesKeepSeparateAyahsOnTheSameLine() {
        let verses = Quran.hafsMadani1405.suras[1].verses
        let frames = WordFrameCollection(frames: [
            frame(verse: verses[0], wordNumber: 1, line: 2),
            frame(verse: verses[1], wordNumber: 1, line: 2),
            frame(verse: verses[1], wordNumber: 2, line: 5),
        ])

        XCTAssertEqual(frames.verseStartFrames, Array(frames.frames.prefix(2)))
        for start in frames.verseStartFrames {
            XCTAssertEqual(start, frames.verseStartFrame(for: start.word.verse))
        }
    }

    func testVerseStartFramesUseFirstAvailableWordForContinuedAyah() {
        let verse = Quran.hafsMadani1405.suras[1].verses[0]
        let firstFrame = frame(verse: verse, wordNumber: 3, line: 1)
        let frames = WordFrameCollection(frames: [
            frame(verse: verse, wordNumber: 4, line: 2),
            firstFrame,
        ])

        XCTAssertEqual(frames.verseStartFrames, [firstFrame])
        XCTAssertEqual(frames.verseStartFrame(for: verse), firstFrame)
    }

    func testVerseStartsUseWordNumbersAndVerseOrderDespiteShuffledFrames() {
        let verses = Quran.hafsMadani1405.suras[1].verses
        let first = frame(verse: verses[0], wordNumber: 1, line: 2)
        let second = frame(verse: verses[1], wordNumber: 1, line: 3)
        let frames = WordFrameCollection(frames: [
            frame(verse: verses[1], wordNumber: 2, line: 3),
            second,
            frame(verse: verses[0], wordNumber: 2, line: 2),
            first,
        ])

        XCTAssertEqual(frames.verseStartFrames, [first, second])
        XCTAssertEqual(frames.verseStartFrame(for: verses[0]), first)
        XCTAssertEqual(frames.verseStartFrame(for: verses[1]), second)
    }

    func testRepeatedWordNumbersPreferEarlierLineThenRightmostFrame() {
        let verse = Quran.hafsMadani1405.suras[1].verses[0]
        let left = frame(verse: verse, wordNumber: 1, line: 2)
        let right = frame(verse: verse, wordNumber: 1, line: 2, minX: 100)
        let later = frame(verse: verse, wordNumber: 1, line: 3, minX: 200)

        for input in [[later, left, right], [right, left, later]] {
            let frames = WordFrameCollection(frames: input)
            XCTAssertEqual(frames.verseStartFrames, [right])
            XCTAssertEqual(frames.verseStartFrame(for: verse), right)
        }
    }

    func testMissingVerseAndEmptyCollectionHaveNoStartFrame() {
        let verses = Quran.hafsMadani1405.suras[1].verses
        let frames = WordFrameCollection(frames: [frame(verse: verses[0], wordNumber: 1, line: 1)])
        let empty = WordFrameCollection(frames: [])

        XCTAssertNil(frames.verseStartFrame(for: verses[1]))
        XCTAssertNil(empty.verseStartFrame(for: verses[0]))
        XCTAssertTrue(empty.verseStartFrames.isEmpty)
    }

    func testRepeatedLineNumbersOnDifferentPagesKeepDistinctVerseStarts() {
        let quran = Quran.hafsMadani1405
        let first = frame(verse: quran.suras[1].verses[0], wordNumber: 1, line: 2)
        let second = frame(verse: quran.suras[2].verses[0], wordNumber: 1, line: 2)

        XCTAssertEqual(WordFrameCollection(frames: [first, second]).verseStartFrames, [first, second])
        XCTAssertNotEqual(first.word, second.word)
    }

    private func frame(verse: AyahNumber, wordNumber: Int, line: Int, minX: Int = 20) -> WordFrame {
        WordFrame(
            line: line,
            word: Word(verse: verse, wordNumber: wordNumber),
            minX: minX,
            maxX: minX + 60,
            minY: 40 * line,
            maxY: 40 * (line + 1)
        )
    }
}
