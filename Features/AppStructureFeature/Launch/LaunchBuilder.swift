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

@MainActor
public struct LaunchBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func launchStartup() -> LaunchStartup {
        let audioUpdater = AudioUpdater(baseURL: container.appHost)
        let fileSystemMigrator = FileSystemMigrator(
            databasesURL: container.databasesURL,
            recitersRetreiver: ReciterDataRetriever()
        )
        return LaunchStartup(
            appBuilder: AppBuilder(container: container),
            audioUpdater: audioUpdater,
            fileSystemMigrator: fileSystemMigrator,
            recitersPathMigrator: RecitersPathMigrator(),
            reviewService: ReviewService(analytics: container.analytics)
        )
    }

    // MARK: Internal

    let container: AppDependencies
}
