//
//  ReadingSelectorBuilder.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-02-14.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import AppDependencies
import ImageService
import QuranKit
import ReadingService
import UIKit

@MainActor
public struct ReadingSelectorBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build() -> UIViewController {
        let viewModel = ReadingSelectorViewModel(
            resources: container.readingResources,
            selectionGuard: selectionGuard()
        )
        return ReadingSelectorViewController(viewModel: viewModel)
    }

    // MARK: Private

    private let container: AppDependencies

    private func selectionGuard() -> ReadingSelectionGuard {
        ReadingSelectionGuard { reading in
            guard reading == .hafs_1441 else {
                return true
            }
            let readingDirectory = Self.readingDirectory(reading, container: container)
            let linePageAssets = LinePageAssetService(readingDirectory: readingDirectory)
            return linePageAssets.isReadingAvailable()
        }
    }

    private static func readingDirectory(_ reading: Reading, container: AppDependencies) -> URL? {
        let remotePath = container.remoteResources?.resource(for: reading)?.downloadDestination.url
        let bundlePath = Bundle.main.url(forResource: reading.localPath, withExtension: nil)
        return remotePath ?? bundlePath
    }
}
