//
//  MoreMenuFootnotes.swift
//
//
//  Created by Mohamed Afifi on 2026-11-16.
//

import Localization
import SwiftUI

struct MoreMenuFootnotes: View {
    @Binding var enabled: Bool

    var body: some View {
        Toggle(l("menu.footnotes"), isOn: $enabled)
            .padding()
    }
}

#Preview {
    MoreMenuFootnotes(enabled: .constant(true))
}
