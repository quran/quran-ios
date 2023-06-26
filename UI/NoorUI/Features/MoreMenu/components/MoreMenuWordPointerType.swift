//
//  SwiftUIView.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import Localization
import SwiftUI
import UIx

struct MoreMenuWordPointerType: View {
    let type: MoreMenu.TranslationPointerType

    var body: some View {
        HStack {
            Text(l("menu.pointer.select_translation"))
            Spacer()
            Text(typeText)
                .font(.footnote)
                .foregroundColor(.secondaryLabel)
            Image(systemName: "chevron.right")
                .flipsForRightToLeftLayoutDirection(true)
        }
        .padding()
    }

    var typeText: String {
        switch type {
        case .translation:
            return l("translationTextType")
        case .transliteration:
            return l("transliterationTextType")
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
