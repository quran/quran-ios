//
//  ReadingBookmarkPin.swift
//

import SwiftUI

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
    @ScaledMetric private var lineWidth = 1.8
    @ScaledMetric private var size = 24.0
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
