import QuranKit

/// Stable verse coordinates survive changes to the displayed Quran page layout.
public struct ListeningCheckpoint: Codable, Equatable, Sendable {
    // MARK: Lifecycle

    public init(ayah: AyahNumber, reciterID: Int, completed: Bool = false) {
        sura = ayah.sura.suraNumber
        verse = ayah.ayah
        self.reciterID = reciterID
        self.completed = completed
    }

    // MARK: Public

    public let sura: Int
    public let verse: Int
    public let reciterID: Int
    /// True after the final verse of the Quran has finished playing.
    public let completed: Bool

    public func ayah(in quran: Quran) -> AyahNumber? {
        AyahNumber(quran: quran, sura: sura, ayah: verse)
    }
}
