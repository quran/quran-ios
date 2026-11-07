//
//  String+HTMLEntities.swift
//

import Foundation
import Utilities

extension String {
    /// Decodes the HTML character references that some translation databases store, such as `&quot;` and `&#39;`.
    ///
    /// Unknown names and numbers that aren't Unicode scalars stay as written.
    func decodingHTMLEntities() -> String {
        guard contains("&") else {
            return self
        }
        return replacingOccurrences(matchingPattern: HTMLEntity.pattern, replacementProvider: HTMLEntity.character(for:))
    }
}

private enum HTMLEntity {
    // MARK: Internal

    static let pattern = "&(?:#[0-9]+|#[xX][0-9A-Fa-f]+|[A-Za-z][A-Za-z0-9]*);"

    static func character(for entity: String) -> String? {
        let name = entity.dropFirst().dropLast()
        guard name.hasPrefix("#") else {
            return namedCharacters[String(name)]
        }

        let number = name.dropFirst()
        let codePoint = number.hasPrefix("x") || number.hasPrefix("X")
            ? UInt32(number.dropFirst(), radix: 16)
            : UInt32(number)
        guard let codePoint, let scalar = Unicode.Scalar(codePoint) else {
            return nil
        }
        return String(scalar)
    }

    // MARK: Private

    /// The XML entities, which cover every named entity in the translation databases, plus the no-break space.
    private static let namedCharacters: [String: String] = [
        "amp": "&",
        "apos": "'",
        "gt": ">",
        "lt": "<",
        "quot": "\"",
        "nbsp": "\u{00A0}",
    ]
}
