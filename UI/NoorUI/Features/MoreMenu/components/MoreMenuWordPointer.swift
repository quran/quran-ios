//
//  MoreMenuWordPointer.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import Localization
import SwiftUI
import UIx

struct MoreMenuWordPointer: View {
    @Binding var enabled: Bool

    var body: some View {
        Toggle(l("menu.pointer"), isOn: $enabled)
            .padding()
    }
}

struct MoreMenuWordPointer_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MoreMenuWordPointer(enabled: .constant(true))
            Divider()
            MoreMenuWordPointer(enabled: .constant(false))
        }
    }
}
