//
//  WordFrameScale.swift
//
//
//  Created by Mohamed Afifi on 2021-12-26.
//

import QuranGeometry
import QuranKit
import UIKit

extension WordFrameScale {
    public static func scaling(imageSize: CGSize, into imageViewSize: CGSize) -> WordFrameScale {
        let scale: CGFloat
        if imageSize.width / imageSize.height < imageViewSize.width / imageViewSize.height {
            scale = imageViewSize.height / imageSize.height
        } else {
            scale = imageViewSize.width / imageSize.width
        }
        let xOffset = (imageViewSize.width - (scale * imageSize.width)) / 2
        let yOffset = (imageViewSize.height - (scale * imageSize.height)) / 2
        return WordFrameScale(scale: scale, xOffset: xOffset, yOffset: yOffset)
    }
}

extension CGRect {
    public func scaled(by scale: WordFrameScale) -> CGRect {
        CGRect(
            x: minX * scale.scale + scale.xOffset,
            y: minY * scale.scale + scale.yOffset,
            width: width * scale.scale,
            height: height * scale.scale
        )
    }
}

extension WordFrameCollection {
    public func wordAtLocation(_ location: CGPoint, imageScale: WordFrameScale) -> Word? {
        let flattenFrames = frames.values.flatMap { $0 }
        for frame in flattenFrames {
            let rectangle = frame.rect.scaled(by: imageScale)
            if rectangle.contains(location) {
                return frame.word
            }
        }
        return nil
    }
}

extension WordFrame {
    static func alignedVertically(_ list: [WordFrame]) -> [WordFrame] {
        let minY = list.map(\.minY).min()!
        let maxY = list.map(\.maxY).max()!
        var result: [WordFrame] = []
        for var frame in list {
            frame.minY = minY
            frame.maxY = maxY
            result.append(frame)
        }
        return result
    }

    mutating func unionHorizontally(left: inout WordFrame) {
        let distance = Int(ceil((CGFloat(minX) - CGFloat(left.maxX)) / 2))
        left.maxX += distance
        minX -= distance
        left.maxX = minX
    }

    static func unionVertically(top: inout [WordFrame], bottom: inout [WordFrame]) {
        // If not continuous lines (different suras).
        guard top.last!.word.verse.sura == bottom.first!.word.verse.sura else {
            return
        }

        var topMaxY = top.map(\.maxY).max()!
        var bottomMinY = bottom.map(\.minY).min()!

        let distance = Int(ceil((CGFloat(bottomMinY) - CGFloat(topMaxY)) / 2))
        topMaxY += distance
        bottomMinY -= distance
        topMaxY = bottomMinY

        for i in 0 ..< top.count {
            top[i].maxY = topMaxY
        }
        for i in 0 ..< bottom.count {
            bottom[i].minY = bottomMinY
        }
    }

    private static func unionEdge(
        _ list: inout [WordFrame],
        keyPath: WritableKeyPath<WordFrame, Int>,
        isMin: Bool
    ) {
        var longest: [Int] = []
        for i in 0 ..< list.count - 1 {
            let pivot = list[i]
            var running = [i]
            for j in i + 1 ..< list.count {
                let other = list[j]
                if abs(pivot[keyPath: keyPath] - other[keyPath: keyPath]) < 50 {
                    running.append(j)
                }
            }
            if running.count > longest.count {
                longest = running
            }
        }

        guard !longest.isEmpty else {
            return
        }

        let values = longest.map { list[$0][keyPath: keyPath] }
        let value = isMin ? values.min()! : values.max()!
        for i in longest {
            var frame = list[i]
            frame[keyPath: keyPath] = value
            list[i] = frame
        }
    }

    static func unionLeftEdge(_ list: inout [WordFrame]) {
        unionEdge(&list, keyPath: \.minX, isMin: true)
    }

    static func unionRightEdge(_ list: inout [WordFrame]) {
        unionEdge(&list, keyPath: \.maxX, isMin: false)
    }
}
