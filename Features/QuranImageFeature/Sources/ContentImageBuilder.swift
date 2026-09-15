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

    public init(container: AppDependencies, overlayService: VerseOverlayService) {
        self.container = container
        self.overlayService = overlayService
    }

    // MARK: Public

    #if QURAN_SYNC
    @ViewBuilder
    public func build(
        at page: Page,
        onAnnotatedAyahTap: @escaping (AyahNumber, CGPoint) -> Void
    ) -> some View {
        let reading = ReadingPreferences.shared.reading
        if reading.usesLinePages {
            let linePageAssetService = Self.buildLinePageAssetService(reading: reading, container: container)
            let viewModel = ContentLineViewModel(
                reading: reading,
                page: page,
                linePageAssetService: linePageAssetService,
                overlayService: overlayService
            )
            ContentLineView(
                viewModel: viewModel,
                onAnnotatedAyahTap: onAnnotatedAyahTap
            )
        } else {
            let imageService = Self.buildImageDataService(reading: reading, container: container)
            let viewModel = ContentImageViewModel(
                reading: reading,
                page: page,
                imageDataService: imageService,
                overlayService: overlayService
            )
            ContentImageView(
                viewModel: viewModel,
                onAnnotatedAyahTap: onAnnotatedAyahTap
            )
        }
    }

    #else
    @ViewBuilder
    public func build(at page: Page) -> some View {
        let reading = ReadingPreferences.shared.reading
        if reading.usesLinePages {
            let linePageAssetService = Self.buildLinePageAssetService(reading: reading, container: container)
            let viewModel = ContentLineViewModel(
                reading: reading,
                page: page,
                linePageAssetService: linePageAssetService,
                overlayService: overlayService
            )
            ContentLineView(viewModel: viewModel)
        } else {
            let imageService = Self.buildImageDataService(reading: reading, container: container)
            let viewModel = ContentImageViewModel(
                reading: reading,
                page: page,
                imageDataService: imageService,
                overlayService: overlayService
            )
            ContentImageView(viewModel: viewModel)
        }
    }

    #endif

    // MARK: Internal

    static func buildImageDataService(reading: Reading, container: AppDependencies) -> ImageDataService {
        let readingDirectory = Self.readingDirectory(reading, container: container)
        return ImageDataService(
            ayahInfoDatabase: reading.ayahInfoDatabase(in: readingDirectory),
            imagesURL: reading.imagesDirectory(in: readingDirectory),
            ayahMarkerURL: container.remoteResources?.resource(for: reading)?.ayahMarkerURL
        )
    }

    static func buildLinePageAssetService(reading: Reading, container: AppDependencies) -> LinePageAssetService {
        guard let metrics = reading.linePageMetrics else {
            preconditionFailure("Attempted to build line-page assets for non-line-page reading \(reading)")
        }
        return LinePageAssetService(
            readingDirectory: Self.readingDirectory(reading, container: container),
            metrics: metrics,
            quran: reading.quran,
            ayahMarkerURL: container.remoteResources?.resource(for: reading)?.ayahMarkerURL
        )
    }

    static func readingDirectory(_ reading: Reading, container: AppDependencies) -> URL {
        let remoteResource = container.remoteResources?.resource(for: reading)
        let remotePath = remoteResource?.downloadDestination.url
        let bundlePath = { Bundle.main.url(forResource: reading.localPath, withExtension: nil) }
        logger.info("Images: Use \(remoteResource != nil ? "remote" : "bundle") For reading \(reading)")
        return remotePath ?? bundlePath()!
    }

    // MARK: Private

    private let container: AppDependencies
    private let overlayService: VerseOverlayService
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
        case .indoPak:
            return .zero
        }
    }
}
