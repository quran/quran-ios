import Foundation
import Preferences
import QuranKit

@MainActor
public final class ListeningProgressStore {
    // MARK: Lifecycle

    public init(preferences: Preferences = .shared) {
        self.preferences = preferences
    }

    // MARK: Public

    public var checkpoint: ListeningCheckpoint? {
        get {
            guard let data = preferences.valueForKey(Self.checkpointKey),
                  let checkpoint = try? JSONDecoder().decode(ListeningCheckpoint.self, from: data),
                  checkpoint.ayah(in: .hafsMadani1405) != nil,
                  !checkpoint.completed || checkpoint.ayah(in: .hafsMadani1405) == Quran.hafsMadani1405.lastVerse
            else {
                return nil
            }
            return checkpoint
        }
        set {
            guard let newValue else {
                preferences.removeValueForKey(Self.checkpointKey)
                return
            }
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            preferences.setValue(data, forKey: Self.checkpointKey)
        }
    }

    // MARK: Private

    private static let checkpointKey = PreferenceKey<Data?>(key: "listeningCheckpointV1", defaultValue: nil)
    private let preferences: Preferences
}
