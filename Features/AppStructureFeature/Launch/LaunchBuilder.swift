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
        print("Received URL: \(url)")
        
        // Function to extract surah and ayah numbers from the URL
        func extractSurahAndAyah(from url: URL) -> (surah: Int, ayah: Int)? {
            // For custom schemes, use the host and path
            let components = (url.host ?? "") + url.path
            let parts = components.trimmingCharacters(in: CharacterSet(charactersIn: "/")).components(separatedBy: "/")
            
            guard parts.count >= 2,
                  let surah = Int(parts[0]),
                  let ayah = Int(parts[1]) else {
                return nil
            }
            return (surah, ayah)
        }
        
        // Handle both custom URL scheme and Universal Links
        if url.scheme == "quran" || url.scheme == "quran-ios" {
            print("URL scheme recognized")
            
                let path: String
                if #available(iOS 16.0, *) {
                    path = url.path(percentEncoded: true)
                } else {
                    path = url.path
                }
            if let (surah, ayah) = extractSurahAndAyah(from: url) {
                print("Extracted Surah: \(surah), Ayah: \(ayah)")
                _ = navigateToAyah(surah: surah, ayah: ayah)
            } else {
                _ = navigateTo(path: path)
            }
        }
    }
    
    // MARK: Internal
    
    let container: AppDependencies
    
    // MARK: Private
    
    private func navigateToAyah(surah: Int, ayah: Int) -> Bool {
        // Implement the logic to navigate to the specific surah and ayah
        print("Navigating to Surah \(surah), Ayah \(ayah)")
        // Quran.hafsMadani1405.suras[surah].verses[ayah]
        return true
        // You would replace this with actual navigation logic
    }
    
    private func navigateTo(path: String) -> Bool {
        // Implement the logic to navigate based on the path
        print("Navigating to path: \(path)")
        return true
        // You would replace this with actual navigation logic
    }
}
