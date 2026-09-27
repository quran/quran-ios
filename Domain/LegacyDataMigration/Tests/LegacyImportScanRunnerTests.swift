#if QURAN_SYNC
//
//  LegacyImportScanRunnerTests.swift
//
//
//  Created by Mohamed Afifi on 2026-09-27.
//

import AsyncAlgorithms
import AsyncUtilitiesForTesting
import XCTest
@testable import LegacyDataMigration

final class LegacyImportScanRunnerTests: XCTestCase {
    // MARK: Internal

    func test_requestsDuringAScan_shareOneFollowUpScan() async {
        let scans = ControlledScans()
        let runner = scans.runner()
        await runner.requestScan()
        await scans.started.next()

        await runner.requestScan()
        await runner.requestScan()
        await runner.requestScan()
        await scans.finish(.success(()))
        await scans.started.next()
        await scans.finish(.success(()))
        await runner.waitForScans()

        let finishedScans = await scans.log.entries
        XCTAssertEqual(finishedScans, ["scan 1", "scan 2"])
    }

    func test_scanNow_whenIdle_startsAScan() async throws {
        let scans = ControlledScans()
        let runner = scans.runner()

        let caller = Task { try await runner.scanNow() }
        await scans.started.next()
        await scans.finish(.success(()))

        try await caller.value
        let finishedScans = await scans.log.entries
        XCTAssertEqual(finishedScans, ["scan 1"])
    }

    func test_scanNow_joinsTheRunningScan() async throws {
        let scans = ControlledScans()
        let runner = scans.runner()
        await runner.requestScan()
        await scans.started.next()

        let caller = Task { try await runner.scanNow() }
        await waitForWaiters(1, in: runner)
        await scans.finish(.success(()))

        try await caller.value
        await runner.waitForScans()
        let finishedScans = await scans.log.entries
        XCTAssertEqual(finishedScans, ["scan 1"])
    }

    func test_scanNow_joinsTheQueuedScan_andReceivesItsResult() async {
        let scans = ControlledScans()
        let runner = scans.runner()
        await runner.requestScan()
        await scans.started.next()
        await runner.requestScan()

        let caller = Task { try await runner.scanNow() }
        await waitForWaiters(1, in: runner)
        await scans.finish(.success(()))
        await scans.started.next()
        await scans.finish(.failure(ScanFailure()))

        // The first scan succeeded; only the queued scan's failure reaches the caller.
        await AsyncAssertThrows(try await caller.value, nil)
        let finishedScans = await scans.log.entries
        XCTAssertEqual(finishedScans, ["scan 1", "scan 2"])
    }

    func test_failure_reachesOnlyTheCallersOfThatScan() async throws {
        let scans = ControlledScans()
        let runner = scans.runner()
        let first = Task { try await runner.scanNow() }
        await scans.started.next()
        await waitForWaiters(1, in: runner)

        await runner.requestScan()
        let second = Task { try await runner.scanNow() }
        await waitForWaiters(2, in: runner)
        await scans.finish(.failure(ScanFailure()))
        await scans.started.next()
        await scans.finish(.success(()))

        await AsyncAssertThrows(try await first.value, nil)
        try await second.value
    }

    func test_waitForScans_returnsAfterTheRunningScanFinishes() async {
        let scans = ControlledScans()
        let runner = scans.runner()
        await runner.requestScan()
        await scans.started.next()

        let waiting = Task {
            await runner.waitForScans()
            await scans.log.append("waited")
        }
        await scans.finish(.success(()))
        await waiting.value

        let entries = await scans.log.entries
        XCTAssertEqual(entries, ["scan 1", "waited"])
    }

    // MARK: Private

    private func waitForWaiters(_ count: Int, in runner: LegacyImportScanRunner) async {
        while await runner.waiterCount < count {
            await Task.yield()
        }
    }
}

/// Scans that report when they start and finish only when the test provides their result.
private final class ControlledScans: Sendable {
    // MARK: Internal

    let started = AsyncChannel<Void>()
    let log = Log()

    func runner() -> LegacyImportScanRunner {
        LegacyImportScanRunner { [self] in
            await started.send()
            let result = await results.next() ?? .success(())
            await log.appendScan()
            return result
        }
    }

    func finish(_ result: Result<Void, Error>) async {
        await results.send(result)
    }

    // MARK: Private

    private let results = AsyncChannel<Result<Void, Error>>()
}

private actor Log {
    private(set) var entries: [String] = []
    private var scans = 0

    func appendScan() {
        scans += 1
        entries.append("scan \(scans)")
    }

    func append(_ entry: String) {
        entries.append(entry)
    }
}

private struct ScanFailure: Error {}
#endif
