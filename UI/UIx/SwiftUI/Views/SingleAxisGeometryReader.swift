//
//  SingleAxisGeometryReader.swift
//
//
//  Created by Mohamed Afifi on 2023-02-13.
//

import SwiftUI

// Author: https://www.wooji-juice.com/blog/stupid-swiftui-tricks-single-axis-geometry-reader.html

public struct SingleAxisGeometryReader<Content: View>: View {
    private struct SizeKey: PreferenceKey {
        static var defaultValue: CGFloat { 10 }
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }

    @State private var size: CGFloat = SizeKey.defaultValue

    private let axis: Axis
    private let alignment: Alignment
    private let content: (CGFloat) -> Content

    public init(
        axis: Axis = .horizontal,
        alignment: Alignment = .center,
        content: @escaping (CGFloat) -> Content
    ) {
        self.axis = axis
        self.alignment = alignment
        self.content = content
    }

    public var body: some View {
        content(size)
            .frame(
                maxWidth: axis == .horizontal ? .infinity : nil,
                maxHeight: axis == .vertical ? .infinity : nil,
                alignment: alignment
            )
            .background(GeometryReader { proxy in
                Color.clear.preference(key: SizeKey.self, value: axis == .horizontal ? proxy.size.width : proxy.size.height)
            })
            .onPreferenceChange(SizeKey.self) { size = $0 }
    }
}
