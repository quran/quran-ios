//
//  AnalyticsSettingsReporterBuilder.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import AppDependencies
import Foundation
import NoorUI
import ReciterService
import SystemDependencies

@MainActor
struct AnalyticsSettingsReporterBuilder {
    // MARK: Internal

    let container: AppDependencies

    func build(appIconService: AppIconService) -> AnalyticsSettingsReporter {
        let appLanguage = Bundle.main.preferredLocalizations.first
        #if QURAN_SYNC
        return AnalyticsSettingsReporter(
            analytics: container.analytics,
            appIconService: appIconService,
            reciterRetriever: ReciterDataRetriever(),
            appLanguage: appLanguage,
            time: DefaultSystemTime(),
            authenticationClient: container.authenticationClient
        )
        #else
        return AnalyticsSettingsReporter(
            analytics: container.analytics,
            appIconService: appIconService,
            reciterRetriever: ReciterDataRetriever(),
            appLanguage: appLanguage,
            time: DefaultSystemTime()
        )
        #endif
    }
}
