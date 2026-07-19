//
//  WordFrame+Extension.swift
//
//
//  Created by Mohamed Afifi on 2021-12-26.
//

import QuranGeometry
import QuranKit

extension WordFrame {
    mutating func normalize() {
        // Ensure minX is less than or equal to maxX
        if minX > maxX {
            swap(&minX, &maxX)
        }

        // Ensure minY is less than or equal to maxY
        if minY > maxY {
            swap(&minY, &maxY)
        }
    }

    static func alignedVertically(_ list: [WordFrame]) -> [WordFrame] {
        let minY = list.map(\.minY).min() ?? 0
        let maxY = list.map(\.maxY).max() ?? 0
        var result: [WordFrame] = []
        for var frame in list {
            frame.minY = minY
            frame.maxY = maxY
            result.append(frame)
        }
        return result
    }

    static func unionHorizontally(leftFrame: inout WordFrame, rightFrame: inout WordFrame) {
        if leftFrame.maxX < rightFrame.minX {
            // If there's a gap, middleX is halfway between the left frame's maxX and the right frame's minX
            let middleX = (leftFrame.maxX + rightFrame.minX) / 2
            rightFrame.minX = middleX
            leftFrame.maxX = middleX
        } else {
            // If there's an overlap or the frames are touching, leftFrame.maxX is set to rightFrame.minX
            leftFrame.maxX = rightFrame.minX
        }
    }

    /// Adjusts the top and bottom arrays of WordFrame instances to meet vertically with an equal gap between them,
    /// but only if they belong to the same sura.
    ///
    /// - Parameters:
    ///   - top: An array of WordFrame instances representing the top line, to be adjusted downwards.
    ///   - bottom: An array of WordFrame instances representing the bottom line, to be adjusted upwards.
    static func unionVertically(top: inout [WordFrame], bottom: inout [WordFrame]) {
        // Early return if not continuous lines (different suras).
        guard top.last?.word.verse.sura == bottom.first?.word.verse.sura else {
            return
        }

        let topMaxY = top.map(\.maxY).max() ?? 0
        let bottomMinY = bottom.map(\.minY).min() ?? 0
        let middleY = (topMaxY + bottomMinY) / 2

        for i in 0 ..< top.count {
            top[i].maxY = middleY
        }
        for i in 0 ..< bottom.count {
            bottom[i].minY = middleY
        }
    }

    private static func unionEdge(
        _ list: inout [WordFrame],
        keyPath: WritableKeyPath<WordFrame, Int>,
        reduce: ([Int]) -> Int?
    ) {
        let value = reduce(list.map { $0[keyPath: keyPath] })!
        for i in 0 ..< list.count {
            list[i][keyPath: keyPath] = value
        }
    }

    static func unionLeftEdge(_ list: inout [WordFrame]) {
        unionEdge(&list, keyPath: \.minX, reduce: { $0.min() })
    }

    static func unionRightEdge(_ list: inout [WordFrame]) {
        unionEdge(&list, keyPath: \.maxX, reduce: { $0.max() })
    }
}
