//
//  MultipartText+Localization.swift
//
//
//  Created by Mohamed Afifi on 2026-07-19.
//

import Foundation
import Localization

extension MultipartText {
    public static func localizedFormat(
        _ key: String,
        table: Table = .localizable,
        language: Language? = nil,
        _ arguments: MultipartText...
    ) -> MultipartText {
        format(l(key, table: table, language: language), arguments: arguments)
    }

    static func format(_ format: String, arguments: [MultipartText]) -> MultipartText {
        let placeholders = arguments.indices.map { index in
            "\u{E000}\(index)\u{E001}"
        }
        let formattedArguments = placeholders.map { $0 as CVarArg }
        let formatted = String(
            format: format,
            locale: .fixedCurrentLocaleNumbers,
            arguments: formattedArguments
        )

        var result: MultipartText = ""
        var remainder = formatted[...]
        while let nextPlaceholder = placeholders.enumerated()
            .compactMap({ index, placeholder -> (index: Int, range: Range<String.Index>)? in
                guard let range = remainder.range(of: placeholder) else { return nil }
                return (index, range)
            })
            .min(by: { $0.range.lowerBound < $1.range.lowerBound })
        {
            result.append(.text(String(remainder[..<nextPlaceholder.range.lowerBound])))
            result.append(arguments[nextPlaceholder.index])
            remainder = remainder[nextPlaceholder.range.upperBound...]
        }
        result.append(.text(String(remainder)))
        return result
    }
}
