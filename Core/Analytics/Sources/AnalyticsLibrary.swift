//
//  AnalyticsLibrary.swift
//
//
//  Created by Mohamed Afifi on 2023-06-12.
//

public protocol AnalyticsLibrary: Sendable {
    func logEvent(_ name: String, value: String)
    func logEvent(_ name: String, parameters: [String: AnalyticsValue])
    /// Temporary: only clears the user properties internal builds set. Remove it before release.
    func setUserProperty(_ value: String?, forName name: String)
    /// Ties later events to the signed-in account; nil clears it.
    func setUserID(_ userID: String?)
}
