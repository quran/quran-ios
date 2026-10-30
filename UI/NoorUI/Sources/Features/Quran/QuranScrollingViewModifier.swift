//
//  QuranScrollingViewModifier.swift
//
//
//  Created by Mohamed Afifi on 2024-08-03.
//

import SwiftUI
import UIKit
import UIx

@MainActor
final class QuranScrollScheduler: ObservableObject {
    private var task: Task<Void, Never>?

    func schedule(_ action: @escaping @MainActor () -> Void) {
        task?.cancel()
        task = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }
            action()
        }
    }

    func scheduleScroll<Value, ID>(
        to value: Value?,
        transform: @escaping @MainActor (Value) -> ID?,
        action: @escaping @MainActor (ID) -> Void
    ) {
        guard let value else {
            cancel()
            return
        }
        schedule {
            guard let id = transform(value) else { return }
            action(id)
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

@MainActor
struct QuranScrollingViewModifier<Value: Equatable, ID: Hashable>: ViewModifier {
    let scrollToValue: Value?
    let anchor: UnitPoint
    let onReaderScroll: () -> Void
    let transform: (Value) -> ID?
    @StateObject private var scheduler = QuranScrollScheduler()

    func body(content: Content) -> some View {
        ScrollViewReader { scrollView in
            content
                .onScrollDragBegan {
                    // The reader takes over; the owner clears `scrollToValue` so later appearances,
                    // size changes, and rotations don't pull them back to it.
                    scheduler.cancel()
                    onReaderScroll()
                }
                .onAppear {
                    scheduleScroll(to: scrollToValue, using: scrollView)
                }
                .onChange(of: scrollToValue) {
                    scheduleScroll(to: $0, using: scrollView)
                }
                .onSizeChange { _ in
                    scheduleScroll(to: scrollToValue, using: scrollView)
                }
                .onDisappear {
                    scheduler.cancel()
                }
        }
    }

    private func scheduleScroll(to value: Value?, using scrollView: ScrollViewProxy) {
        scheduler.scheduleScroll(to: value, transform: transform) { id in
            // Respect animation suppression by the UIKit host.
            withAnimation(UIView.areAnimationsEnabled ? NoorAnimation.standard : nil) {
                scrollView.scrollTo(id, anchor: anchor)
            }
        }
    }
}

extension View {
    /// Scrolls to `scrollToValue` when it changes, and keeps it in view on appearance and size changes.
    ///
    /// `onReaderScroll` runs when the reader starts dragging the content. Clear `scrollToValue` there,
    /// so the content stays where the reader put it and a later request for the same value scrolls again.
    public func quranScrolling<Value: Equatable>(
        scrollToValue: Value?,
        anchor: UnitPoint = UnitPoint(x: 0, y: 0.2),
        onReaderScroll: @escaping () -> Void,
        transform: @escaping (Value) -> (some Hashable)?
    ) -> some View {
        modifier(QuranScrollingViewModifier(
            scrollToValue: scrollToValue,
            anchor: anchor,
            onReaderScroll: onReaderScroll,
            transform: transform
        ))
    }

    public func quranScrolling(
        scrollToValue: (some Hashable)?,
        anchor: UnitPoint = UnitPoint(x: 0, y: 0.2),
        onReaderScroll: @escaping () -> Void
    ) -> some View {
        modifier(QuranScrollingViewModifier(
            scrollToValue: scrollToValue,
            anchor: anchor,
            onReaderScroll: onReaderScroll
        ) { $0 })
    }
}
