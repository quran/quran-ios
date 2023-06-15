//
//  ContentDimension.swift
//  Quran
//
//  Created by Afifi, Mohamed on 2/9/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import UIKit

public enum ContentDimension {
    static let spacing: CGFloat = 8

    public static let interSpacing: CGFloat = 8

    public static let interPageSpacing: CGFloat = 10

    public static func insets(of view: UIView) -> NSDirectionalEdgeInsets {
        let readableInsets = view.window?.safeAreaInsets ?? .zero
        let topInset = max(24, readableInsets.top)
        return NSDirectionalEdgeInsets(top: topInset + spacing,
                                       leading: readableInsets.left + spacing,
                                       bottom: readableInsets.bottom + spacing,
                                       trailing: readableInsets.right + spacing)
    }
}
