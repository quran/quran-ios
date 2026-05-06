//
//  CarPlayTemplateBuilder.swift
//  QuranEngineApp
//
//  Created for CarPlay support
//
import AudioBannerFeature
import CarPlay
import QueuePlayer
import QuranAudio
import QuranAudioKit
import QuranKit
import UIKit

struct ReciterInfo: Equatable {
    let id: Int
    let name: String
}

enum CarPlayPlaybackOption: Equatable {
    case audioEnd(AudioEnd)
    case selectVerses

    var title: String {
        switch self {
        case .audioEnd(let audioEnd):
            audioEnd.name
        case .selectVerses:
            "Select verses"
        }
    }
}

enum CarPlayCustomPlaybackAction {
    case selectSurah
    case selectStartVerse
    case selectEndVerse
    case selectVerseRuns(Runs)
    case selectListRuns(Runs)
    case playSelection
}

struct CarPlayVersePlaybackSelection: Equatable {
    var start: AyahNumber
    var end: AyahNumber
    var verseRuns: Runs
    var listRuns: Runs
}

struct CarPlayVerseBucket: Equatable {
    let range: ClosedRange<Int>
}

struct CarPlayChapterBucket: Equatable {
    let range: ClosedRange<Int>
}

enum CarPlayPlaybackStatus: Equatable {
    case ready
    case downloadRequired
    case downloading(progress: Double)
    case failed(message: String)

    var summaryText: String? {
        switch self {
        case .ready:
            nil
        case .downloadRequired:
            "Download required"
        case .downloading:
            "Downloading audio"
        case .failed:
            "Audio unavailable"
        }
    }

    var titleText: String? {
        switch self {
        case .ready:
            nil
        case .downloadRequired:
            "Download required to play"
        case .downloading:
            "Downloading audio..."
        case .failed:
            "Audio unavailable"
        }
    }

    var detailText: String? {
        switch self {
        case .ready:
            return nil
        case .downloadRequired:
            return "Tap play to download this range, then playback will start."
        case .downloading(let progress):
            let percentage = Int((progress * 100).rounded())
            if percentage > 0 {
                return "Playback will start automatically. \(percentage)% downloaded."
            }
            return "Playback will start automatically."
        case .failed(let message):
            return message
        }
    }

    var isPlayActionEnabled: Bool {
        switch self {
        case .downloading:
            false
        case .ready, .downloadRequired, .failed:
            true
        }
    }
}

final class CarPlayTemplateBuilder {
    static let shared = CarPlayTemplateBuilder()

    func makeChapterListTemplate(
        chapters: [ChapterInfo],
        selectedSurahNumber: Int?,
        selectedSurahStatus: String?,
        selectionHandler: @escaping (ChapterInfo) -> Void
    ) -> CPListTemplate {
        let template = configuredTemplate(
            title: "Quran Chapters",
            tabTitle: "Surahs",
            tabImage: "book.closed"
        )
        updateChapterListTemplate(
            template,
            chapters: chapters,
            selectedSurahNumber: selectedSurahNumber,
            selectedSurahStatus: selectedSurahStatus,
            selectionHandler: selectionHandler
        )
        return template
    }

    func updateChapterListTemplate(
        _ template: CPListTemplate,
        chapters: [ChapterInfo],
        selectedSurahNumber: Int?,
        selectedSurahStatus: String?,
        selectionHandler: @escaping (ChapterInfo) -> Void
    ) {
        let items: [CPListItem] = chapters.map { chapter in
            let isSelected = chapter.number == selectedSurahNumber
            let item = CPListItem(
                text: "\(chapter.number). \(chapter.name)",
                detailText: isSelected ? (selectedSurahStatus ?? "Current surah") : nil
            )
            item.handler = { _, completion in
                selectionHandler(chapter)
                completion()
            }
            return item
        }
        template.updateSections([CPListSection(items: items)])
        logTemplate("chapters", requestedItems: items.count, requestedSections: 1, template: template)
    }

