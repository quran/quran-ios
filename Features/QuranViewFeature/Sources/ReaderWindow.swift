//
//  ReaderWindow.swift
//
//
//  Created by Mohamed Afifi on 2026-11-17.
//

import CoreGraphics

/// What the reader's window offers the More menu. iPhone Duo resizes the window when it folds or unfolds.
struct ReaderWindow: Equatable {
    let width: CGFloat
    let isRegularWidthAndHeight: Bool
    let isPhone: Bool
}
