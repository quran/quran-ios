//
//  PageNumberListItemView.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/27/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import SwiftUI
import UIx

public struct PageNumberListItemView: View {
    public init(page: Int) {
        self.page = page
    }

    let page: Int

    public var body: some View {
        Text(NumberFormatter.shared.format(page))
            .foregroundColor(.secondaryLabel)
            .font(.callout)
            .fontWeight(.light)
    }
}

struct PageNumberListItemView_Previews: PreviewProvider {
    static var previews: some View {
        Previewing.list {
            HStack {
                Spacer()
                PageNumberListItemView(page: 12)
                    .padding()
            }
            Divider()
        }
    }
}
