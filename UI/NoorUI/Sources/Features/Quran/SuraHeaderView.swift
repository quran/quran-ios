//
//  SuraHeaderView.swift
//

import SwiftUI

public struct SuraHeaderView: View {
    private let tint: Color

    public init(tint: Color) {
        self.tint = tint
    }

    public var body: some View {
        NoorImage.suraHeader.image
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(tint)
    }
}

#Preview {
    SuraHeaderView(tint: QuranPageChromeStyle.green.palette(for: .light).header)
        .frame(height: 40)
        .padding()
        .themedBackground()
        .environment(\.themeStyle, .paper)
}
