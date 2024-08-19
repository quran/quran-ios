//
//  MoreMenuWordPointerType.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import Localization
import SwiftUI

struct MoreMenuWordPointerType: View {
    let type: MoreMenu.TranslationPointerType

    var body: some View {
        NoorListItem(
            title: .text(l("menu.pointer.select_translation")),
            subtitle: .init(text: typeText, location: .trailing),
            accessory: .disclosureIndicator
        )
        .padding()
    }

    var typeText: String {
        switch type {
        case .translation:
            return l("translation.text-type.translation")
        case .transliteration:
            return l("translation.text-type.transliteration")
        }
    }
}

struct MoreMenuWordPointerType_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MoreMenuWordPointerType(type: .translation)
            Divider()
            MoreMenuWordPointerType(type: .transliteration)
        }
    }
}
