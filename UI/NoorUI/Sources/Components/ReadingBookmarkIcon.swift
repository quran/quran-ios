//
//  ReadingBookmarkIcon.swift
//

import SwiftUI
import UIKit

public struct ReadingBookmarkIcon: View {
    // MARK: Lifecycle

    public init(style: Style) {
        self.style = style
    }

    // MARK: Public

    public enum Style {
        case outline
        case filled
    }

    public enum Badge {
        case ellipsis
    }

    public static func image(style: Style, badge: Badge? = nil) -> UIImage {
        let size = CGSize(width: defaultSize, height: defaultSize)
        let bounds = CGRect(origin: .zero, size: size)
        let iconBounds = badge == nil
            ? bounds
            : bounds.offsetBy(dx: -2, dy: -1)
        let configuration = UIImage.SymbolConfiguration(pointSize: defaultSymbolPointSize)
        let symbol = UIImage(systemName: style.systemImage.rawValue, withConfiguration: configuration)?
            .withTintColor(.black, renderingMode: .alwaysOriginal)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            if let symbol {
                symbol.draw(in: CGRect(
                    x: iconBounds.midX - symbol.size.width / 2,
                    y: iconBounds.midY - symbol.size.height / 2,
                    width: symbol.size.width,
                    height: symbol.size.height
                ))
            }

            switch badge {
            case .ellipsis:
                drawEllipsisBadge(in: context.cgContext)
            case nil:
                break
            }
        }
        return image.withRenderingMode(.alwaysTemplate)
    }

    public var body: some View {
        style.systemImage.image
            .font(.system(size: symbolPointSize))
            .frame(width: size, height: size)
    }

    // MARK: Private

    private let style: Style
    private static let defaultSymbolPointSize: CGFloat = 17
    private static let defaultSize: CGFloat = 24
    private static let badgeBounds = CGRect(x: 13, y: 13, width: 11, height: 11)
    @ScaledMetric private var symbolPointSize = defaultSymbolPointSize
    @ScaledMetric private var size = defaultSize

    private static func drawEllipsisBadge(in context: CGContext) {
        context.saveGState()
        context.setBlendMode(.clear)
        context.fillEllipse(in: badgeBounds.insetBy(dx: -1, dy: -1))
        context.restoreGState()

        context.saveGState()
        context.setFillColor(UIColor.black.cgColor)
        context.fillEllipse(in: badgeBounds)
        context.setBlendMode(.clear)
        for centerX in [16.25, 18.5, 20.75] {
            context.fillEllipse(in: CGRect(x: centerX - 0.7, y: 17.8, width: 1.4, height: 1.4))
        }
        context.restoreGState()
    }
}

extension ReadingBookmarkIcon.Style {
    fileprivate var systemImage: NoorSystemImage {
        switch self {
        case .outline: .bookmarkOutline
        case .filled: .bookmark
        }
    }
}

#Preview {
    HStack {
        ReadingBookmarkIcon(style: .outline)
        ReadingBookmarkIcon(style: .filled)
            .foregroundColor(.accentColor)
        Image(uiImage: ReadingBookmarkIcon.image(style: .outline, badge: .ellipsis))
    }
}
