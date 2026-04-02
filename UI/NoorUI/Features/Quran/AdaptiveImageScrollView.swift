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
        renderingMode: QuranThemedImage.RenderingMode = .tinted,
        image: () -> UIImage?,
        onScaleChange: @escaping (WordFrameScale) -> Void,
        onGlobalFrameChange: @escaping (CGRect) -> Void,
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer
    ) {
        self.decorations = decorations
        self.image = image()
        self.renderingMode = renderingMode
        self.header = header()
        self.footer = footer()
        self.onScaleChange = onScaleChange
        self.onGlobalFrameChange = onGlobalFrameChange
    }

    // MARK: Public

    public var body: some View {
        AdaptiveQuranScrollView {
            header
        } footer: {
            footer
        } content: { availableContentSize in
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
            .frame(height: imageHeight(for: availableContentSize))
        }
    }

    // MARK: Private

    private let header: Header
    private let footer: Footer
    private let image: UIImage?
    private let renderingMode: QuranThemedImage.RenderingMode
    private let decorations: ImageDecorations
    private let onScaleChange: (WordFrameScale) -> Void
    private let onGlobalFrameChange: (CGRect) -> Void

    private func imageHeight(for availableContentSize: CGSize) -> CGFloat {
        if let imageSize = image?.size, availableContentSize.width > availableContentSize.height {
            return availableContentSize.width * (imageSize.height / imageSize.width)
        } else {
            return availableContentSize.height
        }
    }
}
