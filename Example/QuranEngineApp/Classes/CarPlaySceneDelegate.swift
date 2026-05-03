import AudioBannerFeature
import CarPlay
import MediaPlayer
import QueuePlayer
import QuranAudio
import QuranAudioKit
import QuranKit
import ReciterService
import UIKit

@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private var playbackController: AudioPlaybackController?
    private var playbackObserverId: UUID?
    private var chaptersTemplate: CPListTemplate?
    private var recitersTemplate: CPListTemplate?
    private var playbackModesTemplate: CPListTemplate?
    private var customPlaybackTemplate: CPListTemplate?
    private var chapters: [ChapterInfo] = []
    private var reciters: [Reciter] = []
    private let audioPreferences = AudioPreferences.shared
    private var selectedSurahNumber = 1
    private var selectedReciterId: Int?
    private var selectedPlaybackMode = AudioEnd.juz
    private var customPlaybackSelection: CarPlayVersePlaybackSelection?
    private var customPlaybackStatus: CarPlayPlaybackStatus = .ready
    private var customPlaybackAvailabilityTask: Task<Void, Never>?
    private var lastObservedPlaybackState: AudioPlaybackController.PlaybackState?
    private var isPresentingNowPlaying = false
    private let versePickerLeafSize = 10
    private var chapterPickerListLimit: Int { max(Int(CPListTemplate.maximumItemCount), 1) }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        chapters = createChapters()

        guard let playbackController = AudioPlaybackControllerStore.shared else {
            print("[CarPlay] No shared AudioPlaybackController available")
            return
        }

        self.playbackController = playbackController
        observePlaybackController(playbackController)
        selectedPlaybackMode = audioPreferences.audioEnd

        Task { @MainActor in
            let reciters = await playbackController.getReciters()
            self.reciters = reciters
            let snapshot = playbackController.snapshot
            selectedSurahNumber = snapshot.surahNumber ?? selectedSurahNumber
            selectedReciterId = snapshot.reciter?.id ?? reciters.first?.id
            resetCustomPlaybackSelection()

            let builder = CarPlayTemplateBuilder.shared
            let chaptersTemplate: CPListTemplate = if chapters.count > chapterPickerListLimit {
                builder.makeChapterBucketTemplate(
                    title: "Quran Chapters",
                    tabTitle: "Surahs",
                    tabImage: "book.closed",
                    buckets: chapterBuckets(for: chapters),
                    selectedChapterNumber: selectedSurahNumber,
                    selectionHandler: { [weak self] bucket in
                        self?.didSelectChapterBucket(bucket)
                    }
                )
            } else {
                builder.makeChapterListTemplate(
                    chapters: chapters,
                    selectedSurahNumber: selectedSurahNumber,
                    selectedSurahStatus: selectedSurahStatusDetail,
                    selectionHandler: { [weak self] chapter in
                        self?.didSelectChapter(chapter)
                    }
                )
            }
            let recitersTemplate = builder.makeRecitersTemplate(
                reciters: reciterInfos(),
                selectedReciterId: selectedReciterId,
                selectionHandler: { [weak self] reciter in
                    self?.didSelectReciter(reciter)
                }
            )
            let playbackModesTemplate = builder.makePlaybackModesTemplate(
                playbackOptions: playbackOptions,
                selectedMode: selectedPlaybackMode,
                customPlaybackSummary: customPlaybackSummary,
                selectionHandler: { [weak self] option in
                    self?.didSelectPlaybackOption(option)
                }
            )

            self.chaptersTemplate = chaptersTemplate
            self.recitersTemplate = recitersTemplate
            self.playbackModesTemplate = playbackModesTemplate

            do {
                let requestedTemplates: [CPTemplate] = [
                    chaptersTemplate,
                    recitersTemplate,
                    playbackModesTemplate,
                ]
                let maxTabCount = max(Int(CPTabBarTemplate.maximumTabCount), 1)
                let rootTemplates = Array(requestedTemplates.prefix(maxTabCount))
                print(
                    "[CarPlay] Root templates requested=\(requestedTemplates.count), maxTabCount=\(maxTabCount)"
                )

                let rootTemplate = builder.makeRootTemplate(templates: rootTemplates)
                try await interfaceController.setRootTemplate(rootTemplate, animated: true)
                refreshTemplates()
                updateNowPlayingInfo(with: snapshot)
            } catch {
                print("[CarPlay] Failed to set root template: \(error)")
            }
        }
    }

    private func observePlaybackController(_ playbackController: AudioPlaybackController) {
        playbackObserverId = playbackController.addObserver { [weak self] snapshot in
            self?.handlePlaybackSnapshot(snapshot)
        }
    }

    private func handlePlaybackSnapshot(_ snapshot: AudioPlaybackController.Snapshot) {
        if let surahNumber = snapshot.surahNumber {
            selectedSurahNumber = surahNumber
        }
        if let reciterId = snapshot.reciter?.id {
            selectedReciterId = reciterId
        }

        synchronizeCustomPlaybackStatus(with: snapshot)
        refreshTemplates()
        updateNowPlayingInfo(with: snapshot)

        if case .playing = snapshot.playbackState, !isPlaying(lastObservedPlaybackState) {
            Task { @MainActor in
                await presentNowPlayingIfNeeded()
            }
        }

        lastObservedPlaybackState = snapshot.playbackState
    }

    private func didSelectChapter(_ chapter: ChapterInfo) {
        selectedSurahNumber = chapter.number
        resetCustomPlaybackSelection()
        refreshTemplates()
        Task { @MainActor in
            await playCurrentSelection()
        }
    }

    private func didSelectReciter(_ reciterInfo: ReciterInfo) {
        guard let playbackController,
              let reciter = reciters.first(where: { $0.id == reciterInfo.id }) else {
            return
        }

        selectedReciterId = reciter.id
        playbackController.setReciter(reciter)
        refreshCustomPlaybackAvailability()
        refreshTemplates()
        updateNowPlayingInfo(with: playbackController.snapshot)
    }

    private func didSelectPlaybackOption(_ option: CarPlayPlaybackOption) {
        switch option {
        case .audioEnd(let mode):
            selectedPlaybackMode = mode
            audioPreferences.audioEnd = mode
            refreshTemplates()
            Task { @MainActor in
                await playCurrentSelection()
            }
        case .selectVerses:
            Task { @MainActor in
                await showCustomPlaybackTemplate()
            }
        }
    }

    private func playCurrentSelection() async {
        guard let playbackController else {
            return
        }

        let quran = Quran.hafsMadani1405
        guard quran.suras.indices.contains(selectedSurahNumber - 1) else {
            return
        }

        let surah = quran.suras[selectedSurahNumber - 1]
        let request = playbackRequest(for: surah, audioEnd: selectedPlaybackMode)

        do {
            try await playbackController.play(
                from: request.start,
                to: request.end,
                verseRuns: request.verseRuns,
                listRuns: request.listRuns
            )
            updateNowPlayingInfo(with: playbackController.snapshot)
            await presentNowPlayingIfNeeded()
        } catch {
            await presentPlaybackFailureAlert()
            print("[CarPlay] Failed to play surah \(selectedSurahNumber): \(error)")
        }
    }

    private func presentNowPlayingIfNeeded() async {
        guard let interfaceController,
              !isPresentingNowPlaying,
              interfaceController.topTemplate !== CPNowPlayingTemplate.shared else {
            return
        }

        do {
            isPresentingNowPlaying = true
            defer { isPresentingNowPlaying = false }
            try await interfaceController.pushTemplate(CPNowPlayingTemplate.shared, animated: true)
        } catch {
            print("[CarPlay] Failed to push now playing template: \(error)")
        }
    }

    private func refreshTemplates() {
        let builder = CarPlayTemplateBuilder.shared

        if let chaptersTemplate {
            if chapters.count > chapterPickerListLimit {
                builder.updateChapterBucketTemplate(
                    chaptersTemplate,
                    title: "Quran Chapters",
                    buckets: chapterBuckets(for: chapters),
                    selectedChapterNumber: selectedSurahNumber,
                    selectionHandler: { [weak self] bucket in
                        self?.didSelectChapterBucket(bucket)
                    }
                )
            } else {
                builder.updateChapterListTemplate(
                    chaptersTemplate,
                    chapters: chapters,
                    selectedSurahNumber: selectedSurahNumber,
                    selectedSurahStatus: selectedSurahStatusDetail,
                    selectionHandler: { [weak self] chapter in
                        self?.didSelectChapter(chapter)
                    }
                )
            }
        }

        if let recitersTemplate {
            builder.updateRecitersTemplate(
                recitersTemplate,
                reciters: reciterInfos(),
                selectedReciterId: selectedReciterId,
                selectionHandler: { [weak self] reciter in
                    self?.didSelectReciter(reciter)
                }
            )
        }

        if let playbackModesTemplate {
            builder.updatePlaybackModesTemplate(
                playbackModesTemplate,
                playbackOptions: playbackOptions,
                selectedMode: selectedPlaybackMode,
                customPlaybackSummary: customPlaybackSummary,
                selectionHandler: { [weak self] option in
                    self?.didSelectPlaybackOption(option)
                }
            )
        }

        refreshCustomPlaybackTemplate()
    }

    private func updateNowPlayingInfo(with snapshot: AudioPlaybackController.Snapshot) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]

        if let title = snapshot.surahTitle {
            info[MPMediaItemPropertyTitle] = title
        }
        if let reciterName = snapshot.reciterName {
            info[MPMediaItemPropertyArtist] = reciterName
        }

        let existingRate = (info[MPNowPlayingInfoPropertyPlaybackRate] as? NSNumber)?.floatValue ?? 1
        let playbackRate: Float = switch snapshot.playbackState {
        case .playing:
            existingRate
        case .paused, .stopped, .downloading:
            0
        }
        info[MPNowPlayingInfoPropertyPlaybackRate] = playbackRate

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info.isEmpty ? nil : info
    }

    private func createChapters() -> [ChapterInfo] {
        (1 ... 114).map { number in
            ChapterInfo(id: number, number: number, name: AudioPlaybackController.surahTitle(for: number))
        }
    }

    private func reciterInfos() -> [ReciterInfo] {
        reciters.map { ReciterInfo(id: $0.id, name: $0.localizedName) }
    }

    private var playbackOptions: [CarPlayPlaybackOption] {
        [.audioEnd(.juz), .audioEnd(.sura), .audioEnd(.page), .selectVerses]
    }

    private var customPlaybackSummary: String? {
        guard let selection = customPlaybackSelection else {
            return nil
        }
        let rangeSummary: String
        if selection.start.sura == selection.end.sura {
            rangeSummary = "Ayahs \(selection.start.ayah)-\(selection.end.ayah)"
        } else {
            rangeSummary = "\(selection.start.ayah)-\(selection.end.ayah)"
        }
        guard let statusSummary = customPlaybackStatus.summaryText else {
            return rangeSummary
        }
        return "\(rangeSummary) - \(statusSummary)"
    }

    private func isPlaying(_ state: AudioPlaybackController.PlaybackState?) -> Bool {
        guard let state else {
            return false
        }
        if case .playing = state {
            return true
        }
        return false
    }

    private func playbackRequest(
        for surah: Sura,
        audioEnd: AudioEnd
    ) -> (start: AyahNumber, end: AyahNumber, verseRuns: Runs, listRuns: Runs) {
        let start = surah.firstVerse
        let end = audioEnd.findLastAyah(startAyah: start)
        return (start, end, .one, .one)
    }

    private func resetCustomPlaybackSelection() {
        guard let surah = selectedSurah else {
            customPlaybackSelection = nil
            customPlaybackStatus = .ready
            return
        }
        customPlaybackSelection = CarPlayVersePlaybackSelection(
            start: surah.firstVerse,
            end: surah.lastVerse,
            verseRuns: .one,
            listRuns: .one
        )
        customPlaybackStatus = .ready
        refreshCustomPlaybackAvailability()
        refreshCustomPlaybackTemplate()
    }

    private func refreshCustomPlaybackTemplate() {
        guard let customPlaybackTemplate,
              let selection = customPlaybackSelection,
              let surah = selectedSurah else {
            return
        }
        CarPlayTemplateBuilder.shared.updateCustomPlaybackTemplate(
            customPlaybackTemplate,
            selection: selection,
            surahTitle: AudioPlaybackController.surahTitle(for: surah.suraNumber, withNumber: true),
            playbackStatus: customPlaybackStatus,
            actionHandler: { [weak self] action in
                self?.didSelectCustomPlaybackAction(action)
            }
        )
    }

    private func showCustomPlaybackTemplate() async {
        guard let interfaceController,
              let selection = customPlaybackSelection,
              let surah = selectedSurah else {
            return
        }

        let template: CPListTemplate
        if let customPlaybackTemplate {
            template = customPlaybackTemplate
            refreshCustomPlaybackTemplate()
        } else {
            let newTemplate = CarPlayTemplateBuilder.shared.makeCustomPlaybackTemplate(
                selection: selection,
                surahTitle: AudioPlaybackController.surahTitle(for: surah.suraNumber, withNumber: true),
                playbackStatus: customPlaybackStatus,
                actionHandler: { [weak self] action in
                    self?.didSelectCustomPlaybackAction(action)
                }
            )
            customPlaybackTemplate = newTemplate
            template = newTemplate
        }

        guard interfaceController.topTemplate !== template else {
            return
        }

        do {
            try await interfaceController.pushTemplate(template, animated: true)
        } catch {
            print("[CarPlay] Failed to push custom playback template: \(error)")
        }
    }

    private func didSelectCustomPlaybackAction(_ action: CarPlayCustomPlaybackAction) {
        switch action {
        case .selectSurah:
            Task { @MainActor in
                await showCustomPlaybackSurahPicker()
            }
        case .selectStartVerse:
            Task { @MainActor in
                await showVersePicker(forStartVerse: true)
            }
        case .selectEndVerse:
            Task { @MainActor in
                await showVersePicker(forStartVerse: false)
            }
        case .selectVerseRuns(let runs):
            updateCustomPlaybackSelection {
                $0.verseRuns = runs
            }
        case .selectListRuns(let runs):
            updateCustomPlaybackSelection {
                $0.listRuns = runs
            }
        case .playSelection:
            Task { @MainActor in
                await playCustomSelection()
            }
        }
    }

    private func showCustomPlaybackSurahPicker() async {
        guard let interfaceController else {
            return
        }

        let template: CPListTemplate = if chapters.count > chapterPickerListLimit {
            CarPlayTemplateBuilder.shared.makeChapterBucketTemplate(
                title: "Select Surah",
                buckets: chapterBuckets(for: chapters),
                selectedChapterNumber: selectedSurahNumber,
                selectionHandler: { [weak self] bucket in
                    self?.didSelectCustomPlaybackSurahBucket(bucket)
                }
            )
        } else {
            CarPlayTemplateBuilder.shared.makeSurahPickerTemplate(
                chapters: chapters,
                selectedSurahNumber: selectedSurahNumber,
                selectionHandler: { [weak self] chapter in
                    self?.didSelectCustomPlaybackSurah(chapter)
                }
            )
        }

        do {
            try await interfaceController.pushTemplate(template, animated: true)
        } catch {
            print("[CarPlay] Failed to push surah picker template: \(error)")
        }
    }

    private func didSelectChapterBucket(_ bucket: CarPlayChapterBucket) {
        Task { @MainActor in
            await showChapterPicker(
                title: "Quran Chapters \(chapterRangeTitle(bucket.range))",
                chapters: chapters(in: bucket),
                selectionHandler: { [weak self] chapter in
                    self?.didSelectChapter(chapter)
                }
            )
        }
    }

    private func didSelectCustomPlaybackSurahBucket(_ bucket: CarPlayChapterBucket) {
        Task { @MainActor in
            await showChapterPicker(
                title: "Select Surah \(chapterRangeTitle(bucket.range))",
                chapters: chapters(in: bucket),
                selectionHandler: { [weak self] chapter in
                    self?.didSelectCustomPlaybackSurah(chapter)
                }
            )
        }
    }

    private func didSelectCustomPlaybackSurah(_ chapter: ChapterInfo) {
        selectedSurahNumber = chapter.number
        guard let surah = selectedSurah else {
            return
        }

        customPlaybackSelection = CarPlayVersePlaybackSelection(
            start: surah.firstVerse,
            end: surah.lastVerse,
            verseRuns: customPlaybackSelection?.verseRuns ?? .one,
            listRuns: customPlaybackSelection?.listRuns ?? .one
        )
        customPlaybackStatus = .ready
        refreshCustomPlaybackAvailability()
        refreshTemplates()

        Task { @MainActor in
            guard let interfaceController else {
                return
            }
            do {
                if let customPlaybackTemplate {
                    try await interfaceController.pop(to: customPlaybackTemplate, animated: true)
                } else {
                    try await interfaceController.popTemplate(animated: true)
                }
            } catch {
                print("[CarPlay] Failed to pop surah picker template: \(error)")
            }
        }
    }

    private func showChapterPicker(
        title: String,
        chapters: [ChapterInfo],
        selectionHandler: @escaping (ChapterInfo) -> Void
    ) async {
        guard let interfaceController else {
            return
        }

        let template = CarPlayTemplateBuilder.shared.makeSurahPickerTemplate(
            title: title,
            chapters: chapters,
            selectedSurahNumber: selectedSurahNumber,
            selectionHandler: selectionHandler
        )

        do {
            try await interfaceController.pushTemplate(template, animated: true)
        } catch {
            print("[CarPlay] Failed to push chapter picker template: \(error)")
        }
    }

    private func showVersePicker(forStartVerse: Bool) async {
        guard let interfaceController,
              let selection = customPlaybackSelection,
              let surah = selectedSurah else {
            return
        }

        let allowedRange = allowedVerseRange(forStartVerse: forStartVerse, selection: selection, surah: surah)
        let selectedAyah = min(
            max((forStartVerse ? selection.start : selection.end).ayah, allowedRange.lowerBound),
            allowedRange.upperBound
        )
        let selectedVerse = AyahNumber(sura: surah, ayah: selectedAyah) ?? surah.firstVerse
        let title = forStartVerse ? "Select Start Verse" : "Select End Verse"
        let verses = surah.verses.filter { allowedRange.contains($0.ayah) }
        let bucketNodes = versePickerNodes(for: allowedRange)
        print(
            "[CarPlay] Preparing verse picker: surah=\(surah.suraNumber), selectedVerse=\(selectedVerse.ayah), allowedRange=\(rangeTitle(allowedRange)), verseCount=\(verses.count), maxItems=\(versePickerListLimit), leafBucketSize=\(versePickerLeafSize), rootBucketCount=\(bucketNodes.count)"
        )

        if verses.count <= versePickerListLimit {
            await showExactVersePicker(
                using: interfaceController,
                title: title,
                surah: surah,
                range: allowedRange,
                selectedVerse: selectedVerse,
                forStartVerse: forStartVerse
            )
        } else {
            await showVerseBucketPicker(
                using: interfaceController,
                title: title,
                surah: surah,
                nodes: bucketNodes,
                selectedVerse: selectedVerse,
                forStartVerse: forStartVerse
            )
        }
    }

    private func didSelectVerse(_ verse: AyahNumber, forStartVerse: Bool) {
        updateCustomPlaybackSelection { selection in
            if forStartVerse {
                selection.start = verse
                if selection.end < verse {
                    selection.end = verse
                }
            } else {
                selection.end = verse
                if verse < selection.start {
                    selection.start = verse
                }
            }
        }

        Task { @MainActor in
            guard let interfaceController else {
                return
            }
            do {
                if let customPlaybackTemplate {
                    try await interfaceController.pop(to: customPlaybackTemplate, animated: true)
                } else {
                    try await interfaceController.popTemplate(animated: true)
                }
            } catch {
                print("[CarPlay] Failed to pop verse picker template: \(error)")
            }
        }
    }

    private func playCustomSelection() async {
        guard let playbackController,
              let selection = customPlaybackSelection else {
            return
        }

        if case .downloading = customPlaybackStatus {
            return
        }

        selectedSurahNumber = selection.start.sura.suraNumber

        do {
            try await playbackController.play(
                from: selection.start,
                to: selection.end,
                verseRuns: selection.verseRuns,
                listRuns: selection.listRuns
            )
            refreshTemplates()
            updateNowPlayingInfo(with: playbackController.snapshot)
            await presentNowPlayingIfNeeded()
        } catch {
            customPlaybackStatus = .failed(message: "Check the audio download or your network connection, then try again.")
            refreshTemplates()
            await presentPlaybackFailureAlert()
            print("[CarPlay] Failed to play selected verses: \(error)")
        }
    }

    private func updateCustomPlaybackSelection(
        _ updates: (inout CarPlayVersePlaybackSelection) -> Void
    ) {
        guard var selection = customPlaybackSelection else {
            return
        }
        updates(&selection)
        customPlaybackSelection = selection
        customPlaybackStatus = .ready
        refreshCustomPlaybackAvailability()
        refreshTemplates()
    }

    private var selectedSurah: Sura? {
        let quran = Quran.hafsMadani1405
        guard quran.suras.indices.contains(selectedSurahNumber - 1) else {
            return nil
        }
        return quran.suras[selectedSurahNumber - 1]
    }

    private var selectedReciter: Reciter? {
        if let selectedReciterId {
            return reciters.first { $0.id == selectedReciterId } ?? reciters.first
        }
        return reciters.first
    }

    private var selectedSurahStatusDetail: String? {
        guard let snapshot = playbackController?.snapshot,
              snapshot.surahNumber == selectedSurahNumber else {
            return nil
        }

        switch snapshot.playbackState {
        case .downloading(let progress):
            let percentage = Int((progress * 100).rounded())
            if percentage > 0 {
                return "Downloading audio... \(percentage)%"
            }
            return "Downloading audio..."
        case .playing:
            return "Playing"
        case .paused:
            return "Paused"
        case .stopped:
            return nil
        }
    }

    private var versePickerListLimit: Int {
        max(Int(CPListTemplate.maximumItemCount), 1)
    }

    private func chapterBuckets(for chapters: [ChapterInfo]) -> [CarPlayChapterBucket] {
        stride(from: 0, to: chapters.count, by: chapterPickerListLimit).map { start in
            let end = min(start + chapterPickerListLimit, chapters.count)
            let chunk = Array(chapters[start ..< end])
            return CarPlayChapterBucket(range: chunk.first!.number ... chunk.last!.number)
        }
    }

    private func chapters(in bucket: CarPlayChapterBucket) -> [ChapterInfo] {
        chapters.filter { bucket.range.contains($0.number) }
    }

    private func refreshCustomPlaybackAvailability() {
        customPlaybackAvailabilityTask?.cancel()

        guard let playbackController,
              let selection = customPlaybackSelection,
              let reciter = selectedReciter else {
            return
        }

        let expectedSelection = selection
        let expectedReciter = reciter

        customPlaybackAvailabilityTask = Task { [weak self] in
            let availability = await playbackController.audioAvailability(
                reciter: expectedReciter,
                from: expectedSelection.start,
                to: expectedSelection.end
            )

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard let self,
                      self.customPlaybackSelection == expectedSelection,
                      self.selectedReciter?.id == expectedReciter.id else {
                    return
                }

                switch availability {
                case .downloaded:
                    self.customPlaybackStatus = .ready
                case .downloading(let progress):
                    self.customPlaybackStatus = .downloading(progress: progress)
                case .downloadRequired:
                    if case .failed = self.customPlaybackStatus {
                        return
                    }
                    self.customPlaybackStatus = .downloadRequired
                }
                self.refreshTemplates()
            }
        }
    }

    private func synchronizeCustomPlaybackStatus(with snapshot: AudioPlaybackController.Snapshot) {
        guard isSnapshotForCustomSelection(snapshot) else {
            return
        }

        switch snapshot.playbackState {
        case .downloading(let progress):
            customPlaybackStatus = .downloading(progress: progress)
        case .playing, .paused:
            customPlaybackStatus = .ready
        case .stopped:
            refreshCustomPlaybackAvailability()
            return
        }
    }

    private func isSnapshotForCustomSelection(_ snapshot: AudioPlaybackController.Snapshot) -> Bool {
        guard let request = snapshot.request,
              let selection = customPlaybackSelection else {
            return false
        }
        return request.start == selection.start
            && request.end == selection.end
            && request.verseRuns == selection.verseRuns
            && request.listRuns == selection.listRuns
    }

    private func allowedVerseRange(
        forStartVerse: Bool,
        selection: CarPlayVersePlaybackSelection,
        surah: Sura
    ) -> ClosedRange<Int> {
        let lastAyah = surah.lastVerse.ayah
        if forStartVerse {
            return 1 ... lastAyah
        }
        return selection.start.ayah ... lastAyah
    }

    private func versePickerNodes(for allowedRange: ClosedRange<Int>) -> [VersePickerNode] {
        let leafNodes = stride(
            from: allowedRange.lowerBound,
            through: allowedRange.upperBound,
            by: versePickerLeafSize
        ).map { start in
            let end = min(start + versePickerLeafSize - 1, allowedRange.upperBound)
            return VersePickerNode(range: start ... end, children: [])
        }

        guard leafNodes.count > versePickerListLimit else {
            return leafNodes
        }

        var currentLevel = leafNodes
        while currentLevel.count > versePickerListLimit {
            let previousLevel = currentLevel
            currentLevel = stride(from: 0, to: previousLevel.count, by: versePickerListLimit).map { start in
                let end = min(start + versePickerListLimit, previousLevel.count)
                let children = Array(previousLevel[start ..< end])
                return VersePickerNode(
                    range: children.first!.range.lowerBound ... children.last!.range.upperBound,
                    children: children
                )
            }
        }
        return currentLevel
    }

    private func showVerseBucketPicker(
        using interfaceController: CPInterfaceController,
        title: String,
        surah: Sura,
        nodes: [VersePickerNode],
        selectedVerse: AyahNumber,
        forStartVerse: Bool
    ) async {
        let buckets = nodes.map { CarPlayVerseBucket(range: $0.range) }
        let template = CarPlayTemplateBuilder.shared.makeVerseBucketTemplate(
            title: title,
            buckets: buckets,
            selectedVerse: selectedVerse,
            selectionHandler: { [weak self] bucket in
                self?.didSelectVerseBucket(
                    bucket,
                    from: nodes,
                    surah: surah,
                    title: title,
                    forStartVerse: forStartVerse
                )
            }
        )

        do {
            try await interfaceController.pushTemplate(template, animated: true)
        } catch {
            print("[CarPlay] Failed to push verse bucket template: \(error)")
        }
    }

    private func didSelectVerseBucket(
        _ bucket: CarPlayVerseBucket,
        from nodes: [VersePickerNode],
        surah: Sura,
        title: String,
        forStartVerse: Bool
    ) {
        guard let node = nodes.first(where: { $0.range == bucket.range }),
              let interfaceController else {
            return
        }

        let selectedVerse = forStartVerse
            ? (customPlaybackSelection?.start ?? surah.firstVerse)
            : (customPlaybackSelection?.end ?? surah.lastVerse)
        let nextTitle = "\(title) \(rangeTitle(bucket.range))"

        Task { @MainActor in
            if node.children.isEmpty {
                await showExactVersePicker(
                    using: interfaceController,
                    title: nextTitle,
                    surah: surah,
                    range: node.range,
                    selectedVerse: selectedVerse,
                    forStartVerse: forStartVerse
                )
            } else {
                await showVerseBucketPicker(
                    using: interfaceController,
                    title: nextTitle,
                    surah: surah,
                    nodes: node.children,
                    selectedVerse: selectedVerse,
                    forStartVerse: forStartVerse
                )
            }
        }
    }

    private func showExactVersePicker(
        using interfaceController: CPInterfaceController,
        title: String,
        surah: Sura,
        range: ClosedRange<Int>,
        selectedVerse: AyahNumber,
        forStartVerse: Bool
    ) async {
        let verses = surah.verses.filter { range.contains($0.ayah) }
        print(
            "[CarPlay] Exact verse picker: surah=\(surah.suraNumber), range=\(range.lowerBound)-\(range.upperBound), verseCount=\(verses.count), selectedVerse=\(selectedVerse.ayah)"
        )

        let template = CarPlayTemplateBuilder.shared.makeVersePickerTemplate(
            title: title,
            verses: verses,
            selectedVerse: selectedVerse,
            selectionHandler: { [weak self] verse in
                self?.didSelectVerse(verse, forStartVerse: forStartVerse)
            }
        )

        do {
            try await interfaceController.pushTemplate(template, animated: true)
        } catch {
            print("[CarPlay] Failed to push verse picker template: \(error)")
        }
    }

    private func rangeTitle(_ range: ClosedRange<Int>) -> String {
        if range.lowerBound == range.upperBound {
            return "Ayah \(range.lowerBound)"
        }
        return "\(range.lowerBound)-\(range.upperBound)"
    }

    private func chapterRangeTitle(_ range: ClosedRange<Int>) -> String {
        if range.lowerBound == range.upperBound {
            return "Surah \(range.lowerBound)"
        }
        return "\(range.lowerBound)-\(range.upperBound)"
    }

    private func presentPlaybackFailureAlert() async {
        guard let interfaceController else {
            return
        }

        let action = CPAlertAction(title: "OK", style: .default) { _ in }
        let template = CPAlertTemplate(
            titleVariants: [
                "Could not play audio. Check the download and try again.",
                "Could not play audio",
            ],
            actions: [action]
        )

        do {
            try await interfaceController.presentTemplate(template, animated: true)
        } catch {
            print("[CarPlay] Failed to present playback alert: \(error)")
        }
    }
}

struct ChapterInfo {
    let id: Int
    let number: Int
    let name: String
}

private extension AudioEnd {
    func findLastAyah(startAyah: AyahNumber) -> AyahNumber {
        let pageLastVerse = PageBasedLastAyahFinder().findLastAyah(startAyah: startAyah)
        let lastVerse: AyahNumber = switch self {
        case .juz:
            JuzBasedLastAyahFinder().findLastAyah(startAyah: startAyah)
        case .sura:
            SuraBasedLastAyahFinder().findLastAyah(startAyah: startAyah)
        case .page:
            pageLastVerse
        case .quran:
            QuranBasedLastAyahFinder().findLastAyah(startAyah: startAyah)
        }
        return max(lastVerse, pageLastVerse)
    }
}

private struct VersePickerNode: Equatable {
    let range: ClosedRange<Int>
    let children: [VersePickerNode]
}
