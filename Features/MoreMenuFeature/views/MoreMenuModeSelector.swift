//
//  MoreMenuModeSelector.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import Localization
import QuranText
import SwiftUI

struct MoreMenuModeSelector: View {
    @Binding var mode: QuranMode

    var body: some View {
        Picker(selection: $mode, label: Text("")) {
            Text(l("menu.arabic"))
                .tag(QuranMode.arabic)
            Text(l("menu.translation"))
                .tag(QuranMode.translation)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.bottom, 1)
    }
}

struct MoreMenuModeSelector_Previews: PreviewProvider {
    struct Container: View {
        @State var mode: QuranMode

        var body: some View {
            MoreMenuModeSelector(mode: $mode)
        }
    }

    // MARK: Internal

    static var previews: some View {
        VStack(spacing: 0) {
            Container(mode: .arabic)
            Divider()
            Container(mode: .translation)
        }
    }
}
