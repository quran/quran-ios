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
import SwiftUI
import UIKit
import Utilities
import VLogging

@MainActor
public struct ContentImageBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies, highlightsService: QuranHighlightsService) {
        self.container = container
        self.highlightsService = highlightsService
    }

    // MARK: Public

    @ViewBuilder
    public func build(at page: Page) -> some View {
        let reading = ReadingPreferences.shared.reading
        if reading.usesLinePages {
            let linePageAssetService = Self.buildLinePageAssetService(reading: reading, container: container)
            let viewModel = ContentLineViewModel(
                reading: reading,
                page: page,
                linePageAssetService: linePageAssetService,
                highlightsService: highlightsService
            )
            ContentLineView(viewModel: viewModel)
        } else {
            let imageService = Self.buildImageDataService(reading: reading, container: container)
            let viewModel = ContentImageViewModel(
                reading: reading,
                page: page,
                imageDataService: imageService,
                highlightsService: highlightsService
            )
            ContentImageView(viewModel: viewModel)
        }
    }

    // MARK: Internal

    static func buildImageDataService(reading: Reading, container: AppDependencies) -> ImageDataService {
        let readingDirectory = Self.readingDirectory(reading, container: container)
        return ImageDataService(
            ayahInfoDatabase: reading.ayahInfoDatabase(in: readingDirectory),
            imagesURL: reading.imagesDirectory(in: readingDirectory)
        )
    }

    static func buildLinePageAssetService(reading: Reading, container: AppDependencies) -> LinePageAssetService {
        guard let widthParameter = reading.linePageAssetWidth else {
            preconditionFailure("Attempted to build line-page assets for non-line-page reading \(reading)")
        }
        return LinePageAssetService(
            readingDirectory: Self.readingDirectory(reading, container: container),
            widthParameter: widthParameter
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
    // TODO: Add cropInsets back
    var cropInsets: UIEdgeInsets {
        switch self {
        case .hafs_1405:
            return .zero // UIEdgeInsets(top: 10, left: 34, bottom: 40, right: 24)
        case .hafs_1421:
            return .zero
        case .hafs_1440:
            return .zero
        case .hafs_1439:
            return .zero
        case .hafs_1441:
            return .zero
        case .tajweed:
            return .zero
        }
    }
}
