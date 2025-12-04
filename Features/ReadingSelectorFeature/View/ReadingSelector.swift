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
            error: $viewModel.error,
            progress: viewModel.progress,
            selectedValue: viewModel.selectedReading,
            readings: viewModel.readings,
            imageView: imageView,
            selectItem: { viewModel.showReading($0) },
            start: { await viewModel.start() },
            retry: { }
        )
        .populateThemeStyle()
    }

    // MARK: Private

    private func imageView(reading: ReadingInfo<Reading>) -> some View {
        ReadingImageView(
            image: UIImage(named: reading.value.imageName)!,
            suraHeaders: reading.value.suraHeaders,
            ayahNumbers: reading.value.ayahNumbers,
            renderingMode: renderingMode(for: reading.value)
        )
    }

    private func renderingMode(for reading: Reading) -> QuranThemedImage.RenderingMode {
        reading == .tajweed ? .invertInDarkMode : .tinted
    }
}

private struct ReadingSelectorUI<Value: Hashable, ImageView: View>: View {
    // MARK: Internal

    @Binding var error: Error?

    let progress: Double?
    let selectedValue: Value?
    let readings: [ReadingInfo<Value>]
    let imageView: (ReadingInfo<Value>) -> ImageView
    let selectItem: (Value) -> Void
    let start: AsyncAction
    let retry: AsyncAction

    var body: some View {
        ScrollView {
            VStack {
                ForEach(readings) { reading in
                    let selected = selectedValue == reading.value
                    ReadingItem(
                        reading: reading,
                        imageView: imageView(reading),
                        selected: selected,
                        progress: selected ? progress : nil
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
                    selectItem(reading.value)
                },
                closeAction: { readingInfoDetails = nil }
            )
        }
        .background(
            Color.systemGroupedBackground
                .edgesIgnoringSafeArea(.all)
        )
        .task { await start() }
        .errorAlert(error: $error, retry: retry)
    }

    // MARK: Private

    @State private var readingInfoDetails: ReadingInfo<Value>?
}

struct ReadingSelector_Previews: PreviewProvider {
    private struct Container: View {
        // MARK: Internal

        @State var selectedValue = ReadingInfoTestData.Reading.b
        @State var error: Error?

        var body: some View {
            NavigationView {
                ReadingSelectorUI(
                    error: $error,
                    progress: 0.3,
                    selectedValue: selectedValue,
                    readings: ReadingInfoTestData.readings,
                    imageView: imageView,
                    selectItem: { selectedValue = $0 },
                    start: { },
                    retry: { }
                )
                .navigationTitle("Reading Selector")
                .toolbar {
                    if error == nil {
                        Button("Error") { error = URLError(.notConnectedToInternet) }
                    }
                }
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
