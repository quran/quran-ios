//
//  RepeatCountRow.swift
//  Quran
//

import Localization
import QuranAudio
import SwiftUI

/// The repeat count as a list row that expands a wheel of Loop and 1× through 100×.
struct RepeatCountRow: View {
    // MARK: Lifecycle

    init(image: NoorSystemImage, runs: Binding<Runs>) {
        self.image = image
        _runs = runs
    }

    // MARK: Internal

    var body: some View {
        NoorWheelPickerRow(
            title: l("audio.repeat-count"),
            image: image,
            items: Runs.choices,
            selection: $runs
        ) { runs in
            RunsLabel(runs: runs)
        }
    }

    // MARK: Private

    @Binding private var runs: Runs

    private let image: NoorSystemImage
}

private struct RunsLabel: View {
    let runs: Runs

    var body: some View {
        switch runs {
        case .finite:
            Text(runs.localizedDescription)
        case .indefinite:
            HStack {
                Text(runs.localizedDescription.capitalized)
                NoorSystemImage.infinity.image
            }
        }
    }
}
