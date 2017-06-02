//
//  XCAssert+Extensions.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/27/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//
import XCTest

func expectNotToThrow(file: StaticString = #file, line: UInt = #line, _ body: () throws -> Void) {
    do {
        try body()
    } catch {
        XCTFail("Function expected not to throw errors. But found \(error)", file: file, line: line)
    }
}
