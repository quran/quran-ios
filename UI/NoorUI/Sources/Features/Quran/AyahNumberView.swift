//
//  AyahNumberView.swift
//

import Localization
import QuranKit
import SwiftUI

public struct AyahNumberView: View {
    private let number: Int
    private let ringColor: Color
    private let fillColor: Color?
    private let textColor: Color?

    public init(
        number: Int,
        ringColor: Color = .pageMarkerTint,
        fillColor: Color? = nil,
        textColor: Color? = nil
    ) {
        self.number = number
        self.ringColor = ringColor
        self.fillColor = fillColor
        self.textColor = textColor
    }

    public var body: some View {
        ZStack {
            if let fillColor, textColor != nil {
                Circle()
                    .fill(fillColor)
                    .padding(5)
            }

            ayahRing
                .foregroundColor(ringColor)

            ayahText
                .foregroundColor(markerTextColor)
        }
        .themedColorScheme()
    }

    private var ayahRing: some View {
        NoorImage.ayahEnd.image
            .renderingMode(.template)
            .resizable()
            .padding(.horizontal, 1)
            .aspectRatio(contentMode: .fit)
    }

    private var ayahText: some View {
        Text(NumberFormatter.arabicNumberFormatter.format(number))
            .font(.largeTitle)
            .minimumScaleFactor(0.03)
            .padding(3)
    }

    private var markerTextColor: Color {
        if fillColor != nil, let textColor {
            return textColor
        }
        return ringColor
    }
}

#Preview {
    List {
        AyahNumberView(number: 1)
            .frame(height: 40)
        AyahNumberView(number: 2)
            .frame(height: 40)

        AyahNumberView(number: 100)
            .frame(height: 40)

        AyahNumberView(number: 999)
            .frame(height: 40)

        #if QURAN_SYNC
        let ayah = Quran.hafsMadani1405.suras[1].verses[99]
        AyahNumberView(number: 100)
            .frame(height: 40)
            .overlay {
                GeometryReader { geometry in
                    AyahAnnotationsView(
                        markers: [.init(ayah: ayah, frame: CGRect(origin: .zero, size: geometry.size))],
                        annotations: [ayah: [.collection, .note]],
                        onAnnotatedAyahTap: { _, _ in }
                    )
                }
            }
        #endif
    }
    .themedBackground()
    .environment(\.themeStyle, .paper)
}
