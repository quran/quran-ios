//
//  SegmentedControl+Extension.swift
//  Quran
//
//  Created by Afifi, Mohamed on 7/19/21.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import UIKit

extension UISegmentedControl {
    public func addAttributes(_ attributes: [NSAttributedString.Key: Any], for state: UIControl.State) {
        let originalAttributes = titleTextAttributes(for: state) ?? [:]
        let allAttributes = attributes.reduce(into: originalAttributes) { $0[$1.key] = $1.value }
        setTitleTextAttributes(allAttributes, for: state)
    }
}
