//
//  ReadingSelectorViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-02-13.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import Localization
import NoorUI
import QuranKit
import SwiftUI

class ReadingSelectorViewController: UIHostingController<ReadingSelectorContainer> {
    init() {
        super.init(rootView: ReadingSelectorContainer(viewModel: ReadingSelectorViewModel()))

        navigationItem.title = l("reading.selector.title")
        navigationItem.prompt = l("reading.selector.selection-description")
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ReadingSelectorContainer: View {
    // MARK: Internal

    @StateObject var viewModel: ReadingSelectorViewModel

    var body: some View {
        ReadingSelector(
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
