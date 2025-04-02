//
//  QuranVerseSeparator.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import SwiftUI

public struct QuranVerseSeparator: View {
    public init() { }

    public var body: some View {
        Spacer()
            .frame(height: 1)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .themedSecondaryBackground()
            .padding(.top, ContentDimension.interSpacing)
    }
}

#Preview {
    VStack {
        QuranVerseSeparator()
    }
    .environment(\.themeStyle, .original)
}
