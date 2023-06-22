//
//  ReadingSelector.swift
//
//
//  Created by Mohamed Afifi on 2023-02-12.
//

import SwiftUI
import UIx

public struct ReadingSelector<Value: Hashable, ImageView: View>: View {
    // MARK: Lifecycle

    public init(
        selectedValue: Value?,
        readings: [ReadingInfo<Value>],
        imageView: @escaping (ReadingInfo<Value>) -> ImageView,
        action: @escaping (Value) -> Void
    ) {
        self.selectedValue = selectedValue
        self.readings = readings
        self.imageView = imageView
        self.action = action
    }

    // MARK: Public

    public var body: some View {
        ScrollView {
            VStack {
                ForEach(readings) { reading in
                    ReadingItem(
                        reading: reading,
                        imageView: imageView(reading),
                        selected: selectedValue == reading.value
                    ) {
                        readingInfoDetails = reading
                    }
                }
            }
        }
        .sheet(item: $readingInfoDetails) { reading in
            ReadingDetails(
                reading: reading,
                imageView: imageView(reading),
                useAction: {
                    readingInfoDetails = nil
                    action(reading.value)
                },
                closeAction: { readingInfoDetails = nil }
            )
        }
    }

    // MARK: Internal

    let selectedValue: Value?
    let readings: [ReadingInfo<Value>]
    let imageView: (ReadingInfo<Value>) -> ImageView
    let action: (Value) -> Void

    // MARK: Private

    @State private var readingInfoDetails: ReadingInfo<Value>?
}

struct ReadingSelector_Previews: PreviewProvider {
    private struct Container: View {
        // MARK: Internal

        @State var selectedValue = ReadingInfoTestData.Reading.b

        var body: some View {
            ReadingSelector(
                selectedValue: selectedValue,
                readings: ReadingInfoTestData.readings,
                imageView: imageView
            ) {
                selectedValue = $0
            }
        }

        // MARK: Private

        private func imageView(reading: ReadingInfo<ReadingInfoTestData.Reading>) -> some View {
            NoorImage.logo.image
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }

    // MARK: Internal

    static var previews: some View {
        Container()
    }
}
