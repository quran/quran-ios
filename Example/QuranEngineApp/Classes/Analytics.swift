//
//  Analytics.swift
//  QuranEngineApp
//
//  Created by Mohamed Afifi on 2023-06-24.
//

import Analytics
import Logging
import VLogging

struct LoggingAnalyticsLibrary: AnalyticsLibrary {
    func logEvent(_ name: String, value: String) {
        logger.info("[Analytics] \(name)=\(value)")
    }

    func logEvent(_ name: String, parameters: [String: AnalyticsValue]) {
        let parameters = parameters
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")
        logger.info("[Analytics] event \(name) {\(parameters)}")
    }

    func setUserProperty(_ value: String?, forName name: String) {
        logger.info("[Analytics] user_property \(name)=\(value ?? "<cleared>")")
    }
}
