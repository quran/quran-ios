//
//  ReadingResourcesServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2023-02-20.
//

@testable import QuranTextKit
import TestUtilities
import XCTest

final class ReadingResourcesServiceTests: XCTestCase {
    private var service: ReadingResourcesService!

    override func setUp() {
        ReadingPreferences.shared.reading = .hafs_1405
        OnDemandResource.requestInitializer = BundleResourceRequestFake.init
    }

    func testResourceAvailable() throws {
        BundleResourceRequestFake.resourceAvailable = true
        let service = ReadingResourcesService()

        let events = try awaitPublisher(service.publisher, numberOfElements: 1)

        XCTAssertEqual(events, [.ready])
    }

    func testResourceDownloading() throws {
        BundleResourceRequestFake.resourceAvailable = false
        BundleResourceRequestFake.downloadResult = .success(())
        let service = ReadingResourcesService()

        let events = try awaitPublisher(service.publisher, numberOfElements: 3)

        XCTAssertEqual(events, [.downloading(progress: 0),
                                .downloading(progress: 1),
                                .ready])
    }

    func testResourceDownloadFailure() throws {
        let error = URLError(.notConnectedToInternet)
        BundleResourceRequestFake.resourceAvailable = false
        BundleResourceRequestFake.downloadResult = .failure(error)
        let service = ReadingResourcesService()

        let events = try awaitPublisher(service.publisher, numberOfElements: 2)

        XCTAssertEqual(events, [.downloading(progress: 0),
                                .error(error as NSError)])
    }

    func testResourceSwitching() throws {
        BundleResourceRequestFake.resourceAvailable = true
        let service = ReadingResourcesService()

        let events = try awaitPublisher(service.publisher, numberOfElements: 1)
        XCTAssertEqual(events, [.ready])

        // Switch preference
        BundleResourceRequestFake.resourceAvailable = false
        BundleResourceRequestFake.downloadResult = .success(())
        ReadingPreferences.shared.reading = .hafs_1440

        let newEvents = try awaitPublisher(service.publisher, numberOfElements: 4)
        XCTAssertEqual(newEvents, [events.last,
                                   .downloading(progress: 0),
                                   .downloading(progress: 1),
                                   .ready])
    }
}

private class BundleResourceRequestFake: NSBundleResourceRequest {
    static var resourceAvailable: Bool = true
    static var downloadResult: Result<Void, Error>?

    override func conditionallyBeginAccessingResources(completionHandler: @escaping (Bool) -> Void) {
        DispatchQueue.global().async {
            completionHandler(Self.resourceAvailable)
        }
    }

    override func beginAccessingResources(completionHandler: @escaping (Error?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            switch Self.downloadResult! {
            case .success:
                self.progress.completedUnitCount = self.progress.totalUnitCount
                completionHandler(nil)
            case .failure(let error):
                completionHandler(error)
            }
        }
    }
}
