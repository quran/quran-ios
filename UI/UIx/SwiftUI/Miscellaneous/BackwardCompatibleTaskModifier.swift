//
//  BackwardCompatibleTaskModifier.swift
//
//
//  Created by Mohamed Afifi on 2023-07-07.
//

import SwiftUI

public extension View {
    @available(iOS, obsoleted: 15.0, message: "SwiftUI.View.task is available on iOS 15.")
    @_disfavoredOverload
    @inlinable
    func task(
        priority: TaskPriority = .userInitiated,
        @_inheritActorContext _ action: @escaping @Sendable () async -> Void
    ) -> some View {
        modifier(BackwardCompatibleTaskModifier(priority: priority, action: action))
    }
}

public struct BackwardCompatibleTaskModifier: ViewModifier {
    // MARK: Lifecycle

    public init(
        priority: TaskPriority,
        action: @escaping @Sendable () async -> Void
    ) {
        self.priority = priority
        self.action = action
        task = nil
    }

    // MARK: Public

    public func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content.task(priority: priority, action)
        } else {
            content
                .onAppear {
                    task = Task {
                        await action()
                    }
                }
                .onDisappear {
                    task?.cancel()
                    task = nil
                }
        }
    }

    // MARK: Private

    private var priority: TaskPriority
    private var action: @Sendable () async -> Void
    @State private var task: Task<Void, Never>?
}
