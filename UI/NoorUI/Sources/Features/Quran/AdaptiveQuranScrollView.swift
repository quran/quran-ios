//
//  AdaptiveQuranScrollView.swift
//
//
//  Created by Mohamed Afifi on 2026-03-30.
//

import SwiftUI

/// `AdaptiveQuranScrollView` provides the shared Quran page shell with a header,
/// footer, readable insets, and a content area that adapts to the remaining space.
public struct AdaptiveQuranScrollView<Header: View, Footer: View, Content: View>: View {
    // MARK: Lifecycle

    public init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder content: @escaping (CGSize) -> Content
    ) {
        self.header = header()
        self.footer = footer()
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        let content = content
        let footer = footer
        let footerSize = $footerSize
        let header = header
        let headerSize = $headerSize
        let readableInsets = $readableInsets

        GeometryReader { geometry in
            let availableContentSize = Self.availableContentSize(
                from: geometry,
                readableInsets: readableInsets.wrappedValue,
                headerSize: headerSize.wrappedValue,
                footerSize: footerSize.wrappedValue
            )

            Self.scrollView {
                VStack(spacing: 0) {
                    header
                        .onSizeChange { headerSize.wrappedValue = $0 }

                    content(availableContentSize)
                        .readableInsetsPadding(.horizontal)

                    footer
                        .onSizeChange { footerSize.wrappedValue = $0 }
                }
            }
        }
        .onReadableInsetsChange { readableInsets.wrappedValue = $0 }
    }

    // MARK: Private

    @State private var headerSize: CGSize = .zero
    @State private var footerSize: CGSize = .zero
    @State private var readableInsets: EdgeInsets = .zero

    private let header: Header
    private let footer: Footer
    private let content: (CGSize) -> Content

    @ViewBuilder
    private static func scrollView(@ViewBuilder content: () -> some View) -> some View {
        if #available(iOS 16.4, *) {
            ScrollView(content: content)
                .scrollBounceBehavior(.basedOnSize)
        } else {
            ScrollView(content: content)
        }
    }

    private static func availableContentSize(
        from geometry: GeometryProxy,
        readableInsets: EdgeInsets,
        headerSize: CGSize,
        footerSize: CGSize
    ) -> CGSize {
        CGSize(
            width: max(0, geometry.size.width - readableInsets.leading - readableInsets.trailing),
            height: max(0, geometry.size.height - headerSize.height - footerSize.height)
        )
    }
}
