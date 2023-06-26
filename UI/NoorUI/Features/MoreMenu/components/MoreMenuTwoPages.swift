//
//  MoreMenuTwoPages.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import Localization
import SwiftUI
import UIx

struct MoreMenuTwoPages: View {
    @Binding var enabled: Bool

    var body: some View {
        Toggle(l("menu.twoPages"), isOn: $enabled)
            .padding()
    }
}
