//
//  WordFrame.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import QuranKit
import UIKit

public struct WordFrame: Equatable {
    let line: Int
    public let word: Word

    private var minX: Int
    private var maxX: Int
    private var minY: Int
    private var maxY: Int
    private var cropInsets: UIEdgeInsets = .zero

    init(line: Int, word: Word, minX: Int, maxX: Int, minY: Int, maxY: Int) {
        self.line = line
        self.word = word
        self.minX = minX
        self.maxX = maxX
        self.minY = minY
        self.maxY = maxY
    }

    func withCropInsets(_ cropInsets: UIEdgeInsets) -> Self {
        var mutable = self
        mutable.cropInsets = cropInsets
        return mutable
    }

    public var rect: CGRect {
        CGRect(x: minX - Int(cropInsets.left),
               y: minY - Int(cropInsets.top),
               width: maxX - minX,
               height: maxY - minY)
    }

    static func alignedVertically(_ list: [WordFrame]) -> [WordFrame] {
        let minY = list.min { $0.minY < $1.minY }!.minY
        let maxY = list.max { $0.maxY < $1.maxY }!.maxY
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
        guard abs(top[0].line - bottom[0].line) == 1 else {
            return
        }

        var topMaxY = top.max { $0.maxY < $1.maxY }!.maxY
        var bottomMinY = bottom.min { $0.minY < $1.minY }!.minY

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

    private static func unionEdge(_ list: inout [WordFrame],
                                  get: (WordFrame) -> Int,
                                  set: (inout WordFrame, Int) -> Void,
                                  isMin: Bool)
    {
        var longest: [Int] = []
        for i in 0 ..< list.count - 1 {
            let pivot = list[i]
            var running = [i]
            for j in i + 1 ..< list.count {
                let other = list[j]
                if abs(get(pivot) - get(other)) < 50 {
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

        var value = get(list[longest[0]])
        for i in 1 ..< longest.count {
            let other = get(list[longest[i]])
            value = isMin ? min(value, other) : max(value, other)
        }
        for i in longest {
            var frame = list[i]
            set(&frame, value)
            list[i] = frame
        }
    }

    public static func unionLeftEdge(_ list: inout [WordFrame]) {
        unionEdge(&list, get: { $0.minX }, set: { $0.minX = $1 }, isMin: true)
    }

    public static func unionRightEdge(_ list: inout [WordFrame]) {
        unionEdge(&list, get: { $0.maxX }, set: { $0.maxX = $1 }, isMin: false)
    }
}
