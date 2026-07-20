//
//  ReadingBookmarkPin.swift
//

import SwiftUI
import UIKit

public struct ReadingBookmarkPin: View {
    // MARK: Lifecycle

    public init(style: Style) {
        self.style = style
    }

    // MARK: Public

    public enum Style {
        case outline
        case filled
    }

    public static func image(style: Style) -> UIImage {
        let size = CGSize(width: defaultSize, height: defaultSize)
        let bounds = CGRect(origin: .zero, size: size)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let context = context.cgContext
            context.addPath(ReadingBookmarkPinShape().path(in: bounds).cgPath)
            context.setFillColor(UIColor.black.cgColor)
            context.setStrokeColor(UIColor.black.cgColor)

            switch style {
            case .outline:
                context.setLineWidth(defaultLineWidth)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                context.strokePath()
            case .filled:
                context.drawPath(using: .eoFill)
            }
        }
        return image.withRenderingMode(.alwaysTemplate)
    }

    public var body: some View {
        Group {
            switch style {
            case .outline:
                ReadingBookmarkPinShape()
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            case .filled:
                ReadingBookmarkPinShape()
                    .fill(style: FillStyle(eoFill: true))
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: Private

    private let style: Style
    private static let defaultLineWidth: CGFloat = 1.8
    private static let defaultSize: CGFloat = 24
    @ScaledMetric private var lineWidth = defaultLineWidth
    @ScaledMetric private var size = defaultSize
}

private struct ReadingBookmarkPinShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 24
        let scaleY = rect.height / 24
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scaleX, y: rect.minY + y * scaleY)
        }

        var path = Path()
        path.move(to: point(12, 2))
        path.addCurve(
            to: point(5, 9),
            control1: point(8.13, 2),
            control2: point(5, 5.13)
        )
        path.addCurve(
            to: point(12, 22),
            control1: point(5, 14.25),
            control2: point(12, 22)
        )
        path.addCurve(
            to: point(19, 9),
            control1: point(12, 22),
            control2: point(19, 14.25)
        )
        path.addCurve(
            to: point(12, 2),
            control1: point(19, 5.13),
            control2: point(15.87, 2)
        )
        path.closeSubpath()
        path.addEllipse(in: CGRect(
            x: rect.minX + 9.5 * scaleX,
            y: rect.minY + 6.5 * scaleY,
            width: 5 * scaleX,
            height: 5 * scaleY
        ))
        return path
    }
}

#Preview {
    HStack {
        ReadingBookmarkPin(style: .outline)
        ReadingBookmarkPin(style: .filled)
            .foregroundColor(.appIdentity)
    }
}
