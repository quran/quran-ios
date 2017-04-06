//
//  _Utilities.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 10/23/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

extension NSObjectProtocol {
    func cast<T, U>(_ value: T, file: StaticString = #file, line: UInt = #line) -> U {
        return cast(value, message: "Couldn't cast object '\(value)' to '\(U.self)'", file: file, line: line)
    }

    func cast<T, U>(_ value: T, message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) -> U {
        guard let castedValue = value as? U else {
            fatalError("[\(type(of: self))]: \(message()); file\(file), line:\(line)")
        }
        return castedValue
    }
}
