//
//  AnalyticsLibrary.swift
//
//
//  Created by Mohamed Afifi on 2023-06-12.
//

public protocol AnalyticsLibrary: Sendable {
    func logEvent(_ name: String, value: String)
    func logEvent(_ name: String, parameters: [String: AnalyticsValue])
    func setUserProperty(_ value: String?, forName name: String)
}

extension AnalyticsLibrary {
    // MARK: Public

    // No-op defaults keep libraries written before these requirements compiling.
    public func logEvent(_: String, parameters _: [String: AnalyticsValue]) {}
    public func setUserProperty(_: String?, forName _: String) {}

    public func setUserProperty(_ value: String?, for property: AnalyticsUserProperty) {
        setUserProperty(value, forName: property.rawValue)
    }
}
