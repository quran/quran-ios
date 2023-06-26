//
//  DateSinceView.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/27/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import SwiftUI

struct DateSinceTextView: View {
    let since: String

    var body: some View {
        Text(since)
            .foregroundColor(.secondaryLabel)
            .font(.footnote)
    }
}

struct DateSinceView<Image: View>: View {
    let since: String
    let image: () -> Image

    var body: some View {
        HStack {
            image()
                .font(.footnote)
            DateSinceTextView(since: since)
            Spacer()
        }
    }
}
