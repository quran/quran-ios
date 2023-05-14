//
//  Runs.swift
//  Quran
//
//  Created by Afifi, Mohamed on 2018-04-04.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
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
public enum Runs: Equatable, Sendable {
    case one
    case two
    case three
    case four
    case indefinite

    var maxRuns: Int {
        switch self {
        case .one: return 1
        case .two: return 2
        case .three: return 3
        case .four: return 4
        case .indefinite: return .max
        }
    }
}
