//
//  MoreMenuFocusMode.swift
//

import Localization
import SwiftUI

struct MoreMenuFocusMode: View {
    @Binding var enabled: Bool

    var body: some View {
        Toggle(l("menu.focusMode"), isOn: $enabled)
            .padding()
    }
}

#Preview {
    MoreMenuFocusMode(enabled: .constant(true))
}
