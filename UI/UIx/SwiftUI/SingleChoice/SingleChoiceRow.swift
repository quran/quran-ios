//
//  SingleChoiceRow.swift
//
//
//  Created by Mohamed Afifi on 2022-04-16.
//

import SwiftUI

public struct SingleChoiceRow: View {
    // MARK: Public

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

    // MARK: Internal

    let text: String
    let selected: Bool
}

struct SingleChoiceRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            SingleChoiceRow(text: "translation", selected: false)
            SingleChoiceRow(text: "transliteration", selected: true)
        }
    }
}
