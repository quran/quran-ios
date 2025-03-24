//
//  AnalyticsLibrary.swift
//
//
//  Created by Mohamed Afifi on 2023-06-12.
//

public protocol AnalyticsLibrary: Sendable {
    func logEvent(_ name: String, value: String)
}
