//
//  String+HTMLEntities.swift
//

import Foundation

extension String {
    /// Decodes the HTML character references that some translation databases store, such as `&quot;` and `&#39;`.
    ///
    /// Decodes in a single pass, so `&amp;quot;` becomes `&quot;`. Unknown names, numbers that aren't Unicode
    /// scalars, and C0 and C1 control characters other than tab, line feed, and carriage return stay as written.
    func decodingHTMLEntities() -> String {
        guard contains("&") else {
            return self
        }
        let matches = HTMLEntity.regex.matches(in: self, range: NSRange(startIndex ..< endIndex, in: self))
        var decoded = ""
        var current = startIndex
        for match in matches {
            guard let range = Range(match.range, in: self) else {
                continue
            }
            let entity = self[range]
            decoded += self[current ..< range.lowerBound]
            decoded += HTMLEntity.character(for: entity) ?? String(entity)
            current = range.upperBound
        }
        decoded += self[current...]
        return decoded
    }
}

private enum HTMLEntity {
    // MARK: Internal

    static let regex = try! NSRegularExpression( // swiftlint:disable:this force_try
        pattern: "&(?:#[0-9]+|#[xX][0-9A-Fa-f]+|[A-Za-z][A-Za-z0-9]*);"
    )

    static func character(for entity: Substring) -> String? {
        let name = entity.dropFirst().dropLast()
        guard name.hasPrefix("#") else {
            return namedCharacters[String(name)]
        }

        let number = name.dropFirst()
        let codePoint = number.hasPrefix("x") || number.hasPrefix("X")
            ? UInt32(number.dropFirst(), radix: 16)
            : UInt32(number)
        guard let codePoint, let scalar = Unicode.Scalar(codePoint), !isDisallowedControl(scalar) else {
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

    /// C0 control characters, including U+0000, except tab, line feed, and carriage return, plus DEL and the
    /// C1 control characters (U+007F through U+009F), such as the invisible U+0092 that a Windows-1252 style
    /// `&#146;` names.
    private static func isDisallowedControl(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x09, 0x0A, 0x0D:
            return false
        case 0x00 ... 0x1F, 0x7F ... 0x9F:
            return true
        default:
            return false
        }
    }
}
