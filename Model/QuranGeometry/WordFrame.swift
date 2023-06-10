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
    public let line: Int
    public let word: Word

    public var minX: Int
    public var maxX: Int
    public var minY: Int
    public var maxY: Int
    public var cropInsets: UIEdgeInsets = .zero

    public init(line: Int, word: Word, minX: Int, maxX: Int, minY: Int, maxY: Int) {
        self.line = line
        self.word = word
        self.minX = minX
        self.maxX = maxX
        self.minY = minY
        self.maxY = maxY
    }

    public func withCropInsets(_ cropInsets: UIEdgeInsets) -> Self {
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
}

extension WordFrame: Encodable {
    enum CodingKeys: String, CodingKey {
        case word
        case frame
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(word, forKey: .word)
        try container.encode(rect, forKey: .frame)
    }
}
