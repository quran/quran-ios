//
//  HighlightingView.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/24/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

// This class is expected to be implemented using CoreAnimation with CAShapeLayers.
// It's also expected to reuse layers instead of dropping & creating new ones.
class HighlightingView: UIView {

    @IBInspectable var highlightColor: UIColor = UIColor.redColor()

    var highlightableAreas: [Rect] = []
}
