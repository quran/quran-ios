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

final class ReadingSelectorViewController: UIHostingController<ReadingSelector> {
    init(viewModel: ReadingSelectorViewModel) {
        super.init(rootView: ReadingSelector(viewModel: viewModel))

        navigationItem.title = l("reading.selector.title")
        navigationItem.prompt = l("reading.selector.selection-description")
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
