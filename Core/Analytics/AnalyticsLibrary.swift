//
//  AnalyticsLibrary.swift
//
//
//  Created by Mohamed Afifi on 2023-06-12.
//

import Foundation

public protocol AnalyticsLibrary {
    func logEvent(_ name: String, value: String)
}
