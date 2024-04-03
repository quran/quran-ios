//
//  ImageDecorationsView.swift
//
//
//  Created by Mohamed Afifi on 2024-04-02.
//

import QuranGeometry
import SwiftUI

// TODO: Remove
extension CGRect: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(origin.x)
        hasher.combine(origin.y)
        hasher.combine(size.width)
        hasher.combine(size.height)
    }
}

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

public enum ImageDecoration: Hashable {
    case color(Color, CGRect)
    case suraHeader(CGRect)
    case ayahNumber(Int, CGPoint)

    func rect(forImageSize imageSize: CGSize) -> CGRect {
        switch self {
        case .color(_, let rect):
            return rect
        case .suraHeader(let rect):
            return rect
        case .ayahNumber(_, let center):
            let length = 0.06 * imageSize.width
            return CGRect(
                x: center.x - length / 2,
                y: center.y - length / 2,
                width: length,
                height: length
            )
        }
    }

    @ViewBuilder var decorationView: some View {
        switch self {
        case .color(let color, _):
            color
        case .suraHeader:
            SuraHeaderView()
        case .ayahNumber(let number, _):
            AyahNumberView(number: number)
        }
    }
}

struct ImageDecorationsView: View {
    let imageSize: CGSize
    let decorations: [ImageDecoration]
    let onScaleChange: (WordFrameScale) -> Void
    let onGlobalFrameChange: (CGRect) -> Void

    private struct SizeInfo: Equatable {
        var imageSize: CGSize
        var viewSize: CGSize
    }

    @State private var sizeInfo: SizeInfo = SizeInfo(imageSize: .zero, viewSize: .zero)

    var scale: WordFrameScale {
        WordFrameScale.scaling(imageSize: sizeInfo.imageSize, into: sizeInfo.viewSize)
    }

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .topLeading) {
                ForEach(decorations, id: \.self) { decoration in
                    let scaledRectangle = decoration.rect(forImageSize: imageSize).scaled(by: scale)
                    decoration.decorationView
                        .offset(x: scaledRectangle.minX, y: scaledRectangle.minY)
                        .frame(width: scaledRectangle.width, height: scaledRectangle.height)
                }
            }
        }
        .onChangeWithInitial(of: imageSize) { sizeInfo.imageSize = $0 }
        .onSizeChange { sizeInfo.viewSize = $0 }
        .onChange(of: sizeInfo) { newSizeInfo in
            onScaleChange(.scaling(imageSize: newSizeInfo.imageSize, into: newSizeInfo.viewSize))
        }
        .onGlobalFrameChanged(onGlobalFrameChange)
    }
}

private struct SuraHeaderView: View {
    public var body: some View {
        NoorImage.suraHeader.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.pageMarkerTint)
    }
}

private struct AyahNumberView: View {
    let number: Int

    public var body: some View {
        NoorImage.ayahEnd.image
            .resizable()
            .padding(.horizontal, 1)
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.pageMarkerTint)
            .overlay(
                Text(NumberFormatter.arabicNumberFormatter.format(number))
                    .font(.largeTitle)
                    .minimumScaleFactor(0.03)
                    .padding(3)
            )
    }
}

#Preview {
    List {
        SuraHeaderView()
            .frame(height: 40)

        AyahNumberView(number: 1)
            .frame(height: 40)
        AyahNumberView(number: 2)
            .frame(height: 40)

        AyahNumberView(number: 100)
            .frame(height: 40)

        AyahNumberView(number: 999)
            .frame(height: 40)
    }
}
