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
}
