//
//  URL+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/7/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

extension URL {

    init(validURL: String) {
        self.init(string: validURL)! // swiftlint:disable:this force_unwrapping
    }
}
