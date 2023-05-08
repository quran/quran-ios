//
//  SystemTime.swift
//
//
//  Created by Mohamed Afifi on 2023-05-07.
//

import Foundation

protocol SystemTime {
    var now: Date { get }
}

struct DefaultSystemTime: SystemTime {
    var now: Date {
        Date()
    }
}
