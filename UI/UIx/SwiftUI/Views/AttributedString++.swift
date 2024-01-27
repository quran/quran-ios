//
//  AttributedString++.swift
//
//
//  Created by Mohamed Afifi on 2024-01-20.
//

import SwiftUI

extension AttributedString {
    public func range(
        from range: Range<String.Index>,
        overallRange: Range<String.Index>,
        overallText: String
    ) -> Range<AttributedString.Index>? {
        let clampedRange = range.clamped(to: overallRange)
        if clampedRange.lowerBound >= clampedRange.upperBound {
            return nil
        }

        let startDistance = overallText.distance(from: overallRange.lowerBound, to: clampedRange.lowerBound)
        let endDistance = overallText.distance(from: overallRange.lowerBound, to: clampedRange.upperBound)

        let start = index(startIndex, offsetByCharacters: startDistance)
        let end = index(startIndex, offsetByCharacters: endDistance)
        return start ..< end
    }
}
