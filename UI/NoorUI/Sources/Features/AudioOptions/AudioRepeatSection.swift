//
//  AudioRepeatSection.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

import Localization
import QuranAudio
import SwiftUI

/// A list section with a repeat count and a pause, for each verse or for the set of verses.
///
/// Audio Options and Settings › Audio Playback both show these sections. Callers pass the
/// pause choices and their labels, so NoorUI doesn't depend on the player's delay types.
public struct AudioRepeatSection<Delay: Hashable>: View {
    public enum Kind {
        /// Repeats and pauses after each verse.
        case eachVerse
        /// Repeats and pauses between plays of the whole set of verses.
        case setOfVerses
    }

    // MARK: Lifecycle

    public init(
        _ kind: Kind,
        runs: Binding<Runs>,
        delays: [Delay],
        delay: Binding<Delay>,
        delayLabel: @escaping (Delay) -> String
    ) {
        self.kind = kind
        _runs = runs
        self.delays = delays
        _delay = delay
        self.delayLabel = delayLabel
    }

    // MARK: Public

    public var body: some View {
        NoorBasicSection(title: title, footer: footer) {
            RepeatCountRow(image: repeatImage, runs: $runs)

            NoorMenuRow(
                title: delayTitle,
                image: .pauseDelay,
                items: delays,
                selection: $delay,
                label: delayLabel
            )
        }
    }

    // MARK: Private

    @Binding private var runs: Runs
    @Binding private var delay: Delay

    private let kind: Kind
    private let delays: [Delay]
    private let delayLabel: (Delay) -> String

    private var title: String {
        let title = switch kind {
        case .eachVerse: lAndroid("play_each_verse")
        case .setOfVerses: lAndroid("play_verses_range")
        }
        // The Android section titles end with a colon.
        return title.replacingOccurrences(of: ":", with: "")
    }

    private var footer: String {
        switch kind {
        case .eachVerse: l("audio.verse-delay.description")
        case .setOfVerses: l("audio.repetition-delay.description")
        }
    }

    private var repeatImage: NoorSystemImage {
        switch kind {
        case .eachVerse: .repeatVerse
        case .setOfVerses: .repeatRange
        }
    }

    private var delayTitle: String {
        switch kind {
        case .eachVerse: l("audio.verse-delay")
        case .setOfVerses: l("audio.repetition-delay")
        }
    }
}

#Preview {
    struct Container: View {
        @State var verseRuns = Runs.finite(1)
        @State var listRuns = Runs.indefinite
        @State var verseDelay = "Off"
        @State var repetitionDelay = "1s"

        var body: some View {
            NoorList {
                AudioRepeatSection(
                    .eachVerse,
                    runs: $verseRuns,
                    delays: ["Off", "0.5×", "1×"],
                    delay: $verseDelay,
                    delayLabel: { $0 }
                )
                AudioRepeatSection(
                    .setOfVerses,
                    runs: $listRuns,
                    delays: ["Off", "1s", "2s"],
                    delay: $repetitionDelay,
                    delayLabel: { $0 }
                )
            }
            .noorListIconColumn()
        }
    }
    return Container()
}
