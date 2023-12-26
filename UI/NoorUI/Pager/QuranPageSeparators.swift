//
//  QuranPageSeparators.swift
//
//
//  Created by Mohamed Afifi on 2023-12-25.
//

import SwiftUI

public enum QuranSeparators {
    // MARK: Public

    public static let middleWidth: CGFloat = ContentDimension.interPageSpacing

    // MARK: Internal

    static let gradient = [Color(.pageSeparatorBackground), Color(.reading)]
    static let line = Color(.pageSeparatorLine)

    static let sideWidth: CGFloat = 10
}

extension QuranSeparators {
    public struct PageSideSeparator: View {
        // MARK: Lifecycle

        public init(leading: Bool) {
            self.leading = leading
        }

        // MARK: Public

        public var body: some View {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: directionalGradientColors),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: width)

                // Adding lines on top of the gradient
                ForEach(0 ..< lines, id: \.self) { i in
                    let step = width / CGFloat(lines - 1)
                    let distance = CGFloat(i) * step

                    Rectangle()
                        .fill(lineColor)
                        .frame(width: lineWidth)
                        .offset(x: distance - width / 2)
                }
            }
            .flipsForRightToLeftLayoutDirection(true)
        }

        // MARK: Internal

        let gradientColors = QuranSeparators.gradient
        let lineColor = QuranSeparators.line
        let lines: Int = 5
        let width: CGFloat = QuranSeparators.sideWidth
        let lineWidth: CGFloat = 0.5

        let leading: Bool

        var directionalGradientColors: [Color] {
            leading ? gradientColors : gradientColors.reversed()
        }
    }

    public struct PageMiddleSeparator: View {
        // MARK: Lifecycle

        public init() {
        }

        // MARK: Public

        public var body: some View {
            ZStack {
                HStack(spacing: 0) {
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                    .frame(width: width)

                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: width)
                }

                // Adding 1 line on top of the gradients
                Rectangle()
                    .fill(lineColor)
                    .frame(width: lineWidth)
            }
            .flipsForRightToLeftLayoutDirection(true)
        }

        // MARK: Internal

        let gradientColors = QuranSeparators.gradient
        let lineColor = QuranSeparators.line
        let width: CGFloat = QuranSeparators.middleWidth / 2
        let lineWidth: CGFloat = 0.7

        var directionalGradientColors: [Color] {
            gradientColors
        }
    }
}

struct QuranPageSeparators_Previews: PreviewProvider {
    struct QuranPageSeparatorsPreview: View {
        var body: some View {
            HStack {
                QuranSeparators.PageSideSeparator(leading: true)
                Spacer()
                QuranSeparators.PageMiddleSeparator()
                Spacer()
                QuranSeparators.PageSideSeparator(leading: false)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(Color(.reading))
            .ignoresSafeArea()
            .environment(\.layoutDirection, .rightToLeft)
        }
    }

    // MARK: Internal

    static var previews: some View {
        QuranPageSeparatorsPreview()
    }
}
