#if QURAN_SYNC
//
//  LegacyImportScanRunner.swift
//
//
//  Created by Mohamed Afifi on 2026-09-27.
//

/// Runs one scan at a time. Requests made during a scan share one follow-up scan.
actor LegacyImportScanRunner {
    // MARK: Lifecycle

    init(scan: @escaping @Sendable () async -> Result<Void, Error>) {
        self.scan = scan
    }

    // MARK: Internal

    /// Callers of ``scanNow()`` waiting for a result.
    var waiterCount: Int {
        waiters.count
    }

    /// Starts a scan, or queues one follow-up when a scan is running.
    func requestScan() {
        requestedScan += 1
        guard scanLoop == nil else {
            return
        }
        scanLoop = Task { await runScans() }
    }

    /// Returns the result of the running or queued scan, starting one when idle.
    func scanNow() async throws {
        try await withCheckedThrowingContinuation { continuation in
            if scanLoop == nil {
                requestScan()
            }
            waiters.append((requestedScan, continuation))
        }
    }

    /// Waits until no scan is running or queued.
    func waitForScans() async {
        await scanLoop?.value
    }

    // MARK: Private

    private typealias Waiter = (scan: Int, continuation: CheckedContinuation<Void, Error>)

    private let scan: @Sendable () async -> Result<Void, Error>
    private var scanLoop: Task<Void, Never>?
    private var requestedScan = 0
    private var waiters: [Waiter] = []

    private func runScans() async {
        var completedScan = 0
        while completedScan < requestedScan {
            completedScan = requestedScan
            let result = await scan()

            let finished = waiters.filter { $0.scan <= completedScan }
            waiters.removeAll { $0.scan <= completedScan }
            for waiter in finished {
                waiter.continuation.resume(with: result)
            }
        }
        scanLoop = nil
    }
}
#endif
