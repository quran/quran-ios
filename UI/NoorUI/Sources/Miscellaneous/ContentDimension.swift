//
//  ContentDimension.swift
//  Quran
//
//  Created by Afifi, Mohamed on 2/9/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import SwiftUI

public enum ContentDimension {
    // MARK: Public

    public static let interSpacing: CGFloat = spacing
    public static let interPageSpacing: CGFloat = 12

    public static func readableInsets(of safeAreaInsets: EdgeInsets) -> EdgeInsets {
        EdgeInsets(
            top: max(24, safeAreaInsets.top) + spacing,
            leading: safeAreaInsets.leading + spacing,
            bottom: safeAreaInsets.bottom + spacing,
            trailing: safeAreaInsets.trailing + spacing
        )
    }

    // MARK: Internal

    static let spacing: CGFloat = 8
}
