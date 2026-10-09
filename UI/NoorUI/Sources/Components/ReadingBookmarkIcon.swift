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
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let context = context.cgContext
            let iconBounds = badge == nil
                ? bounds
                : bounds.offsetBy(dx: -2, dy: -1)
            context.addPath(ReadingBookmarkShape().path(in: iconBounds).cgPath)
            context.setFillColor(UIColor.black.cgColor)
            context.setStrokeColor(UIColor.black.cgColor)

            switch style {
            case .outline:
                context.setLineWidth(defaultLineWidth)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                context.strokePath()
            case .filled:
                context.fillPath()
            }

            switch badge {
            case .ellipsis:
                drawEllipsisBadge(in: context)
            case nil:
                break
            }
        }
        return image.withRenderingMode(.alwaysTemplate)
    }

    public var body: some View {
        Group {
            switch style {
            case .outline:
                ReadingBookmarkShape()
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            case .filled:
                ReadingBookmarkShape()
                    .fill()
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: Private

    private let style: Style
    private static let defaultLineWidth: CGFloat = 1.8
    private static let defaultSize: CGFloat = 24
    private static let badgeBounds = CGRect(x: 13, y: 13, width: 11, height: 11)
    @ScaledMetric private var lineWidth = defaultLineWidth
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

private struct ReadingBookmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 24
        let scaleY = rect.height / 24
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scaleX, y: rect.minY + y * scaleY)
        }

        // A ribbon with rounded top corners and a notched tail.
        var path = Path()
        path.move(to: point(6, 5))
        path.addQuadCurve(to: point(8.5, 2.5), control: point(6, 2.5))
        path.addLine(to: point(15.5, 2.5))
        path.addQuadCurve(to: point(18, 5), control: point(18, 2.5))
        path.addLine(to: point(18, 20.4))
        path.addQuadCurve(to: point(16.9, 20.9), control: point(18, 21.6))
        path.addLine(to: point(12, 16.5))
        path.addLine(to: point(7.1, 20.9))
        path.addQuadCurve(to: point(6, 20.4), control: point(6, 21.6))
        path.closeSubpath()
        return path
    }
}

#Preview {
    HStack {
        ReadingBookmarkIcon(style: .outline)
        ReadingBookmarkIcon(style: .filled)
            .foregroundColor(.accentColor)
    }
}
