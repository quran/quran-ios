//
//  ImageDecorationsView.swift
//

import SwiftUI
import UIx

struct ImageDecorationsView: View {
    let layout: ImageDecorationsLayout

    var body: some View {
        ZStack(alignment: .topLeading) {
            highlights
            suraHeaders
            ayahNumbers
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: Private

    private var highlights: some View {
        ForEach(layout.highlights) { placement in
            placement.color
                .placed(in: placement.frame)
        }
    }

    private var suraHeaders: some View {
        ForEach(layout.suraHeaders) { placement in
            SuraHeaderView()
                .placed(in: placement.frame)
        }
    }

    private var ayahNumbers: some View {
        ForEach(layout.drawnAyahMarkers, id: \.ayah) { placement in
            AyahNumberView(number: placement.ayah.ayah)
                .placed(in: placement.frame)
        }
    }
}
