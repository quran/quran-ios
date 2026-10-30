//
//  QuranScrollingViewModifier.swift
//
//
//  Created by Mohamed Afifi on 2024-08-03.
//

import SwiftUI
import UIKit

@MainActor
final class QuranScrollScheduler<ID: Hashable>: ObservableObject {
    // MARK: Internal

    /// The latest target resolved against the rendered content.
    private(set) var target: ID?

    func schedule(_ action: @escaping @MainActor () -> Void) {
        task?.cancel()
        task = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }
            action()
        }
    }

    /// Records `target` and scrolls to it after a yield, or cancels pending work when there is no target.
    func scroll(to target: ID?, action: @escaping @MainActor (ID) -> Void) {
        self.target = target
        guard let target else {
            cancel()
            return
        }
        schedule {
            action(target)
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    // MARK: Private

    private var task: Task<Void, Never>?
}

@MainActor
struct QuranScrollingViewModifier<Value: Equatable, ID: Hashable>: ViewModifier {
    let scrollToValue: Value?
    let anchor: UnitPoint
    let transform: (Value) -> ID?
    @StateObject private var scheduler = QuranScrollScheduler<ID>()

    func body(content: Content) -> some View {
        // Resolve the target here, against this update's content. The legacy `onChange` action still
        // carries the previous update's captures, so a transform evaluated there sees stale content.
        let target = scrollToValue.flatMap(transform)
        ScrollViewReader { scrollView in
            content
                .onAppear {
                    scroll(to: target, using: scrollView)
                }
                .onChange(of: target) {
                    scroll(to: $0, using: scrollView)
                }
                .onSizeChange { _ in
                    scroll(to: scheduler.target, using: scrollView)
                }
                .onDisappear {
                    scheduler.cancel()
                }
        }
    }

    private func scroll(to target: ID?, using scrollView: ScrollViewProxy) {
        scheduler.scroll(to: target) { id in
            // Respect animation suppression by the UIKit host.
            withAnimation(UIView.areAnimationsEnabled ? NoorAnimation.standard : nil) {
                scrollView.scrollTo(id, anchor: anchor)
            }
        }
    }
}

extension View {
    public func quranScrolling<Value: Equatable>(
        scrollToValue: Value?,
        anchor: UnitPoint = UnitPoint(x: 0, y: 0.2),
        transform: @escaping (Value) -> (some Hashable)?
    ) -> some View {
        modifier(QuranScrollingViewModifier(scrollToValue: scrollToValue, anchor: anchor, transform: transform))
    }

    public func quranScrolling(
        scrollToValue: (some Hashable)?,
        anchor: UnitPoint = UnitPoint(x: 0, y: 0.2)
    ) -> some View {
        modifier(QuranScrollingViewModifier(scrollToValue: scrollToValue, anchor: anchor) { $0 })
    }
}
