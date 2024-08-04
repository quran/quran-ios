//
//  QuranScrollingViewModifier.swift
//
//
//  Created by Mohamed Afifi on 2024-08-03.
//

import SwiftUI

struct QuranScrollingViewModifier<Value: Equatable, ID: Hashable>: ViewModifier {
    let scrollToValue: Value?
    let transform: (Value) -> ID?
    @State private var scrollToValueRequest: Value?

    func body(content: Content) -> some View {
        ScrollViewReader { scrollView in
            content
                .onChange(of: scrollToValue) { scrollToValueRequest = $0 }
                .onChange(of: scrollToValueRequest) { scrollToValue in
                    if let scrollToValue, let id = transform(scrollToValue) {
                        withAnimation {
                            scrollView.scrollTo(id, anchor: UnitPoint(x: 0, y: 0.2))
                        }
                        scrollToValueRequest = nil
                    }
                }
        }
        .onSizeChange { _ in
            scrollToValueRequest = scrollToValue
        }
    }
}

extension View {
    public func quranScrolling<Value: Equatable>(
        scrollToValue: Value?,
        transform: @escaping (Value) -> (some Hashable)?
    ) -> some View {
        modifier(QuranScrollingViewModifier(scrollToValue: scrollToValue, transform: transform))
    }

    public func quranScrolling(scrollToValue: (some Hashable)?) -> some View {
        modifier(QuranScrollingViewModifier(scrollToValue: scrollToValue) { $0 })
    }
}
