//
//  AnalyticsValue.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

public enum AnalyticsValue: Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
}

extension AnalyticsValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .string(let value): value
        case .int(let value): String(value)
        case .double(let value): String(value)
        case .bool(let value): String(value)
        }
    }
}
