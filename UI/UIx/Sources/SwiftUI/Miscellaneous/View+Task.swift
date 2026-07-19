//
//  View+Task.swift
//
//
//  Created by Mohamed Afifi on 2024-09-27.
//

import SwiftUI

public struct TaskOnceModifier: ViewModifier {
    @State private var started = false
    private let priority: TaskPriority
    private let action: @Sendable () async -> Void

    public init(priority: TaskPriority, _ action: @escaping @Sendable () async -> Void) {
        self.priority = priority
        self.action = action
    }

    public func body(content: Content) -> some View {
        content
            .task(priority: priority) {
                guard !started else {
                    return
                }
                started = true
                await action()
            }
    }
}

extension View {
    @inlinable
    public func taskOnce(
        priority: TaskPriority = .userInitiated,
        _ action: @escaping @Sendable () async -> Void
    ) -> some View {
        modifier(TaskOnceModifier(priority: priority, action))
    }
}
