//
//  MoreMenuFontSize.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import Localization
import QuranText
import SwiftUI
import UIx

struct MoreMenuFontSize: View {
    let label: String
    @Binding var fontSize: FontSize

    private let fonts = Array(FontSize.allCases.sorted().reversed())
    private var fontIndex: Binding<Int> {
        Binding(
            get: { fonts.firstIndex(of: fontSize)! },
            set: { fontSize = fonts[$0] }
        )
    }

    var body: some View {
        Stepper(value: fontIndex, in: 0 ... fonts.count - 1) {
            HStack {
                Text(label)
                Spacer()
                    .background(
                        HStack {
                            Spacer()
                            Text(l("menu.fontSizeLetter")).font(.system(size: fontSizeInPoints))
                            Spacer()
                        }
                    )
            }
        }
        .padding()
    }

    private var fontSizeInPoints: CGFloat {
        switch fontSize {
        case .xxLarge:
            return 35
        case .xLarge:
            return 31
        case .large:
            return 25
        case .medium:
            return 20
        case .small:
            return 14
        case .xSmall:
            return 10
        case .xxSmall:
            return 7
        }
    }
}

struct MoreMenuFontSize_Previews: PreviewProvider {
    struct Container: View {
        @State var fontSize: FontSize
        var body: some View {
            MoreMenuFontSize(label: "Font Size", fontSize: $fontSize)
        }
    }

    static var previews: some View {
        Previewing.screen {
            VStack {
                Container(fontSize: .xSmall)
                Divider()
                Container(fontSize: .medium)
                Divider()
                Container(fontSize: .xLarge)
            }
        }
        .previewLayout(.fixed(width: 320, height: 300))
    }
}
