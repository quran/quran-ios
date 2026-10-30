//
//  AsyncAction.swift
//
//
//  Created by Mohamed Afifi on 2023-06-22.
//

import SwiftUI

public typealias Action = @MainActor @Sendable () -> Void
public typealias AsyncAction = @MainActor @Sendable () async -> Void

public typealias ItemAction<Item> = @MainActor @Sendable (Item) -> Void
public typealias AsyncItemAction<Item> = @MainActor @Sendable (Item) async -> Void
public typealias ItemDeletionAction<Item> = @MainActor @Sendable (Item) -> AsyncAction?

/// What a tap on an async control does while the action started by an earlier tap is still running.
public enum AsyncTapPolicy: Sendable {
    /// Cancels the running action and starts a new one.
    case cancelPrevious
    /// Ignores the tap and lets the running action finish.
    case ignoreWhileRunning
}

public struct AsyncButton<Label: View>: View {
    // MARK: Lifecycle

    /// `tapPolicy` says what a tap does while an earlier tap's action is still running.
    public init(
        tapPolicy: AsyncTapPolicy = .cancelPrevious,
        action: @escaping AsyncAction,
        @ViewBuilder label: () -> Label
    ) {
        let label = label()
        self.init(tapPolicy: tapPolicy, action: action) { _ in label }
    }

    /// `label` receives whether the action is running, so it can show progress while it runs.
    ///
    /// With `.ignoreWhileRunning`, the button is also disabled while the action runs, since it ignores taps.
    public init(
        tapPolicy: AsyncTapPolicy = .cancelPrevious,
        action: @escaping AsyncAction,
        @ViewBuilder label: @escaping (_ isRunning: Bool) -> Label
    ) {
        self.tapPolicy = tapPolicy
        self.action = action
        self.label = label
    }

    // MARK: Public

    public var body: some View {
        Button {
            runner.run(tapPolicy, action: action)
        } label: {
            label(runner.isRunning)
        }
        .disabled(tapPolicy == .ignoreWhileRunning && runner.isRunning)
    }

    // MARK: Private

    private let tapPolicy: AsyncTapPolicy
    private let action: AsyncAction
    private let label: (_ isRunning: Bool) -> Label

    @StateObject private var runner = AsyncActionRunner()
}

extension View {
    public func onAsyncTapGesture(count: Int = 1, asyncAction action: @escaping AsyncAction) -> some View {
        modifier(AsyncTapGestureModifier(count: count, action: action))
    }
}

private struct AsyncTapGestureModifier: ViewModifier {
    // MARK: Internal

    let count: Int
    let action: AsyncAction

    func body(content: Content) -> some View {
        content.onTapGesture(count: count, perform: {
            runner.run(.cancelPrevious, action: action)
        })
    }

    // MARK: Private

    // Deliberately not `@StateObject`: nothing here observes `isRunning`, so it needs no redraws.
    @State private var runner = AsyncActionRunner()
}
