//
//  TableHeaderView.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/29/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import SwiftUI
import UIx

public struct TableHeaderView: View {
    public init(title: String) {
        self.title = title
    }

    let title: String
    public var body: some View {
        HStack {
            Text(title)
                .font(.callout)
                .fontWeight(.semibold)
                .padding()
            Spacer()
        }
        .background(Color.systemGray5)
    }
}

struct TableHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Previewing.list {
            TableHeaderView(title: "Juz' 1")
            Divider()

            TableHeaderView(title: "Juz' 30")
            Divider()
        }
    }
}
