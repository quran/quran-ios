//
//  MoreMenuVerticalScrolling.swift
//
//
//  Created by Mohamed Afifi on 2022-10-08.
//

import Localization
import SwiftUI
import UIx

struct MoreMenuVerticalScrolling: View {
    @Binding var enabled: Bool

    var body: some View {
        Toggle(l("menu.verticalScrolling"), isOn: $enabled)
            .padding()
    }
}
