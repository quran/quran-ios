//
//  AsyncActionRunnerTests.swift
//
//

import Combine
import XCTest
@testable import UIx

@MainActor
final class AsyncActionRunnerTests: XCTestCase {
    func test_ignoreWhileRunning_repeatedTapNeitherCancelsNorStartsAnotherAction() async {
        let runner = AsyncActionRunner()
        let first = BlockingAction()
        let firstTask = runner.run(.ignoreWhileRunning, action: { await first.run() })

        let secondTask = runner.run(.ignoreWhileRunning, action: { await first.run() })

        XCTAssertNil(secondTask)
        XCTAssertTrue(runner.isRunning)
        first.finish()
        await firstTask?.value
        XCTAssertEqual(first.starts, 1)
        XCTAssertEqual(first.cancellations, 0)
        XCTAssertFalse(runner.isRunning)
    }

    func test_ignoreWhileRunning_tapAfterActionFinishedStartsANewAction() async {
        let runner = AsyncActionRunner()
        let action = BlockingAction()
        action.finish()
        await runner.run(.ignoreWhileRunning, action: { await action.run() })?.value

        let secondTask = runner.run(.ignoreWhileRunning, action: { await action.run() })

        XCTAssertNotNil(secondTask)
        await secondTask?.value
        XCTAssertEqual(action.starts, 2)
    }

    func test_cancelPrevious_repeatedTapCancelsTheRunningAction() async {
        let runner = AsyncActionRunner()
        let first = BlockingAction()
        let second = BlockingAction()
        second.finish()
        let firstTask = runner.run(.cancelPrevious, action: { await first.run() })

        let secondTask = runner.run(.cancelPrevious, action: { await second.run() })

        await firstTask?.value
        await secondTask?.value
        XCTAssertEqual(first.cancellations, 1)
        XCTAssertEqual(second.starts, 1)
        XCTAssertEqual(second.cancellations, 0)
        XCTAssertFalse(runner.isRunning)
    }

    func test_cancelPrevious_cancelledActionEndingLateKeepsItsReplacementRunning() async {
        let runner = AsyncActionRunner()
        var states: [Bool] = []
        let cancellable = runner.$isRunning.sink { states.append($0) }
        let first = BlockingAction()
        let second = BlockingAction()
        let firstTask = runner.run(.cancelPrevious, action: { await first.run() })
        let secondTask = runner.run(.cancelPrevious, action: { await second.run() })

        await firstTask?.value

        XCTAssertTrue(runner.isRunning)
        XCTAssertEqual(states, [false, true])
        runner.run(.cancelPrevious, action: {})
        second.finish()
        await secondTask?.value
        XCTAssertEqual(second.cancellations, 1)
        cancellable.cancel()
    }

    func test_isRunning_publishesTrueWhileTheActionRunsAndFalseAfterItFinishes() async {
        let runner = AsyncActionRunner()
        var states: [Bool] = []
        let cancellable = runner.$isRunning.sink { states.append($0) }
        let action = BlockingAction()

        let task = runner.run(.ignoreWhileRunning, action: { await action.run() })

        XCTAssertTrue(runner.isRunning)
        action.finish()
        await task?.value
        XCTAssertFalse(runner.isRunning)
        XCTAssertEqual(states, [false, true, false])
        cancellable.cancel()
    }

    func test_isRunning_ignoredTapPublishesNothing() async {
        let runner = AsyncActionRunner()
        var states: [Bool] = []
        let cancellable = runner.$isRunning.sink { states.append($0) }
        let action = BlockingAction()
        let task = runner.run(.ignoreWhileRunning, action: { await action.run() })

        runner.run(.ignoreWhileRunning, action: {})

        XCTAssertEqual(states, [false, true])
        action.finish()
        await task?.value
        cancellable.cancel()
    }
}

/// An action that runs until `finish()` or until its task is cancelled, recording both.
@MainActor
private final class BlockingAction {
    // MARK: Lifecycle

    init() {
        (stream, continuation) = AsyncStream<Void>.makeStream()
    }

    // MARK: Internal

    private(set) var starts = 0
    private(set) var cancellations = 0

    func run() async {
        starts += 1
        for await _ in stream {
            break
        }
        if Task.isCancelled {
            cancellations += 1
        }
    }

    func finish() {
        continuation.finish()
    }

    // MARK: Private

    private let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation
}
