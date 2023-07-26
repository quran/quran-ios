//
//  ReadingItem.swift
//
//
//  Created by Mohamed Afifi on 2023-02-18.
//

import NoorUI
import SwiftUI
import UIx

struct ReadingItem<Value: Hashable, ImageView: View>: View {
    // MARK: Internal

    let reading: ReadingInfo<Value>
    let imageView: ImageView
    let selected: Bool
    let progress: Double?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                SingleAxisGeometryReader { width in
                    HStack {
                        VStack(alignment: .leading) {
                            if let progress {
                                ProgressView(value: progress, total: 1)
                            }
                            titleView
                            descriptionView
                        }
                        .frame(width: width * 0.65)

                        ReadingImage(imageView: imageView)
                    }
                }
                .padding()
                .background(background)
                .padding()

                checkmarkView
            }
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    // MARK: Private

    private var titleView: some View {
        Text(reading.title)
            .font(.headline)
            .padding(.bottom)
    }

    private var descriptionView: some View {
        Text(reading.description)
            .font(.footnote)
    }

    private var backgroundRectangle: some InsettableShape {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
    }

    private var background: some View {
        backgroundRectangle
            .strokeBorder(selected ? Color.appIdentity : .clear, lineWidth: 2)
            .background(backgroundRectangle
                .foregroundColor(Color.secondarySystemGroupedBackground)
            )
            .shadow(radius: 5, x: 0, y: 3)
    }

    @ViewBuilder private var checkmarkView: some View {
        if selected {
            NoorSystemImage.checkmark.image
                .foregroundColor(.white)
                .padding()
                .background(
                    Circle()
                        .foregroundColor(Color.appIdentity)
                        .shadow(radius: 3)
                )
        }
    }
}
