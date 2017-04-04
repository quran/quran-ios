//
//  NotImplemented.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/28/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

func unimplemented<T>(function: StaticString = #function, file: StaticString = #file, line: Int = #line) -> T {
    fatalError("Function '\(function)' is unimplemented at: \(file) - \(line)")
}

func unimplemented(function: StaticString = #function, file: StaticString = #file, line: Int = #line) -> Never {
    fatalError("Function '\(function)' is unimplemented at: \(file) - \(line)")
}

func expectedToBeSubclassed(function: StaticString = #function, file: StaticString = #file, line: Int = #line) -> Never {
    fatalError("\(#function) Should be implemented by subclasses")
}
