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
    
    public func handleIncomingUrl(urlContext: UIOpenURLContext) {
        let url = urlContext.url
        
        if url.scheme == "quran" || url.scheme == "quran-ios" {
            let path: String
            
            if #available(iOS 16.0, *) {
                path = url.path(percentEncoded: true)
            } else {
                path = url.path
            }
            
            _ = navigateTo(path: path)
        }
    }

    // MARK: Internal

    let container: AppDependencies
    
    // MARK: Public
    private func navigateTo(path: String) -> Bool {
        // Implement the actual navigation or handling logic in follow up pr
        return true
    }
}
