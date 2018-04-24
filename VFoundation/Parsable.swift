//
//  Parsable.swift
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

import SwiftyJSON

public protocol Parsable {
    init(json: JSON) throws
}

private func parsingError(_ message: String) -> ParsingError {
    NSLog("JSON parsing error: \(message)")
    return ParsingError.parsing(message)
}

private func castValue<T>(_ value: T?, json: JSON) throws -> T {
    guard let castedValue = value else {
        throw parsingError("JSON not convertible to '\(T.self)'. JSON: '\(json)'")
    }
    return castedValue
}

extension Bool: Parsable {
    public init(json: JSON) throws {
        self = try json.parsed()
    }
}

extension Int: Parsable {
    public init(json: JSON) throws {
        self = try json.parsed()
    }
}

extension Float: Parsable {
    public init(json: JSON) throws {
        self = try json.parsed()
    }
}

extension Double: Parsable {
    public init(json: JSON) throws {
        self = try json.parsed()
    }
}

extension String: Parsable {
    public init(json: JSON) throws {
        self = try json.parsed()
    }
}

extension URL: Parsable {
    public init(json: JSON) throws {
        self = try json.parsed()
    }
}

extension JSON {

    public func parsed() throws -> Bool {
        return try castValue(bool, json: self)
    }

    public func parsed() throws -> Int {
        return try castValue(int, json: self)
    }

    public func parsed() throws -> Float {
        return try castValue(float, json: self)
    }

    public func parsed() throws -> Double {
        return try castValue(double, json: self)
    }

    public func parsed() throws -> String {
        return try castValue(string, json: self)
    }

    public func parsedAsDoubleFromString() throws -> Double {
        let string: String = try parsed()
        guard let value = Double(string) else {
            throw parsingError("String not convertible to 'Double'. JSON: '\(string)'")
        }
        return value
    }

    public func parsed() throws -> URL {
        return try castValue(url, json: self)
    }

    public func unencodedURL() -> URL? {
        return string.flatMap { Foundation.URL(string: $0) }
    }

    public func parsed() throws -> [JSON] {
        return try castValue(array, json: self)
    }

    public func parsed() throws -> [String: JSON] {
        return try castValue(dictionary, json: self)
    }

    public func parsed<T>(map: (JSON) throws -> T) throws -> [String: T] {
        return try parsed().reduce([String: T]()) { (dictionary: [String: T], element: (String, JSON)) -> [String: T] in
            var d = dictionary
            d[element.0] = try map(element.1)
            return d
        }
    }

    public func parsableArrayParsed<ElementType: Parsable>(continueOnError: Bool = false) throws -> [ElementType] {
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
        }.compactMap { $0 }
    }

    public func parsedOptional<T>(_ key: String, map: (JSON) throws -> T) rethrows -> T? {
        let value = self[key]
        guard value.error == nil else {
            return nil
        }
        return try map(value)
    }
}
