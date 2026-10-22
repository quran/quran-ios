//
//  AnalyticsUserPropertiesReporterBuilder.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import AppDependencies
import Foundation
import NoorUI
import ReciterService

@MainActor
struct AnalyticsUserPropertiesReporterBuilder {
    // MARK: Internal

    let container: AppDependencies

    func build(appIconService: AppIconService) -> AnalyticsUserPropertiesReporter {
        let appLanguage = Bundle.main.preferredLocalizations.first
        #if QURAN_SYNC
        return AnalyticsUserPropertiesReporter(
            analytics: container.analytics,
            appIconService: appIconService,
            reciterRetriever: ReciterDataRetriever(),
            appLanguage: appLanguage,
            authenticationClient: container.authenticationClient
        )
        #else
        return AnalyticsUserPropertiesReporter(
            analytics: container.analytics,
            appIconService: appIconService,
            reciterRetriever: ReciterDataRetriever(),
            appLanguage: appLanguage
        )
        #endif
    }
}
