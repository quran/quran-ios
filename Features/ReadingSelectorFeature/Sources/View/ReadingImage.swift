//
//  ReadingImage.swift
//
//
//  Created by Mohamed Afifi on 2023-02-18.
//

import NoorUI
import SwiftUI

struct ReadingImage<ImageView: View>: View {
    let imageView: ImageView
    @ScaledMetric var cornerRadius = Dimensions.cornerRadius

    var body: some View {
        Group {
            imageView
                .padding(.vertical)
        }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .foregroundColor(Color.tertiarySystemBackground)
                .shadow(radius: 3)
        )
    }
}
