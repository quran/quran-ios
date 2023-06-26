//
//  ReadingImage.swift
//
//
//  Created by Mohamed Afifi on 2023-02-18.
//

import SwiftUI

struct ReadingImage<ImageView: View>: View {
    let imageView: ImageView

    var body: some View {
        Group {
            imageView
                .padding(.vertical)
        }
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .foregroundColor(Color.tertiarySystemBackground)
                .shadow(radius: 3)
        )
    }
}
