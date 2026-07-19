//
//  AsyncAction.swift
//
//
//  Created by Mohamed Afifi on 2023-06-22.
//

import SwiftUI

public typealias AsyncAction = @MainActor @Sendable () async -> Void

public typealias ItemAction<Item> = @MainActor @Sendable (Item) -> Void
public typealias AsyncItemAction<Item> = @MainActor @Sendable (Item) async -> Void

public struct AsyncButton<Label: View>: View {
    // MARK: Lifecycle

    public init(action: @escaping AsyncAction, label: () -> Label) {
        self.action = action
        self.label = label()
    }

    // MARK: Public

    public var body: some View {
        Button {
            // Cancel the previous task
            currentTask?.cancel()

            // Start a new task
            currentTask = Task {
                await action()
            }
        } label: {
            label
        }
    }

    // MARK: Private

    private let action: AsyncAction
    private let label: Label

    @State private var currentTask: Task<Void, Never>? = nil
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
            // Cancel the previous task
            currentTask?.cancel()

            // Start a new task
            currentTask = Task {
                await action()
            }
        })
    }

    // MARK: Private

    @State private var currentTask: Task<Void, Never>? = nil
}
