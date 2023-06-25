//
//  AsyncTextLabelImplmentation.swift
//  QuranEngineApp
//
//  Created by Mohamed Afifi on 2023-06-24.
//

import NoorUI

extension FixedTextNode: AsyncTextLabel {
    public func sizeThatFits(min: CGSize, max: CGSize) -> CGSize {
        layoutThatFits(ASSizeRange(min: min, max: max)).size
    }
}
