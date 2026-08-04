//
//  AnalyticsLibrary+Events.swift
//
//
//  Created by Mohamed Afifi on 2023-06-12.
//

import Analytics
import QuranKit
import VLogging

extension AnalyticsLibrary {
    private func logVersesEvent(_ name: String, verses: some Collection<AyahNumber>) {
        let versesDescription = verses.map(\.shortDescription).joined(separator: ", ")
        logger.info("AnalyticsVerses=\(name). Verses: [\(versesDescription)]")
        logEvent(name, value: verses.count.description)
    }

    public func highlight(verses: [AyahNumber]) {
        logVersesEvent("HighlightVersesNum", verses: verses)
    }

    public func unhighlight(verses: some Collection<AyahNumber>) {
        logVersesEvent("UnhighlightVersesNum", verses: verses)
    }

    public func updateNote(verses: Set<AyahNumber>) {
        logVersesEvent("UpdateNoteVersesNum", verses: verses)
    }
}

private extension AyahNumber {
    var shortDescription: String {
        "\(sura):\(ayah)"
    }
}
