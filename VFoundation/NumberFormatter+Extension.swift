//
//  NumberFormatter+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/1/16.
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

extension NumberFormatter {

    @nonobjc public func format(_ number: NSNumber) -> String {
        return string(from: number) ?? number.description
    }

    @nonobjc public func format(_ number: Int) -> String {
        return format(NSNumber(value: number))
    }

    @nonobjc public func format(_ number: Double) -> String {
        return format(NSNumber(value: number))
    }

    @nonobjc public func format(_ number: Float) -> String {
        return format(NSNumber(value: number))
    }
}
