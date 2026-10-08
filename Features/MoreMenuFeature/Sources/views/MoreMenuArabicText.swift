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
        Toggle(lAndroid("prefs_ayah_before_translation_title"), isOn: $enabled)
            .padding()
    }
}

#Preview {
    MoreMenuArabicText(enabled: .constant(true))
}
