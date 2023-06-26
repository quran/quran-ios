//
//  DisclosureIndicator.swift
//
//
//  Created by Mohamed Afifi on 2023-06-25.
//

import SwiftUI

struct DisclosureIndicator: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .flipsForRightToLeftLayoutDirection(true)
            .foregroundColor(.secondaryLabel)
    }
}
