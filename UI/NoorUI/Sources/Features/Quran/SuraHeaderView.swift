//
//  SuraHeaderView.swift
//

import SwiftUI

public struct SuraHeaderView: View {
    private let tint: Color

    public init(tint: Color = .pageMarkerTint) {
        self.tint = tint
    }

    public var body: some View {
        NoorImage.suraHeader.image
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(tint)
            .themedColorScheme()
    }
}

#Preview {
    SuraHeaderView()
        .frame(height: 40)
        .padding()
        .themedBackground()
        .environment(\.themeStyle, .paper)
}
