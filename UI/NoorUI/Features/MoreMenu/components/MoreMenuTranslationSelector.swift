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
        NoorListItem(
            title: .text(l("menu.select_translation")),
            accessory: .disclosureIndicator
        )
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
