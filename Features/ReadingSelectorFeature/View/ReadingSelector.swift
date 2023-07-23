//
//  ReadingSelector.swift
//
//
//  Created by Mohamed Afifi on 2023-02-12.
//

import NoorUI
import QuranKit
import SwiftUI
import UIx

struct ReadingSelector: View {
    // MARK: Internal

    @StateObject var viewModel: ReadingSelectorViewModel

    var body: some View {
        ReadingSelectorUI(
            selectedValue: viewModel.selectedReading,
            readings: viewModel.readings,
            imageView: imageView
        ) {
            viewModel.showReading($0)
        }
    }

    // MARK: Private

    private func imageView(reading: ReadingInfo<Reading>) -> some View {
        ReadingImageView(
            image: UIImage(named: reading.value.imageName)!,
            pageMarkers: reading.value.pageMarkers
        )
    }
}

private struct ReadingSelectorUI<Value: Hashable, ImageView: View>: View {
    // MARK: Internal

    let selectedValue: Value?
    let readings: [ReadingInfo<Value>]
    let imageView: (ReadingInfo<Value>) -> ImageView
    let action: (Value) -> Void

    var body: some View {
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
        .background(
            Color.systemGroupedBackground
                .edgesIgnoringSafeArea(.all)
        )
    }

    // MARK: Private

    @State private var readingInfoDetails: ReadingInfo<Value>?
}

struct ReadingSelector_Previews: PreviewProvider {
    private struct Container: View {
        // MARK: Internal

        @State var selectedValue = ReadingInfoTestData.Reading.b

        var body: some View {
            NavigationView {
                ReadingSelectorUI(
                    selectedValue: selectedValue,
                    readings: ReadingInfoTestData.readings,
                    imageView: imageView
                ) {
                    selectedValue = $0
                }
                .navigationTitle("Title")
            }
        }

        // MARK: Private

        private func imageView(reading: ReadingInfo<ReadingInfoTestData.Reading>) -> some View {
            Image(uiImage: UIImage(contentsOfFile: testResourceURL("images/page604.png").absoluteString)!)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }

    // MARK: Internal

    static var previews: some View {
        Container()
    }
}
