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

    public func rangeAsNSRange(_ range: Range<String.Index>) -> NSRange {
        NSRange(range, in: self)
    }
}

extension String {
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
}
