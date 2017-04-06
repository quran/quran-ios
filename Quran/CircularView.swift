//
//  CircularView.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/2/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class CircularView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = circularRadius
    }
}
