//
//  NSNumberFormatter+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/1/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

extension NSNumberFormatter {

    func format(number: NSNumber) -> String {
        return stringFromNumber(number) ?? number.description
    }
}
