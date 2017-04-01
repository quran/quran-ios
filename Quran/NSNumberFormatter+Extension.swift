//
//  NSNumberFormatter+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/1/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

extension NumberFormatter {

    @nonobjc func format(_ number: NSNumber) -> String {
        return string(from: number) ?? number.description
    }

    @nonobjc func format(_ number: Int) -> String {
        return format(NSNumber(value: number))
    }

    @nonobjc func format(_ number: Double) -> String {
        return format(NSNumber(value: number))
    }

    @nonobjc func format(_ number: Float) -> String {
        return format(NSNumber(value: number))
    }
}
