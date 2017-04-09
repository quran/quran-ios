//
//  Parser.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/23/17.
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

protocol Parser {
    associatedtype From
    associatedtype To //swiftlint:disable:this type_name

    func parse(_ from: From) throws -> To
}

struct AnyParser<From, To>: Parser {
    let parseClosure: (From) throws -> To
    init<ParserType: Parser>(_ parser: ParserType) where ParserType.From == From, ParserType.To == To {
        parseClosure = parser.parse
    }

    func parse(_ from: From) throws -> To {
        return try parseClosure(from)
    }
}
