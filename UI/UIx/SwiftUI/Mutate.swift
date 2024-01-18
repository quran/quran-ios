//
//  Mutate.swift
//
//
//  Created by Mohamed Afifi on 2024-01-13.
//

import SwiftUI

extension View {
    func mutateSelf(_ body: (inout Self) -> Void) -> Self {
        var copy = self
        body(&copy)
        return copy
    }
}
