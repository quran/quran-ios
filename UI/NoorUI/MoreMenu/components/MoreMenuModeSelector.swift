//
//  MoreMenuModeSelector.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import Localization
import SwiftUI
import UIx

struct MoreMenuModeSelector: View {
    @Binding var mode: MoreMenu.Mode

    var body: some View {
        Picker(selection: $mode, label: Text("")) {
            Text(l("menu.arabic"))
                .tag(MoreMenu.Mode.arabic)
            Text(l("menu.translation"))
                .tag(MoreMenu.Mode.translation)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.bottom, 1)
    }
}

struct MoreMenuModeSelector_Previews: PreviewProvider {
    struct Container: View {
        @State var mode: MoreMenu.Mode

        var body: some View {
            MoreMenuModeSelector(mode: $mode)
        }
    }

    // MARK: Internal

    static var previews: some View {
        Previewing.screen {
            VStack(spacing: 0) {
                Container(mode: .arabic)
                Divider()
                Container(mode: .translation)
            }
        }
        .previewLayout(.fixed(width: 320, height: 100))
    }
}
