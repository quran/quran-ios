//
//  String+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/25/17.
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

import Foundation

extension String {
    public var lastPathComponent: String {
        (self as NSString).lastPathComponent
    }

    public var pathExtension: String {
        (self as NSString).pathExtension
    }

    public var stringByDeletingLastPathComponent: String {
        (self as NSString).deletingLastPathComponent
    }

    public var stringByDeletingPathExtension: String {
        (self as NSString).deletingPathExtension
    }

    public var pathComponents: [String] {
        (self as NSString).pathComponents
    }

    public func stringByAppendingPath(_ path: String) -> String {
        (self as NSString).appendingPathComponent(path)
    }

    public func stringByAppendingExtension(_ pathExtension: String) -> String {
        (self as NSString).appendingPathExtension(pathExtension) ?? (self + "." + pathExtension)
    }

    public func byteOffsetToStringIndex(_ byteOffset: Int) -> String.Index? {
        let index = utf8.index(utf8.startIndex, offsetBy: byteOffset)
        return index.samePosition(in: self)
    }
}

extension String {
    public func ranges(of regex: NSRegularExpression) -> [Range<String.Index>] {
        let range = NSRange(startIndex ..< endIndex, in: self)
        let matches = regex.matches(in: self, range: range)
        return matches.compactMap { Range($0.range, in: self) }
    }

    public func replacingOccurrences(matchingPattern pattern: String, replacementProvider: (String) -> String?) -> String {
        let expression = try! NSRegularExpression(pattern: pattern, options: []) // swiftlint:disable:this force_try
        let matches = expression.matches(in: self, options: [], range: NSRange(startIndex ..< endIndex, in: self))
        return matches.reversed().reduce(into: self) { current, result in
            let range = Range(result.range, in: current)!
            let token = String(current[range])
            guard let replacement = replacementProvider(token) else { return }
            current.replaceSubrange(range, with: replacement)
        }
    }

    public func replaceMatches(
        of regex: NSRegularExpression,
        replace: (Substring, Int) -> String
    ) -> (String, [Range<String.Index>]) {
        let ranges = ranges(of: regex)
        return replacing(sortedRanges: ranges, body: replace)
    }
}

extension String {
    public func replacing(
        sortedRanges: [Range<String.Index>],
        body: (Substring, Int) -> String
    ) -> (String, [Range<String.Index>]) {
        var newText = self
        var offsets = [(start: Int, length: Int, offset: Int)]()
        var replacementIndex = sortedRanges.count - 1

        for matchRange in sortedRanges.reversed() {
            let match = self[matchRange]

            let replacement = body(match, replacementIndex)
            newText.replaceSubrange(matchRange, with: replacement)

            let replacementStart = newText.distance(from: newText.startIndex, to: matchRange.lowerBound)
            offsets.append((
                start: replacementStart,
                length: replacement.count,
                offset: match.count - replacement.count
            ))

            replacementIndex -= 1
        }

        var accumlatedOffset = 0
        let ranges = offsets.reversed().map { data -> Range<String.Index> in
            let start = newText.index(newText.startIndex, offsetBy: data.start - accumlatedOffset)
            let end = newText.index(start, offsetBy: data.length)
            accumlatedOffset += data.offset
            return start ..< end
        }
        return (newText, ranges)
    }
}
