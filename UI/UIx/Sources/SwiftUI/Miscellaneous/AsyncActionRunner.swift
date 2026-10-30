//
//  AsyncActionRunner.swift
//
//

/// Runs an async control's action for each tap, applying an `AsyncTapPolicy` to taps made while one is running.
@MainActor
final class AsyncActionRunner {
    // MARK: Internal

    var isRunning: Bool { currentTask != nil }

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

    private var currentTask: Task<Void, Never>?
    private var runCount = 0

    private func finish(_ run: Int) {
        // A cancelled run that ends after its replacement started must not clear the replacement.
        if run == runCount {
            currentTask = nil
        }
    }
}
