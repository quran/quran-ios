//
//  EdgeInsets++.swift
//
//
//  Created by Mohamed Afifi on 2024-01-04.
//

import SwiftUI

extension EdgeInsets {
    public static var zero: Self {
        .init()
    }
}

extension EdgeInsets: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(leading)
        hasher.combine(trailing)
        hasher.combine(top)
        hasher.combine(bottom)
    }
}
