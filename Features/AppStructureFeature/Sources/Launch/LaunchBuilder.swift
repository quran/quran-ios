//
//  LaunchBuilder.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-01-09.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import AppDependencies
import AppMigrationFeature
import AudioUpdater
import ReciterService
import SettingsService
import UIKit

@MainActor
public struct LaunchBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies, preparation: LaunchPreparation? = nil) {
        self.container = container
        self.preparation = preparation ?? LaunchPreparation(container: container)
    }

    // MARK: Public

    public func launchStartup() -> LaunchStartup {
        let audioUpdater = AudioUpdater(baseURL: container.appHost)
        return LaunchStartup(
            appBuilder: AppBuilder(container: container),
            preparation: preparation,
            audioUpdater: audioUpdater,
            reviewService: ReviewService(analytics: container.analytics),
            appIconService: container.appIconService(),
            analyticsUserPropertiesReporterBuilder: AnalyticsUserPropertiesReporterBuilder(container: container)
        )
    }

    // MARK: Internal

    let container: AppDependencies
    private let preparation: LaunchPreparation
}
