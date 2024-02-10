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
        Rectangle()
            .fill(Color.systemGray4)
            .frame(height: 1)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, ContentDimension.interSpacing)
    }
}
