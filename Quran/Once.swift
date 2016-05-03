//
//  Once.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

// class not struct to allow let declaration because once will be a mutating function.
final class Once {

    private (set) var exuected = false

    func once(@noescape block: () -> Void) {
        guard !exuected else {
            return
        }
        block()
    }
}
