//
//  SingleChoiceRow.swift
//
//
//  Created by Mohamed Afifi on 2022-04-16.
//

import SwiftUI

public struct SingleChoiceRow: View {
    let text: String
    let selected: Bool
    public var body: some View {
        HStack {
            Text(text)
            Spacer()
            if selected {
                Image(systemName: "checkmark")
                    .foregroundColor(Color.accentColor)
            }
        }
        .padding()
    }
}

struct SingleChoiceRow_Previews: PreviewProvider {
    static var previews: some View {
        Previewing.screen {
            List {
                SingleChoiceRow(text: "translation", selected: false)
                SingleChoiceRow(text: "transliteration", selected: true)
            }
        }
        .previewLayout(.fixed(width: 320, height: 200))
    }
}
