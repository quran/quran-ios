//
//  LocalizationConverter.swift
//  Android 2 iOS Localization Converter
//
//  Created by Mohamed Afifi on 5/28/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation
import AEXML

private struct Pair {
    let one: String
    let second: String
}

private let replaces = [
    Pair(one: "%@", second: "%s"),
    Pair(one: "%1$@", second: "%1$s"),
    Pair(one: "%2$@", second: "%2$s"),
    Pair(one: "%3$@", second: "%3$s"),
    Pair(one: "%4$@", second: "%4$s"),
    Pair(one: "%5$@", second: "%5$s"),
    Pair(one: "%6$@", second: "%6$s"),
    Pair(one: "%7$@", second: "%7$s"),
    Pair(one: "%8$@", second: "%8$s"),
    Pair(one: "%9$@", second: "%9$s"),
    Pair(one: "%10$@", second: "%10$s"),
]

private let digitReplaces = [
    Pair(one: "%d", second: "%s"),
    Pair(one: "%1$d", second: "%1$s"),
    Pair(one: "%2$d", second: "%2$s"),
    Pair(one: "%3$d", second: "%3$s"),
    Pair(one: "%4$d", second: "%4$s"),
    Pair(one: "%5$d", second: "%5$s"),
    Pair(one: "%6$d", second: "%6$s"),
    Pair(one: "%7$d", second: "%7$s"),
    Pair(one: "%8$d", second: "%8$s"),
    Pair(one: "%9$d", second: "%9$s"),
    Pair(one: "%10$d", second: "%10$s"),
]

class LocalizationConverter {

    private func preprocess(_ value: String, shouldUseDigits: Bool) -> String {
        var processed = value
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\\\n")
            .replacingOccurrences(of: "\\\"", with: "$$$$$^^^^^^@@@")
            .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "$$$$$^^^^^^@@@", with: "\\\"")
        for replace in (shouldUseDigits ? digitReplaces : replaces) {
            processed = processed.replacingOccurrences(of: replace.second, with: replace.one)
        }
        return processed
    }
    
    func convert(androidXml: Data) -> (strings: String, plural: String) {

        var options = AEXMLOptions()
        options.parserSettings.shouldTrimWhitespace = false
        let androidDoc = try! AEXMLDocument(xml: androidXml, options: options)

        let strings = androidDoc.root["string"].all ?? []

        var translations: [String: String] = [:]

        let translationsPairs: [(String, String)] = strings.map { string in
            let name = string.attributes["name"]!
            let value = preprocess(string.string, shouldUseDigits: false)
            translations[name] = value
            return (name, value)
        }
        var convertedStrings = translationsPairs.map { arg -> (String, String) in
            let (name, value) = arg
            var translation = value
            if value.hasPrefix("@string/") {
                translation = translations[value.replacingOccurrences(of: "@string/", with: "")]!
            }
            return (name, translation)
        }

        let arrays = androidDoc.root["string-array"].all ?? []
        for array in arrays {
            let name = array.attributes["name"]!
            for (index, quantity) in (array["item"].all ?? []).enumerated() {
                convertedStrings.append((name + (index + 1).description, preprocess(quantity.string, shouldUseDigits: false)))
            }
        }

        let plurals = androidDoc.root["plurals"].all ?? []
        
        
        let iOSDoc = AEXMLDocument()

        let root = iOSDoc.addChild(name: "plist", attributes: ["version": "1.0"]).addChild(name: "dict")

        for plural in plurals {
            let name = plural.attributes["name"]!
            
            root.addChild(name: "key", value: name)
            let dict = root.addChild(name: "dict")

            dict.addChild(name: "key", value: "NSStringLocalizedFormatKey")
            dict.addChild(name: "string", value: "%#@\(name)@")
            dict.addChild(name: "key", value: name)

            let values = dict.addChild(name: "dict")
            values.addChild(name: "key", value: "NSStringFormatSpecTypeKey")
            values.addChild(name: "string", value: "NSStringPluralRuleType")
            values.addChild(name: "key", value: "NSStringFormatValueTypeKey")
            values.addChild(name: "string", value: "d")

            for quantity in plural["item"].all ?? [] {
                let q = quantity.attributes["quantity"]!
                values.addChild(name: "key", value: q)
                var value = preprocess(quantity.string, shouldUseDigits: true)
                if value.hasPrefix("@string/") {
                    value = translations[value.replacingOccurrences(of: "@string/", with: "")]!
                }
                values.addChild(name: "string", value: value)
            }
        }

        return (strings: convertedStrings
            .map { String(format: "\"%@\" = \"%@\";", $0, $1) }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n"),
                plural: iOSDoc.xml.replacingOccurrences(of: "\t", with: "    "))
    }
}
