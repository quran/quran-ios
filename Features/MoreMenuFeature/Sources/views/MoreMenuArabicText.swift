//
//  MoreMenuArabicText.swift
//
//
//  Created by Mohamed Afifi on 2026-10-08.
//

import Localization
import SwiftUI

struct MoreMenuArabicText: View {
    @Binding var enabled: Bool

    var body: some View {
        Toggle(l("menu.arabicText"), isOn: $enabled)
            .padding()
    }
}

#Preview {
    MoreMenuArabicText(enabled: .constant(true))
}
