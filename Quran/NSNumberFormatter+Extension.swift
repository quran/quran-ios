//
//  NSNumberFormatter+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/1/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

extension NumberFormatter {

    func format(_ number: NSNumber) -> String {
        return string(from: number) ?? number.description
    }
}
