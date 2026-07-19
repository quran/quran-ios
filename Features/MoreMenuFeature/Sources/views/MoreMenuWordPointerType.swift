//
//  MoreMenuWordPointerType.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import Localization
import NoorUI
import QuranText
import SwiftUI

struct MoreMenuWordPointerType: View {
    let type: WordTextType

    var body: some View {
        NoorListItem(
            title: .text(l("menu.pointer.select_translation")),
            subtitle: .init(text: type.localizedName, location: .trailing),
            accessory: .disclosureIndicator
        )
        .padding()
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

extension WordTextType {
    var localizedName: String {
        switch self {
        case .translation:
            return l("translation.text-type.translation")
        case .transliteration:
            return l("translation.text-type.transliteration")
        }
    }
}
