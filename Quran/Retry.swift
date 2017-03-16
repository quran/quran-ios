//
//  Retry.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/12/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

func attempt<T>(times: UInt, _ body: () throws -> T) throws -> T {
    precondition(times > 0, "cannot execute something 0 times")
    var lastError: Error?
    for _ in 0..<times {
        do {
            return try body()
        } catch {
            lastError = error
        }
    }
    throw lastError! // swiftlint:disable:this force_unwrapping
}
