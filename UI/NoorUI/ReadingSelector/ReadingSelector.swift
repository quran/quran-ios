//
//  ReadingSelector.swift
//
//
//  Created by Mohamed Afifi on 2023-02-12.
//

import SwiftUI
import UIx

public struct ReadingSelector<Value: Hashable, ImageView: View>: View {
    let selectedValue: Value?
    let readings: [ReadingInfo<Value>]
    let imageView: (ReadingInfo<Value>) -> ImageView
    let action: (Value) -> Void

    @State private var readingInfoDetails: ReadingInfo<Value>?

    public init(selectedValue: Value?,
                readings: [ReadingInfo<Value>],
                imageView: @escaping (ReadingInfo<Value>) -> ImageView,
                action: @escaping (Value) -> Void)
    {
        self.selectedValue = selectedValue
        self.readings = readings
        self.imageView = imageView
        self.action = action
    }

    public var body: some View {
        ScrollView {
            VStack {
                ForEach(readings) { reading in
                    ReadingItem(reading: reading,
                                imageView: imageView(reading),
                                selected: selectedValue == reading.value)
                    {
                        readingInfoDetails = reading
                    }
                }
            }
        }
        .sheet(item: $readingInfoDetails) { reading in
            ReadingDetails(reading: reading,
                           imageView: imageView(reading),
                           useAction: {
                               readingInfoDetails = nil
                               action(reading.value)
                           },
                           closeAction: { readingInfoDetails = nil })
        }
    }
}

struct ReadingSelector_Previews: PreviewProvider {
    private struct Container: View {
        @State var selectedValue = ReadingInfoTestData.Reading.b

        var body: some View {
            ReadingSelector(selectedValue: selectedValue,
                            readings: ReadingInfoTestData.readings,
                            imageView: imageView)
            {
                selectedValue = $0
            }
        }

        private func imageView(reading: ReadingInfo<ReadingInfoTestData.Reading>) -> some View {
            Image("logo-lg-w")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }

    static var previews: some View {
        Container()
    }
}
