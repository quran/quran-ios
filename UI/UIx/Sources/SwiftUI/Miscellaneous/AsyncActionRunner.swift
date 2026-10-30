//
//  AsyncActionRunner.swift
//
//

import Combine

/// Runs an async control's action for each tap, applying an `AsyncTapPolicy` to taps made while one is running.
@MainActor
final class AsyncActionRunner: ObservableObject {
    // MARK: Internal

    /// Whether an action is running, published so a control can show progress while it runs.
    @Published private(set) var isRunning = false

    /// Starts `action`, or returns nil when `policy` ignores the tap because an action is still running.
    @discardableResult
    func run(_ policy: AsyncTapPolicy, action: @escaping AsyncAction) -> Task<Void, Never>? {
        if let currentTask {
            switch policy {
            case .cancelPrevious:
                currentTask.cancel()
            case .ignoreWhileRunning:
                return nil
            }
        }

        runCount += 1
        let run = runCount
        let task = Task { [weak self] in
            await action()
            self?.finish(run)
        }
        currentTask = task
        return task
    }

    // MARK: Private

    private var runCount = 0

    private var currentTask: Task<Void, Never>? {
        didSet {
            // Publish only real changes, so replacing a running action doesn't redraw its control.
            let isRunning = currentTask != nil
            if self.isRunning != isRunning {
                self.isRunning = isRunning
            }
        }
    }

    private func finish(_ run: Int) {
        // A cancelled run that ends after its replacement started must not clear the replacement.
        if run == runCount {
            currentTask = nil
        }
    }
}
