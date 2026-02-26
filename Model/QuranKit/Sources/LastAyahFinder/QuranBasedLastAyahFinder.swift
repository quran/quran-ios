public struct QuranBasedLastAyahFinder: LastAyahFinder {
    // MARK: Lifecycle

    public init() {
    }

    // MARK: Public

    public func findLastAyah(startAyah: AyahNumber) -> AyahNumber {
        startAyah.quran.suras.last!.lastVerse
    }
}
