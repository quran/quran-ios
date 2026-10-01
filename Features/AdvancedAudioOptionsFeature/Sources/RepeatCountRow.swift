//
//  RepeatCountRow.swift
//  Quran
//

import Localization
import NoorUI
import QuranAudio
import QuranAudioKit
import SwiftUI

/// The repeat count as a list row that expands a wheel of Loop and 1× through 100×.
struct RepeatCountRow: View {
    let image: NoorSystemImage
    @Binding var runs: Runs

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
