//
//  ReadingSelector.swift
//
//
//  Created by Mohamed Afifi on 2023-02-12.
//

import Localization
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
            groups: viewModel.readingGroups,
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
        reading.usesInvertedQuranImageRenderingInDarkMode ? .invertInDarkMode : .tinted
    }
}

private struct ReadingSelectorUI<Value: Hashable, ImageView: View>: View {
    // MARK: Internal

    @Binding var error: Error?

    let progress: Double?
    let selectedValue: Value?
    let groups: [ReadingGroup<Value>]
    let imageView: (ReadingInfo<Value>) -> ImageView
    let selectItem: (Value) -> Void
    let start: AsyncAction
    let retry: AsyncAction

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack {
                    Color.clear
                        .frame(height: 0)
                        .id(ReadingSelectorScrollPosition.top)

                    SegmentedChoicesPicker(
                        title: l("reading.selector.title"),
                        items: groups.map(\.id),
                        selection: $selectedGroupID,
                        label: groupTitle
                    )
                    .padding()

                    ForEach(selectedReadings) { reading in
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
            .onChange(of: selectedGroupID) { _ in
                proxy.scrollTo(ReadingSelectorScrollPosition.top, anchor: .top)
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
        .onChange(of: selectedValue) { selectedValue in
            guard
                let selectedValue,
                let group = groups.first(where: { group in
                    group.readings.contains(where: { $0.value == selectedValue })
                })
            else { return }
            selectedGroupID = group.id
        }
        .errorAlert(error: $error, retry: retry)
    }

    // MARK: Private

    @State private var readingInfoDetails: ReadingInfo<Value>?
    @State private var selectedGroupID: String

    private var selectedReadings: [ReadingInfo<Value>] {
        groups.first(where: { $0.id == selectedGroupID })?.readings ?? []
    }

    init(
        error: Binding<Error?>,
        progress: Double?,
        selectedValue: Value?,
        groups: [ReadingGroup<Value>],
        imageView: @escaping (ReadingInfo<Value>) -> ImageView,
        selectItem: @escaping (Value) -> Void,
        start: @escaping AsyncAction,
        retry: @escaping AsyncAction
    ) {
        _error = error
        self.progress = progress
        self.selectedValue = selectedValue
        self.groups = groups
        self.imageView = imageView
        self.selectItem = selectItem
        self.start = start
        self.retry = retry
        let selectedGroup = groups.first { group in
            group.readings.contains(where: { $0.value == selectedValue })
        }
        _selectedGroupID = State(initialValue: selectedGroup?.id ?? groups.first?.id ?? "")
    }

    private func groupTitle(_ id: String) -> String {
        groups.first(where: { $0.id == id })?.title ?? ""
    }
}

private enum ReadingSelectorScrollPosition {
    case top
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
                    groups: ReadingInfoTestData.groups,
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
