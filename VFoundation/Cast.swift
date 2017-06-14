//
//  Cast.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/29/16.
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

public func cast<S, T>(_ object: S, function: StaticString = #function) -> T {
    guard let value = object as? T else {
        fatalError("\(function): Couldn't cast object of type '\(type(of: (object)))' to '\(T.self)' where object value is '\(object)'")
    }
    return value
}

public func unwrap<T>(_ object: T?, function: StaticString = #function) -> T {
    guard let value = object else {
        fatalError("\(function): Couldn't unwrap object of type '\(type(of: (object)))', found nil.")
    }
    return value
}

public func suppress(message: StaticString = #function, _ body: () throws -> Void) {
    do {
        try body()
    } catch {
        Crash.recordError(error, reason: "\(message)", fatalErrorOnDebug: false)
    }
}
