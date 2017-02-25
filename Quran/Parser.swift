//
//  Parser.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/23/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation

protocol Parser {
    associatedtype From
    associatedtype To

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