    func makeRecitersTemplate(
        reciters: [ReciterInfo],
        selectedReciterId: Int?,
        selectionHandler: @escaping (ReciterInfo) -> Void
    ) -> CPListTemplate {
        let template = configuredTemplate(
            title: "Reciters",
            tabTitle: "Reciters",
            tabImage: "person.wave.2"
        )
        updateRecitersTemplate(
            template,
            reciters: reciters,
            selectedReciterId: selectedReciterId,
            selectionHandler: selectionHandler
        )
        return template
    }

    func updateRecitersTemplate(
        _ template: CPListTemplate,
        reciters: [ReciterInfo],
        selectedReciterId: Int?,
        selectionHandler: @escaping (ReciterInfo) -> Void
    ) {
        let items: [CPListItem] = reciters.map { reciter in
            let isSelected = reciter.id == selectedReciterId
            let item = CPListItem(
                text: reciter.name,
                detailText: isSelected ? "Current reciter" : nil
            )
            item.handler = { _, completion in
                selectionHandler(reciter)
                completion()
            }
            return item
        }
        template.updateSections([CPListSection(items: items)])
    }

    func makePlaybackModesTemplate(
        playbackOptions: [CarPlayPlaybackOption],
        selectedMode: AudioEnd,
        customPlaybackSummary: String?,
        selectionHandler: @escaping (CarPlayPlaybackOption) -> Void
    ) -> CPListTemplate {
        let template = configuredTemplate(
            title: "Playback Options",
            tabTitle: "Playback",
            tabImage: "waveform"
        )
        updatePlaybackModesTemplate(
            template,
            playbackOptions: playbackOptions,
            selectedMode: selectedMode,
            customPlaybackSummary: customPlaybackSummary,
            selectionHandler: selectionHandler
        )
        return template
    }

    func updatePlaybackModesTemplate(
        _ template: CPListTemplate,
        playbackOptions: [CarPlayPlaybackOption],
        selectedMode: AudioEnd,
        customPlaybackSummary: String?,
        selectionHandler: @escaping (CarPlayPlaybackOption) -> Void
    ) {
        let items: [CPListItem] = playbackOptions.map { option in
            let item = CPListItem(
                text: option.title,
                detailText: detailText(
                    for: option,
                    selectedMode: selectedMode,
                    customPlaybackSummary: customPlaybackSummary
                )
            )
            item.handler = { _, completion in
                selectionHandler(option)
                completion()
            }
            return item
        }
        template.updateSections([CPListSection(items: items)])
    }

    func makeCustomPlaybackTemplate(
        selection: CarPlayVersePlaybackSelection,
        surahTitle: String,
        playbackStatus: CarPlayPlaybackStatus,
        actionHandler: @escaping (CarPlayCustomPlaybackAction) -> Void
    ) -> CPListTemplate {
        let template = CPListTemplate(title: "Select Verses", sections: [])
        updateCustomPlaybackTemplate(
            template,
            selection: selection,
            surahTitle: surahTitle,
            playbackStatus: playbackStatus,
            actionHandler: actionHandler
        )
        return template
    }

    func updateCustomPlaybackTemplate(
        _ template: CPListTemplate,
        selection: CarPlayVersePlaybackSelection,
        surahTitle: String,
        playbackStatus: CarPlayPlaybackStatus,
        actionHandler: @escaping (CarPlayCustomPlaybackAction) -> Void
    ) {
        let surahItem = CPListItem(text: "Selected surah", detailText: surahTitle)
        surahItem.handler = { _, completion in
            actionHandler(.selectSurah)
            completion()
        }

        let fromItem = CPListItem(text: "From", detailText: verseTitle(for: selection.start))
        fromItem.handler = { _, completion in
            actionHandler(.selectStartVerse)
            completion()
        }

        let toItem = CPListItem(text: "To", detailText: verseTitle(for: selection.end))
        toItem.handler = { _, completion in
            actionHandler(.selectEndVerse)
            completion()
        }

        let verseRunsItems = runsItems(
            selected: selection.verseRuns,
            selectionHandler: { actionHandler(.selectVerseRuns($0)) }
        )
        let listRunsItems = runsItems(
            selected: selection.listRuns,
            selectionHandler: { actionHandler(.selectListRuns($0)) }
        )

        let playItem = CPListItem(
            text: "Play selected verses",
            detailText: "\(selection.start.ayah)-\(selection.end.ayah)"
        )
        playItem.isEnabled = playbackStatus.isPlayActionEnabled
        playItem.handler = { _, completion in
            actionHandler(.playSelection)
            completion()
        }

        var playbackItems = [CPListItem]()
        if let statusTitle = playbackStatus.titleText {
            let statusItem = CPListItem(text: statusTitle, detailText: playbackStatus.detailText)
            statusItem.isEnabled = false
            playbackItems.append(statusItem)
        }
        playbackItems.append(playItem)

        let sections = [
            CPListSection(items: [surahItem]),
            CPListSection(items: [fromItem, toItem], header: "Playing Verses", sectionIndexTitle: nil),
            CPListSection(items: verseRunsItems, header: "Play Each Verse", sectionIndexTitle: nil),
            CPListSection(items: listRunsItems, header: "Play Set Of Verses", sectionIndexTitle: nil),
            CPListSection(items: playbackItems, header: "Playback", sectionIndexTitle: nil),
        ]

        template.updateSections(sections)
        logTemplate(
            "customPlayback",
            requestedItems: sections.reduce(0) { $0 + $1.items.count },
            requestedSections: sections.count,
            template: template
        )
    }

