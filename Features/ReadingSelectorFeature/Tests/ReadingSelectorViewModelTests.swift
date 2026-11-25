//
//  ReadingSelectorViewModelTests.swift
//
//
//  Created by Mohamed Afifi on 2026-11-17.
//

import BatchDownloaderFake
import QuranKit
import ReadingService
import SystemDependenciesFake
import XCTest
@testable import ReadingSelectorFeature

@MainActor
final class ReadingSelectorViewModelTests: XCTestCase {
    func test_readingGroups_listOnlyLoadableReadings_beforeStart() async {
        // Regression: until start() loaded the available readings, the selector listed every reading,
        // and picking one the app can't load crashed the reader.
        let context = BatchDownloaderFake.makeContext()
        let (downloader, _) = await context.makeDownloader(fileManager: FileSystemFake())
        let resources = ReadingResourcesService(
            fileManager: FileSystemFake(),
            downloader: downloader,
            remoteResources: nil,
            bundledReadings: [.hafs_1405]
        )

        let viewModel = ReadingSelectorViewModel(resources: resources)

        let listedReadings = viewModel.readingGroups.flatMap(\.readings).map(\.value)
        XCTAssertEqual(listedReadings, [.hafs_1405])
    }
}
