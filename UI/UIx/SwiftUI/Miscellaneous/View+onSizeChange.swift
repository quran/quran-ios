//
//  View+onSizeChange.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import SwiftUI

extension View {
    public func onSizeChange(_ body: @escaping (CGSize) -> Void) -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        }
        .onPreferenceChange(SizePreferenceKey.self, perform: body)
    }

    public func onGlobalFrameChanged(_ body: @escaping (CGRect) -> Void) -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(key: GlobalFramePreferenceKey.self, value: geometry.frame(in: .global))
            }
        }
        .onPreferenceChange(GlobalFramePreferenceKey.self, perform: body)
    }

    public func onChangeWithInitial<V>(of value: V, perform: @escaping (_ newValue: V) -> Void) -> some View where V: Equatable {
        onAppear {
            perform(value)
        }
        .onChange(of: value, perform: perform)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

private struct GlobalFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {}
}
