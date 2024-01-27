//
//  String+Chunking.swift
//
//
//  Created by Mohamed Afifi on 2023-12-31.
//

import Foundation

extension String {
    public func chunk(maxChunkSize: Int) -> [Substring] {
        chunkRanges(maxChunkSize: maxChunkSize).map { self[$0] }
    }

    public func chunkRanges(maxChunkSize: Int) -> [Range<String.Index>] {
        chunkRanges(range: startIndex ..< endIndex, maxChunkSize: maxChunkSize)
    }

    public func chunkRanges(range: Range<String.Index>, maxChunkSize: Int) -> [Range<String.Index>] {
        var chunks: [Range<String.Index>] = []
        chunkText(self, range: range, maxChunkSize: maxChunkSize, strategy: .paragraph, chunks: &chunks)
        return chunks
    }
}

private func chunkText(_ text: String, range: Range<String.Index>, maxChunkSize: Int, strategy: ChunkingStrategy, chunks: inout [Range<String.Index>]) {
    let blocks = text.split(in: range, on: strategy.enumerationOptions)

    var accumlatedChunkStartIndex = range.lowerBound
    var accumlatedBlocks = 0

    func addAccumlatedChunk(to upperBound: String.Index, next: String.Index) {
        if accumlatedBlocks > 0 && accumlatedChunkStartIndex < range.upperBound {
            chunks.append(accumlatedChunkStartIndex ..< upperBound)
            accumlatedBlocks = 0
        }
        accumlatedChunkStartIndex = next
    }

    for block in blocks {
        let blockLength = text.distance(from: block.lowerBound, to: block.upperBound)
        if blockLength > maxChunkSize {
            // Add accumlated chunks.
            addAccumlatedChunk(to: block.lowerBound, next: block.upperBound)

            if let nextStrategy = strategy.nextStrategy() {
                // Try a finer strategy
                chunkText(text, range: block, maxChunkSize: maxChunkSize, strategy: nextStrategy, chunks: &chunks)
            } else {
                // No finer strategy, add the long block as a separate chunk.
                chunks.append(block)
            }
        } else {
            // Try to extend current chunk.
            let extendedCurrentChunkLength = text.distance(from: accumlatedChunkStartIndex, to: block.upperBound)

            if extendedCurrentChunkLength > maxChunkSize {
                // Add the current chunk and start a new one from the current block.
                addAccumlatedChunk(to: block.lowerBound, next: block.lowerBound)
                accumlatedBlocks = 1
            } else {
                // Continue to accumlate blocks.
                accumlatedBlocks += 1
            }
        }
    }

    if accumlatedChunkStartIndex < range.upperBound {
        addAccumlatedChunk(to: range.upperBound, next: range.upperBound)
    }
}

private extension String {
    func split(in range: Range<Index>, on: EnumerationOptions) -> [Range<Index>] {
        var subranges: [Range<Index>] = []

        enumerateSubstrings(in: range, options: [on, .substringNotRequired]) { _, subrange, _, _ in
            let modifiedSubrange: Range<Index>
            if let lastRangeIndex = subranges.indices.last {
                // Update last range to end at the new subrange.
                subranges[lastRangeIndex] = subranges[lastRangeIndex].lowerBound ..< subrange.lowerBound
                modifiedSubrange = subrange
            } else {
                modifiedSubrange = range.lowerBound ..< subrange.upperBound
            }
            subranges.append(modifiedSubrange)
        }

        // Check if there's any remaining text after the last subrange
        if let lastRangeIndex = subranges.indices.last {
            // Merge any remaining text with the last subrange
            subranges[lastRangeIndex] = subranges[lastRangeIndex].lowerBound ..< range.upperBound
        }

        if subranges.isEmpty {
            subranges.append(range)
        }

        return subranges
    }
}

private enum ChunkingStrategy {
    case paragraph, sentence, word

    // MARK: Internal

    var enumerationOptions: String.EnumerationOptions {
        switch self {
        case .paragraph: return .byParagraphs
        case .sentence: return .bySentences
        case .word: return .byWords
        }
    }

    func nextStrategy() -> ChunkingStrategy? {
        switch self {
        case .paragraph: return .sentence
        case .sentence: return .word
        case .word: return nil
        }
    }
}
