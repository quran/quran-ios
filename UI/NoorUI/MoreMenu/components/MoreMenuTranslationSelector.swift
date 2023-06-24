//
//  MoreMenuTranslationSelector.swift
//
//
//  Created by Afifi, Mohamed on 9/6/21.
//

import Localization
import SwiftUI
import UIx

struct MoreMenuTranslationSelector: View {
    var body: some View {
        HStack {
            Text(l("menu.select_translation"))
            Spacer()
            Image(systemName: "chevron.right")
                .flipsForRightToLeftLayoutDirection(true)
        }
        .padding()
    }
}

struct MoreMenuTranslationSelector_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MoreMenuTranslationSelector()
        }
    }
}
