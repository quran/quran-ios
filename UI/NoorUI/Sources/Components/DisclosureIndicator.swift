//
//  DisclosureIndicator.swift
//
//
//  Created by Mohamed Afifi on 2023-06-25.
//

import SwiftUI

struct DisclosureIndicator: View {
    var body: some View {
        NoorSystemImage.disclosure.image
            .flipsForRightToLeftLayoutDirection(true)
            .foregroundColor(.secondaryLabel)
    }
}