    func makeVersePickerTemplate(
        title: String,
        verses: [AyahNumber],
        selectedVerse: AyahNumber,
        selectionHandler: @escaping (AyahNumber) -> Void
    ) -> CPListTemplate {
        let template = CPListTemplate(title: title, sections: [])
        updateVersePickerTemplate(
            template,
            title: title,
            verses: verses,
            selectedVerse: selectedVerse,
            selectionHandler: selectionHandler
        )
        return template
    }

    func updateVersePickerTemplate(
        _ template: CPListTemplate,
        title: String,
        verses: [AyahNumber],
        selectedVerse: AyahNumber,
        selectionHandler: @escaping (AyahNumber) -> Void
    ) {
        let items: [CPListItem] = verses.map { verse in
            let item = CPListItem(
                text: "Ayah \(verse.ayah)",
                detailText: verse == selectedVerse ? "Current value" : nil
            )
            item.handler = { _, completion in
                selectionHandler(verse)
                completion()
            }
            return item
        }
        template.updateSections([CPListSection(items: items)])
        logTemplate("exactVersePicker(\(title))", requestedItems: items.count, requestedSections: 1, template: template)
    }

    func makeVerseBucketTemplate(
        title: String,
        buckets: [CarPlayVerseBucket],
        selectedVerse: AyahNumber,
        selectionHandler: @escaping (CarPlayVerseBucket) -> Void
    ) -> CPListTemplate {
        let template = CPListTemplate(title: title, sections: [])
        let items: [CPListItem] = buckets.map { bucket in
            let item = CPListItem(
                text: rangeTitle(for: bucket.range),
                detailText: bucket.range.contains(selectedVerse.ayah) ? "Current value" : nil
            )
            item.handler = { _, completion in
                selectionHandler(bucket)
                completion()
            }
            return item
        }
        template.updateSections([CPListSection(items: items)])
        logTemplate("bucketVersePicker(\(title))", requestedItems: items.count, requestedSections: 1, template: template)
        return template
    }

    func makeChapterBucketTemplate(
        title: String,
        tabTitle: String? = nil,
        tabImage: String? = nil,
        buckets: [CarPlayChapterBucket],
        selectedChapterNumber: Int,
        selectionHandler: @escaping (CarPlayChapterBucket) -> Void
    ) -> CPListTemplate {
        let template = CPListTemplate(title: title, sections: [])
        template.tabTitle = tabTitle
        if let tabImage {
            template.tabImage = UIImage(systemName: tabImage)
        }
        updateChapterBucketTemplate(
            template,
            title: title,
            buckets: buckets,
            selectedChapterNumber: selectedChapterNumber,
            selectionHandler: selectionHandler
        )
        return template
    }

