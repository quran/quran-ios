//
//  QuranScrollingViewModifier.swift
//
//
//  Created by Mohamed Afifi on 2024-08-03.
//

import SwiftUI

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

    func cancel() {
        task?.cancel()
        task = nil
    }
}

@MainActor
struct QuranScrollingViewModifier<Value: Equatable, ID: Hashable>: ViewModifier {
    let scrollToValue: Value?
    let anchor: UnitPoint
    let transform: (Value) -> ID?
    @StateObject private var scheduler = QuranScrollScheduler()

    func body(content: Content) -> some View {
        ScrollViewReader { scrollView in
            content
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
        guard let value else { return }
        scheduler.schedule {
            guard let id = transform(value) else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
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
