//
//  AdaptiveImageScrollView.swift
//
//
//  Created by Mohamed Afifi on 2024-02-17.
//

import QuranGeometry
import SwiftUI

/// `AdaptiveImageScrollView` adjusts an image to fill the available space and enables scrolling
/// when the view's width is greater than its height. In contrast, it fits the image within the view
/// without scrolling when the view's height is greater than its width.
public struct AdaptiveImageScrollView<Header: View, Footer: View>: View {
    // MARK: Lifecycle

    public init(
        decorations: ImageDecorations,
        image: () -> UIImage?,
        onScaleChange: @escaping (WordFrameScale) -> Void,
        onGlobalFrameChange: @escaping (CGRect) -> Void,
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer
    ) {
        self.decorations = decorations
        self.image = image()
        self.header = header()
        self.footer = footer()
        self.onScaleChange = onScaleChange
        self.onGlobalFrameChange = onGlobalFrameChange
    }

    // MARK: Public

    public var body: some View {
        GeometryReader { geometry in
            scrollView {
                VStack(spacing: 0) {
                    header
                        .onSizeChange { headerSize = $0 }

                    Group {
                        if let image {
                            QuranThemedImage(image: image)
                                .background(
                                    ImageDecorationsView(
                                        imageSize: image.size,
                                        decorations: decorations,
                                        onScaleChange: onScaleChange,
                                        onGlobalFrameChange: onGlobalFrameChange
                                    )
                                )
                        } else {
                            Color.clear
                        }
                    }
                    .readableInsetsPadding(.horizontal)
                    .frame(height: imageHeight(geometry: geometry))

                    footer
                        .onSizeChange { footerSize = $0 }
                }
            }
        }
        .onReadableInsetsChange { readableInsets = $0 }
    }

    // MARK: Private

    @State private var headerSize: CGSize = .zero
    @State private var footerSize: CGSize = .zero
    @State private var readableInsets: EdgeInsets = .zero

    private let header: Header
    private let footer: Footer
    private let image: UIImage?
    private let decorations: ImageDecorations
    private let onScaleChange: (WordFrameScale) -> Void
    private let onGlobalFrameChange: (CGRect) -> Void

    @ViewBuilder
    private func scrollView(@ViewBuilder content: () -> some View) -> some View {
        if #available(iOS 16.4, *) {
            ScrollView(content: content)
                .scrollBounceBehavior(.basedOnSize)
        } else {
            ScrollView(content: content)
        }
    }

    private func imageGeometrySize(from geometry: GeometryProxy) -> CGSize {
        CGSize(
            width: geometry.size.width - readableInsets.leading - readableInsets.trailing,
            height: geometry.size.height - headerSize.height - footerSize.height
        )
    }

    private func imageHeight(geometry: GeometryProxy) -> CGFloat {
        let imageGeometry = imageGeometrySize(from: geometry)
        if let imageSize = image?.size, imageGeometry.width > imageGeometry.height {
            return imageGeometry.width * (imageSize.height / imageSize.width)
        } else {
            return imageGeometry.height
        }
    }
}