    func updateChapterBucketTemplate(
        _ template: CPListTemplate,
        title: String,
        buckets: [CarPlayChapterBucket],
        selectedChapterNumber: Int,
        selectionHandler: @escaping (CarPlayChapterBucket) -> Void
    ) {
        let items: [CPListItem] = buckets.map { bucket in
            let item = CPListItem(
                text: chapterRangeTitle(for: bucket.range),
                detailText: bucket.range.contains(selectedChapterNumber) ? "Current surah" : nil
            )
            item.handler = { _, completion in
                selectionHandler(bucket)
                completion()
            }
            return item
        }
        template.updateSections([CPListSection(items: items)])
        logTemplate("chapterBuckets(\(title))", requestedItems: items.count, requestedSections: 1, template: template)
    }

    func makeSurahPickerTemplate(
        title: String = "Select Surah",
        chapters: [ChapterInfo],
        selectedSurahNumber: Int,
        selectionHandler: @escaping (ChapterInfo) -> Void
    ) -> CPListTemplate {
        let template = CPListTemplate(title: title, sections: [])
        let items: [CPListItem] = chapters.map { chapter in
            let item = CPListItem(
                text: "\(chapter.number). \(chapter.name)",
                detailText: chapter.number == selectedSurahNumber ? "Current value" : nil
            )
            item.handler = { _, completion in
                selectionHandler(chapter)
                completion()
            }
            return item
        }
        template.updateSections([CPListSection(items: items)])
        logTemplate("surahPicker(\(title))", requestedItems: items.count, requestedSections: 1, template: template)
        return template
    }

    func makeRootTemplate(templates: [CPTemplate]) -> CPTabBarTemplate {
        CPTabBarTemplate(templates: templates)
    }

    private func configuredTemplate(title: String, tabTitle: String, tabImage: String) -> CPListTemplate {
        let template = CPListTemplate(title: title, sections: [])
        template.tabTitle = tabTitle
        template.tabImage = UIImage(systemName: tabImage)
        return template
    }

    private func detailText(
        for option: CarPlayPlaybackOption,
        selectedMode: AudioEnd,
        customPlaybackSummary: String?
    ) -> String? {
        switch option {
        case .audioEnd(let audioEnd):
            return audioEnd == selectedMode ? "Current mode" : nil
        case .selectVerses:
            return customPlaybackSummary ?? "Choose a verse range"
        }
    }

    private func runsItems(
        selected: Runs,
        selectionHandler: @escaping (Runs) -> Void
    ) -> [CPListItem] {
        CarPlayRuns.allCases.map { run in
            let item = CPListItem(
                text: run.title,
                detailText: run.runs == selected ? "Current value" : nil
            )
            item.handler = { _, completion in
                selectionHandler(run.runs)
                completion()
            }
            return item
        }
    }

    private func verseTitle(for ayah: AyahNumber) -> String {
        "\(ayah.sura.suraNumber). \(AudioPlaybackController.surahTitle(for: ayah.sura.suraNumber)) - Ayah \(ayah.ayah)"
    }

    private func rangeTitle(for range: ClosedRange<Int>) -> String {
        if range.lowerBound == range.upperBound {
            return "Ayah \(range.lowerBound)"
        }
        return "Ayahs \(range.lowerBound)-\(range.upperBound)"
    }

    private func chapterRangeTitle(for range: ClosedRange<Int>) -> String {
        if range.lowerBound == range.upperBound {
            return "Surah \(range.lowerBound)"
        }
        return "Surahs \(range.lowerBound)-\(range.upperBound)"
    }

    private func logTemplate(
        _ name: String,
        requestedItems: Int,
        requestedSections: Int,
        template: CPListTemplate
    ) {
        print(
            "[CarPlay] Template \(name): requestedItems=\(requestedItems), requestedSections=\(requestedSections), displayedItems=\(template.itemCount), displayedSections=\(template.sectionCount), maxItems=\(CPListTemplate.maximumItemCount), maxSections=\(CPListTemplate.maximumSectionCount)"
        )
    }
}

private enum CarPlayRuns: CaseIterable {
    case one
    case two
    case three
    case loop

    var runs: Runs {
        switch self {
        case .one:
            .one
        case .two:
            .two
        case .three:
            .three
        case .loop:
            .indefinite
        }
    }

    var title: String {
        switch self {
        case .one:
            "1 time"
        case .two:
            "2 times"
        case .three:
            "3 times"
        case .loop:
            "Loop"
        }
    }
}
