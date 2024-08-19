//
//  ContentImageBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 9/16/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AnnotationsService
import AppDependencies
import Foundation
import ImageService
import QuranKit
import QuranPagesFeature
import ReadingService
import UIKit
import Utilities
import VLogging

@MainActor
public struct ContentImageBuilder: PageViewBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies, highlightsService: QuranHighlightsService) {
        self.container = container
        self.highlightsService = highlightsService
    }

    // MARK: Public

    public func build(at page: Page) -> PageView {
        let reading = ReadingPreferences.shared.reading
        let imageService = Self.buildImageDataService(reading: reading, container: container)

        return ContentImageViewController(
            page: page,
            viewModel: ContentImageViewModel(
                reading: reading,
                page: page,
                imageDataService: imageService,
                highlightsService: highlightsService
            )
        )
    }

    // MARK: Internal

    static func buildImageDataService(reading: Reading, container: AppDependencies) -> ImageDataService {
        let readingDirectory = Self.readingDirectory(reading, container: container)
        return ImageDataService(
            ayahInfoDatabase: reading.ayahInfoDatabase(in: readingDirectory),
            imagesURL: reading.images(in: readingDirectory)
        )
    }

    // MARK: Private

    private let container: AppDependencies
    private let highlightsService: QuranHighlightsService

    private static func readingDirectory(_ reading: Reading, container: AppDependencies) -> URL {
        let remoteResource = container.remoteResources?.resource(for: reading)
        let remotePath = remoteResource?.downloadDestination.url
        let bundlePath = { Bundle.main.url(forResource: reading.localPath, withExtension: nil) }
        logger.info("Images: Use \(remoteResource != nil ? "remote" : "bundle") For reading \(reading)")
        return remotePath ?? bundlePath()!
    }
}

private extension Reading {
    func ayahInfoDatabase(in directory: URL) -> URL {
        switch self {
        case .hafs_1405:
            return directory.appendingPathComponent("images_1920/databases/ayahinfo_1920.db")
        case .hafs_1421:
            return directory.appendingPathComponent("images_1120/databases/ayahinfo_1120.db")
        case .hafs_1440:
            return directory.appendingPathComponent("images_1352/databases/ayahinfo_1352.db")
        case .tajweed:
            return directory.appendingPathComponent("images_1280/databases/ayahinfo_1280.db")
        }
    }

    func images(in directory: URL) -> URL {
        switch self {
        case .hafs_1405:
            return directory.appendingPathComponent("images_1920/width_1920")
        case .hafs_1421:
            return directory.appendingPathComponent("images_1120/width_1120")
        case .hafs_1440:
            return directory.appendingPathComponent("images_1352/width_1352")
        case .tajweed:
            return directory.appendingPathComponent("images_1280/width_1280")
        }
    }

    // TODO: Add cropInsets back
    var cropInsets: UIEdgeInsets {
        switch self {
        case .hafs_1405:
            return .zero // UIEdgeInsets(top: 10, left: 34, bottom: 40, right: 24)
        case .hafs_1421:
            return .zero
        case .hafs_1440:
            return .zero
        case .tajweed:
            return .zero
        }
    }
}
