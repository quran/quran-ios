//
//  Parsable.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/25/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import SwiftyJSON

protocol Parsable {
    init(json: JSON) throws
}

private func parsingError(_ message: String) -> NetworkError {
    NSLog("JSON parsing error: \(message)")
    return NetworkError.parsing(message)
}

private func castValue<T>(_ value: T?, json: JSON) throws -> T {
    guard let castedValue = value else {
        throw parsingError("JSON not convertible to '\(T.self)'. JSON: '\(json)'")
    }
    return castedValue
}

extension Bool: Parsable {
    init(json: JSON) throws {
        self = try json.parsed()
    }
}

extension Int: Parsable {
    init(json: JSON) throws {
        self = try json.parsed()
    }
}

extension Float: Parsable {
    init(json: JSON) throws {
        self = try json.parsed()
    }
}

extension Double: Parsable {
    init(json: JSON) throws {
        self = try json.parsed()
    }
}

extension String: Parsable {
    init(json: JSON) throws {
        self = try json.parsed()
    }
}

extension URL: Parsable {
    init(json: JSON) throws {
        self = try json.parsed()
    }
}

extension JSON {

    func parsed() throws -> Bool {
        return try castValue(bool, json: self)
    }

    func parsed() throws -> Int {
        return try castValue(int, json: self)
    }

    func parsed() throws -> Float {
        return try castValue(float, json: self)
    }

    func parsed() throws -> Double {
        return try castValue(double, json: self)
    }

    func parsed() throws -> String {
        return try castValue(string, json: self)
    }

    func parsedAsDoubleFromString() throws -> Double {
        let string: String = try parsed()
        guard let value = Double(string) else {
            throw parsingError("String not convertible to 'Double'. JSON: '\(string)'")
        }
        return value
    }

    func parsed() throws -> URL {
        return try castValue(url, json: self)
    }

    func unencodedURL() -> URL? {
        return string.flatMap { Foundation.URL(string: $0) }
    }

    func parsed() throws -> [JSON] {
        return try castValue(array, json: self)
    }

    func parsed() throws -> [String: JSON] {
        return try castValue(dictionary, json: self)
    }

    func parsed<T>(map: (JSON) throws -> T) throws -> [String: T] {
        return try parsed().reduce([String: T]()) { (dictionary: [String: T], element: (String, JSON)) -> [String: T] in
            var d = dictionary
            d[element.0] = try map(element.1)
            return d
        }
    }

    func parsableArrayParsed<ElementType: Parsable>(continueOnError: Bool = false) throws -> [ElementType] {
        let array: [JSON] = try parsed()
        return try array.map { element -> ElementType? in
            do {
                return try ElementType(json: element)
            } catch let error {
                if !continueOnError {
                    throw error // rethrow
                }
                return nil
            }
        }.flatMap { $0 }
    }

    func parsedOptional<T>(_ key: String, map: (JSON) throws -> T) rethrows -> T? {
        let value = self[key]
        guard value.error == nil else {
            return nil
        }
        return try map(value)
    }
}
