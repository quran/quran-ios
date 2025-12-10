//
//  AdaptiveImageScrollView.swift
//
//
//  Created by Mohamed Afifi on 2024-02-17.
//

import QuranGeometry
import SwiftUI

public struct ScrollingEnabledKey: EnvironmentKey {
    public static let defaultValue: Bool = true
}

public extension EnvironmentValues {
    var scrollingEnabled: Bool {
        get { self[ScrollingEnabledKey.self] }
        set { self[ScrollingEnabledKey.self] = newValue }
    }
}

/// `AdaptiveImageScrollView` adjusts an image to fill the available space and enables scrolling
/// when the view's width is greater than its height. In contrast, it fits the image within the view
/// without scrolling when the view's height is greater than its width.
public struct AdaptiveImageScrollView<Header: View, Footer: View>: View {
    @Environment(\.scrollingEnabled) private var envScrollingEnabled
    // MARK: Lifecycle

    public init(
        decorations: ImageDecorations,
        renderingMode: QuranThemedImage.RenderingMode = .tinted,
        image: () -> UIImage?,
        onScaleChange: @escaping (WordFrameScale) -> Void,
        onGlobalFrameChange: @escaping (CGRect) -> Void,
        scrollingEnabled: Bool = true,
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer
    ) {
        self.decorations = decorations
        self.image = image()
        self.renderingMode = renderingMode
        self.scrollingEnabledParameter = scrollingEnabled
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
                            QuranThemedImage(image: image, renderingMode: renderingMode)
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
    private let renderingMode: QuranThemedImage.RenderingMode
    private let decorations: ImageDecorations
    private let onScaleChange: (WordFrameScale) -> Void
    private let onGlobalFrameChange: (CGRect) -> Void

    private let scrollingEnabledParameter: Bool
    private var scrollingEnabled: Bool {
        scrollingEnabledParameter && envScrollingEnabled
    }

    @ViewBuilder
    private func scrollView(@ViewBuilder content: () -> some View) -> some View {
        if scrollingEnabled {
            if #available(iOS 16.4, *) {
                ScrollView(content: content)
                    .scrollBounceBehavior(.basedOnSize)
            } else {
                ScrollView(content: content)
            }
        } else {
            content()
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
        guard let imageSize = image?.size else {
             return imageGeometry.height
        }
        
        // If scrolling is enabled, we fit the image if it's taller than wide (portrait-ish)
        // or if we are forced to fit (not implemented here but implied by original logic).
        // Original logic: if imageGeometry.width > imageGeometry.height (landscape view), scale to fit width.
        // Actually the original logic was:
        // if imageGeometry.width > imageGeometry.height { return imageGeometry.width * Ratio }
        // else { return imageGeometry.height }
        
        if scrollingEnabled {
            if imageGeometry.width > imageGeometry.height {
                return imageGeometry.width * (imageSize.height / imageSize.width)
            } else {
                return imageGeometry.height
            }
        } else {
            // In vertical scrolling mode, we always want to fit width and expand height
            return imageGeometry.width * (imageSize.height / imageSize.width)
        }
    }
}
